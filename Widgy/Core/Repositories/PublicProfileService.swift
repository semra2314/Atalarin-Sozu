//
//  PublicProfileService.swift
//  Kare
//
//  The part of a profile other people see: name, @username and photo. It
//  lives on the phone first (AppStorage and ProfileStore) and is mirrored to
//  Firestore so a review can show who wrote it.
//
//  Shape:
//    /profiles/{uid}   displayName, username, avatar (small JPEG bytes), updatedAt
//
//  The photo is stored as a ~160px JPEG inside the document itself. At that
//  size it is a few kilobytes, so it needs no separate file storage.
//

import Foundation
import Observation
import UIKit
import FirebaseCore
import FirebaseFirestore

nonisolated struct PublicProfile: Identifiable, Hashable, Sendable {
    let id: String          // Firebase uid
    var displayName: String
    var username: String
    var avatarData: Data?

    var handle: String { username.isEmpty ? "" : "@" + username }
}

@MainActor
@Observable
final class PublicProfileService {
    static let shared = PublicProfileService()
    private init() {}

    private static let collection = "profiles"
    /// Profiles fetched this session, so a list of reviews by the same few
    /// people does not fetch the same document again and again.
    private(set) var cache: [String: PublicProfile] = [:]
    private var inFlight: Set<String> = []

    private var isAvailable: Bool { FirebaseApp.app() != nil }

    // MARK: Reading

    func profile(for uid: String) -> PublicProfile? { cache[uid] }

    /// Loads a profile into the cache if it is not there yet.
    func load(_ uid: String, force: Bool = false) async {
        guard isAvailable, force || cache[uid] == nil, !inFlight.contains(uid) else { return }
        inFlight.insert(uid)
        defer { inFlight.remove(uid) }
        guard let snapshot = try? await Firestore.firestore()
            .collection(Self.collection).document(uid).getDocument(),
              let data = snapshot.data() else { return }
        cache[uid] = PublicProfile(id: uid,
                                   displayName: data["displayName"] as? String ?? "",
                                   username: data["username"] as? String ?? "",
                                   avatarData: data["avatar"] as? Data)
    }

    // MARK: Writing

    /// Sends the signed-in user's current name, handle and photo. Called after
    /// sign-in, after editing the profile, and once at launch.
    func publishMine() async {
        guard isAvailable, let uid = AuthService.currentUID else { return }
        let defaults = UserDefaults.standard
        let name = String((defaults.string(forKey: OnboardingKeys.displayName) ?? "").prefix(60))
        let username = String((defaults.string(forKey: OnboardingKeys.username) ?? "").prefix(30))
        guard !ReviewFilter.isObjectionable(name), !ReviewFilter.isObjectionable(username) else { return }

        var avatar: Data?
        if let image = ProfileStore.shared.avatar(), let full = image.jpegData(compressionQuality: 0.9) {
            avatar = ImageDownscaler.downscaledJPEG(full, maxDimension: 160, quality: 0.7)
        }

        var data: [String: Any] = [
            "displayName": name,
            "username": username,
            "updatedAt": Timestamp(date: .now)
        ]
        data["avatar"] = avatar.map { $0 as Any } ?? FieldValue.delete()
        try? await Firestore.firestore().collection(Self.collection).document(uid)
            .setData(data, merge: true)
        cache[uid] = PublicProfile(id: uid, displayName: name, username: username, avatarData: avatar)
    }

    func deleteMine(uid: String) async {
        guard isAvailable else { return }
        try? await Firestore.firestore().collection(Self.collection).document(uid).delete()
        cache[uid] = nil
    }

    /// Reports a profile (its name or photo) for review by us.
    func report(_ profile: PublicProfile, reason: ReviewService.ReportReason) async {
        guard isAvailable else { return }
        var data: [String: Any] = [
            "kind": "profile",
            "profileUID": profile.id,
            "reviewID": "",
            "reason": reason.rawValue,
            "text": profile.displayName + " " + profile.handle,
            "createdAt": Timestamp(date: .now)
        ]
        if let me = AuthService.currentUID { data["reporterUID"] = me }
        try? await Firestore.firestore().collection("reports").addDocument(data: data)
    }
}
