//
//  ReviewService.swift
//  Kare
//
//  Reviews live in Firestore, so the one people write is the one everyone
//  else reads. Because they are written by people, Guideline 1.2 applies:
//  there is a filter before posting, a way to report a review, a way to
//  block its author, and we act on reports (see the Terms).
//
//  Shape:
//    /reviews/{templateID}_{uid}   one review per person per widget
//      templateID, uid, authorName, stars, text, createdAt, [hidden]
//    /reports/{autoID}             reviewID, reviewUID, reason, reporterUID?, createdAt
//
//  `hidden` is only ever set by us, from the Firebase console, after a
//  report. The security rules stop clients from setting or clearing it.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

@MainActor
enum ReviewService {
    private static let reviews = "reviews"
    private static let reports = "reports"
    private static let blockedKey = "kare.reviews.blockedUIDs"
    private static let reportedKey = "kare.reviews.reportedIDs"

    static var isAvailable: Bool { FirebaseApp.app() != nil }

    enum ReportReason: String, CaseIterable, Identifiable {
        case spam, offensive, harassment, other
        var id: String { rawValue }
        var title: String {
            switch self {
            case .spam: String(localized: "Spam or advertising")
            case .offensive: String(localized: "Offensive language")
            case .harassment: String(localized: "Harassment or hate")
            case .other: String(localized: "Something else")
            }
        }
    }

    enum Failure: LocalizedError {
        case notSignedIn, blockedWords
        var errorDescription: String? {
            switch self {
            case .notSignedIn: String(localized: "Sign in to write a review.")
            case .blockedWords: String(localized: "Your review has words we don't allow. Please reword it.")
            }
        }
    }

    // MARK: Reading

    static func fetch(templateID: String) async throws -> [Review] {
        let snapshot = try await Firestore.firestore()
            .collection(reviews)
            .whereField("templateID", isEqualTo: templateID)
            .limit(to: 100)
            .getDocuments()
        let blocked = blockedUIDs
        let reported = reportedIDs
        return snapshot.documents.compactMap { doc -> Review? in
            let data = doc.data()
            guard (data["hidden"] as? Bool) != true,
                  let uid = data["uid"] as? String, !blocked.contains(uid),
                  !reported.contains(doc.documentID),
                  let stars = data["stars"] as? Int,
                  let text = data["text"] as? String else { return nil }
            return Review(id: doc.documentID,
                          templateID: templateID,
                          authorName: data["authorName"] as? String ?? "Kare user",
                          authorID: uid,
                          stars: stars,
                          text: text,
                          createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .now)
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    /// Everything one person has written, for their public profile.
    static func fetch(byUID uid: String) async throws -> [Review] {
        guard !blockedUIDs.contains(uid) else { return [] }
        let snapshot = try await Firestore.firestore()
            .collection(reviews)
            .whereField("uid", isEqualTo: uid)
            .limit(to: 50)
            .getDocuments()
        let reported = reportedIDs
        return snapshot.documents.compactMap { doc -> Review? in
            let data = doc.data()
            guard (data["hidden"] as? Bool) != true,
                  !reported.contains(doc.documentID),
                  let templateID = data["templateID"] as? String,
                  let stars = data["stars"] as? Int,
                  let text = data["text"] as? String else { return nil }
            return Review(id: doc.documentID,
                          templateID: templateID,
                          authorName: data["authorName"] as? String ?? "Kare user",
                          authorID: uid,
                          stars: stars,
                          text: text,
                          createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? .now)
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    static func isBlocked(_ uid: String) -> Bool { blockedUIDs.contains(uid) }

    // MARK: Writing

    /// Posts or replaces the signed-in user's review of this widget.
    static func submit(_ review: Review) async throws {
        guard let uid = AuthService.currentUID else { throw Failure.notSignedIn }
        guard !ReviewFilter.isObjectionable(review.text),
              !ReviewFilter.isObjectionable(review.authorName) else { throw Failure.blockedWords }
        let data: [String: Any] = [
            "templateID": review.templateID,
            "uid": uid,
            "authorName": String(review.authorName.prefix(60)),
            "stars": max(1, min(5, review.stars)),
            "text": String(review.text.prefix(1_000)),
            "createdAt": Timestamp(date: .now)
        ]
        // Make sure there is a profile behind the name before it goes public.
        await PublicProfileService.shared.publishMine()
        try await Firestore.firestore().collection(reviews)
            .document("\(review.templateID)_\(uid)")
            .setData(data, merge: true)
    }

    static func deleteMine(templateID: String) async throws {
        guard let uid = AuthService.currentUID else { throw Failure.notSignedIn }
        try await Firestore.firestore().collection(reviews).document("\(templateID)_\(uid)").delete()
    }

    /// Used when an account is deleted.
    static func deleteAll(byUID uid: String) async {
        guard isAvailable else { return }
        let db = Firestore.firestore()
        guard let snapshot = try? await db.collection(reviews)
            .whereField("uid", isEqualTo: uid).getDocuments() else { return }
        for doc in snapshot.documents {
            try? await doc.reference.delete()
        }
    }

    // MARK: Safety

    /// Sends a report and hides the review on this phone straight away.
    static func report(_ review: Review, reason: ReportReason) async {
        var ids = reportedIDs
        ids.insert(review.id)
        UserDefaults.standard.set(Array(ids), forKey: reportedKey)

        guard isAvailable else { return }
        var data: [String: Any] = [
            "reviewID": review.id,
            "templateID": review.templateID,
            "reason": reason.rawValue,
            "text": String(review.text.prefix(1_000)),
            "createdAt": Timestamp(date: .now)
        ]
        if let author = review.authorID { data["reviewUID"] = author }
        if let me = AuthService.currentUID { data["reporterUID"] = me }
        try? await Firestore.firestore().collection(reports).addDocument(data: data)
    }

    /// Hides everything this person wrote, on this phone, from now on.
    static func block(uid: String) {
        var uids = blockedUIDs
        uids.insert(uid)
        UserDefaults.standard.set(Array(uids), forKey: blockedKey)
    }

    static func isMine(_ review: Review) -> Bool {
        guard let uid = AuthService.currentUID else { return false }
        return review.authorID == uid
    }

    private static var blockedUIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: blockedKey) ?? [])
    }

    private static var reportedIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: reportedKey) ?? [])
    }
}

/// A short first line of defence. Not a moderator, just enough to stop the
/// obvious before it is posted; reports and the console handle the rest.
nonisolated enum ReviewFilter {
    private static let words: [String] = [
        // English
        "fuck", "shit", "bitch", "cunt", "nigger", "nigga", "faggot", "retard", "whore", "slut",
        // Turkish
        "amk", "aq", "orospu", "piç", "siktir", "sikerim", "yarrak", "göt", "ibne", "pezevenk", "kahpe"
    ]

    static func isObjectionable(_ text: String) -> Bool {
        let tokens = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        return tokens.contains { token in
            words.contains { token == $0 || (token.count > 4 && token.hasPrefix($0) && $0.count >= 4) }
        }
    }
}
