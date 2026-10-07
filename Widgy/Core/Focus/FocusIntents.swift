//
//  FocusIntents.swift
//  Kare  (shared: app + widget extension)
//
//  App Intents that let the home-screen Focus widget start/stop a session with a
//  tap (interactive widgets, iOS 17+). Add target membership to BOTH targets.
//

import AppIntents
import WidgetKit

struct StartFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Start focus"

    func perform() async throws -> some IntentResult {
        let session = FocusSession(title: "Deep work", startedAt: .now, durationMinutes: 45, soundName: nil)
        FocusSessionStore.save(session)
        return .result()
    }
}

struct StopFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop focus"

    func perform() async throws -> some IntentResult {
        FocusSessionStore.clear()
        return .result()
    }
}

struct PauseFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause focus"

    func perform() async throws -> some IntentResult {
        if var session = FocusSessionStore.load(), !session.isPaused {
            session.pausedAt = .now
            FocusSessionStore.save(session)
        }
        return .result()
    }
}

struct ResumeFocusIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume focus"

    func perform() async throws -> some IntentResult {
        if var session = FocusSessionStore.load(), let pausedAt = session.pausedAt {
            // Shift the start forward by the pause duration so the remaining
            // time picks up exactly where it left off.
            session.startedAt = session.startedAt.addingTimeInterval(Date.now.timeIntervalSince(pausedAt))
            session.pausedAt = nil
            FocusSessionStore.save(session)
        }
        return .result()
    }
}
