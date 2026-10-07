//
//  RemovalFeedback.swift
//  Kare
//
//  Why people take a widget back out of their library. One tap after a
//  removal, never required, and never more than once a day so it does not
//  become the reason people leave.
//
//  Answers are kept on the device first and sent to Firestore
//  (`removalFeedback/{id}`) whenever Firebase is set up. Until then they
//  wait in the queue and go out on the next launch that can send them.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

nonisolated enum RemovalReason: String, Codable, CaseIterable, Identifiable, Sendable {
    case notUsing
    case design
    case notWorking
    case homeScreen
    case foundBetter
    case other

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .notUsing: "😴"
        case .design: "🎨"
        case .notWorking: "🛠️"
        case .homeScreen: "📱"
        case .foundBetter: "🔁"
        case .other: "💬"
        }
    }

    /// Key into Localizable.xcstrings.
    var titleKey: String {
        switch self {
        case .notUsing: "I wasn't using it"
        case .design: "I didn't like the design"
        case .notWorking: "It didn't work as expected"
        case .homeScreen: "It didn't look good on my home screen"
        case .foundBetter: "I found something better"
        case .other: "Something else"
        }
    }
}

nonisolated struct RemovalFeedback: Codable, Identifiable, Sendable {
    var id = UUID()
    var templateID: String
    var widgetName: String
    var reason: RemovalReason
    var note: String?
    var daysInstalled: Int?
    var createdAt = Date.now
    var appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
    var language = Locale.current.language.languageCode?.identifier ?? "?"
    var uploaded = false
}

/// What the survey needs to know about the widget that just went.
struct RemovalSurveyTarget: Identifiable, Equatable {
    var id: String { templateID }
    let templateID: String
    let name: String
    let daysInstalled: Int?
}

@MainActor
enum RemovalFeedbackStore {
    private static let lastAskedKey = "kare.removalSurvey.lastAsked"
    private static let collection = "removalFeedback"

    private static var fileURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("removal-feedback.json")
    }

    // MARK: Asking

    /// At most one survey a day. Someone clearing out five widgets should
    /// not be asked five times.
    static var shouldAsk: Bool {
        guard let last = UserDefaults.standard.object(forKey: lastAskedKey) as? Date else { return true }
        return Date.now.timeIntervalSince(last) > 24 * 3_600
    }

    static func markAsked() {
        UserDefaults.standard.set(Date.now, forKey: lastAskedKey)
    }

    // MARK: Saving

    static func all() -> [RemovalFeedback] {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([RemovalFeedback].self, from: data)) ?? []
    }

    private static func save(_ items: [RemovalFeedback]) {
        guard let url = fileURL else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        // Keep the queue small; the useful part is what reaches the server.
        let trimmed = Array(items.suffix(200))
        if let data = try? JSONEncoder().encode(trimmed) {
            try? data.write(to: url, options: .atomic)
        }
    }

    static func record(_ feedback: RemovalFeedback) {
        var items = all()
        items.append(feedback)
        save(items)
        Task { await flush() }
    }

    // MARK: Sending

    /// Sends everything not yet sent. Quietly does nothing when Firebase is
    /// not configured or the phone is offline; the answers wait for next time.
    static func flush() async {
        guard FirebaseApp.app() != nil else { return }
        var items = all()
        guard items.contains(where: { !$0.uploaded }) else { return }

        let db = Firestore.firestore()
        for index in items.indices where !items[index].uploaded {
            let item = items[index]
            var data: [String: Any] = [
                "templateID": item.templateID,
                "widgetName": item.widgetName,
                "reason": item.reason.rawValue,
                "createdAt": Timestamp(date: item.createdAt),
                "appVersion": item.appVersion,
                "language": item.language
            ]
            if let note = item.note { data["note"] = note }
            if let days = item.daysInstalled { data["daysInstalled"] = days }
            do {
                // The id is ours, so sending twice writes the same document.
                try await db.collection(collection).document(item.id.uuidString).setData(data)
                items[index].uploaded = true
            } catch {
                break
            }
        }
        save(items)
    }
}
