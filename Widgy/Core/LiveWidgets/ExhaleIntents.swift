//
//  ExhaleIntents.swift
//  Kare  (shared: app + widget extension)
//
//  The two buttons on the Exhale widget. They run in the widget extension
//  when tapped on the home screen (interactive widgets, iOS 17+).
//

import AppIntents
import WidgetKit

/// Tapping the lungs: they fill all the way for a few seconds, then settle
/// back to the real level. A small ritual in place of the old one.
struct TakeBreathIntent: AppIntent {
    static var title: LocalizedStringResource = "Take a breath"
    static var isDiscoverable: Bool { false }

    func perform() async throws -> some IntentResult {
        QuitStore.update { plan in
            plan.breathUntil = Date.now.addingTimeInterval(QuitWidgetTiming.breath)
            plan.resetArmedUntil = nil
        }
        return .result()
    }
}

/// Restart, in two taps. The first arms it and the widget asks "Sure?";
/// the second, within a few seconds, starts the count again from now.
struct RestartQuitIntent: AppIntent {
    static var title: LocalizedStringResource = "Start over"
    // Kept out of Shortcuts and Siri: resetting someone's count by voice or
    // automation is not something anyone should do by accident.
    static var isDiscoverable: Bool { false }

    func perform() async throws -> some IntentResult {
        if let plan = QuitStore.load(), plan.isResetArmed() {
            QuitStore.restart()
        } else {
            QuitStore.update { plan in
                plan.resetArmedUntil = Date.now.addingTimeInterval(QuitWidgetTiming.resetWindow)
                plan.breathUntil = nil
            }
        }
        return .result()
    }
}

nonisolated enum QuitWidgetTiming {
    static let breath: TimeInterval = 4
    static let resetWindow: TimeInterval = 8
}
