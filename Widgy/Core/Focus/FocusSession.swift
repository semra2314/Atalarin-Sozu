//
//  FocusSession.swift
//  Kare  (shared: app + widget extension)
//
//  A running focus session, shared through the App Group so the home-screen
//  Focus widget can show a live countdown. Add this file's target membership to
//  BOTH the app and the widget extension.
//

import Foundation
import WidgetKit

nonisolated struct FocusSession: Codable, Hashable, Sendable {
    var title: String
    var startedAt: Date
    var durationMinutes: Int
    var soundName: String?      // nil = silent; otherwise a bundled mp3 name
    /// When the user paused. While set, the countdown is frozen; resuming
    /// pushes `startedAt` forward by however long the pause lasted, so the
    /// remaining time is preserved exactly.
    var pausedAt: Date?

    init(title: String = "Deep work", startedAt: Date = .now, durationMinutes: Int = 45, soundName: String? = nil, pausedAt: Date? = nil) {
        self.title = title
        self.startedAt = startedAt
        self.durationMinutes = durationMinutes
        self.soundName = soundName
        self.pausedAt = pausedAt
    }

    var endsAt: Date { startedAt.addingTimeInterval(Double(durationMinutes) * 60) }

    var isPaused: Bool { pausedAt != nil }

    /// A paused session never expires on its own.
    func isFinished(at date: Date = .now) -> Bool {
        guard pausedAt == nil else { return false }
        return date >= endsAt
    }

    func remaining(at date: Date = .now) -> TimeInterval {
        max(0, endsAt.timeIntervalSince(pausedAt ?? date))
    }

    func progress(at date: Date = .now) -> Double {
        let total = Double(durationMinutes) * 60
        guard total > 0 else { return 0 }
        return min(1, max(0, (pausedAt ?? date).timeIntervalSince(startedAt) / total))
    }

    /// Frozen countdown as mm:ss, for when the timer isn't ticking.
    var remainingText: String {
        let seconds = Int(remaining())
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

/// Reads/writes the active focus session in the App Group container.
/// `nonisolated` because it's pure file I/O with no shared mutable state, and
/// App Intents call it from the widget extension's own (non-main) context.
nonisolated enum FocusSessionStore {
    static let widgetKind = "FocusWidget"
    private static let fileName = "focus-session.json"

    private static var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedWidgetStore.appGroupID)?
            .appendingPathComponent(fileName)
    }

    static func save(_ session: FocusSession) {
        guard let url = fileURL, let data = try? JSONEncoder().encode(session) else { return }
        try? data.write(to: url, options: .atomic)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    /// The active session, or nil if none / already finished.
    static func load() -> FocusSession? {
        guard let url = fileURL, let data = try? Data(contentsOf: url),
              let session = try? JSONDecoder().decode(FocusSession.self, from: data) else { return nil }
        return session.isFinished() ? nil : session
    }

    static func clear() {
        if let url = fileURL { try? FileManager.default.removeItem(at: url) }
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
