//
//  HushWidget.swift
//  KareWidget  (widget extension target)
//
//  A deliberately quiet widget: one word, lots of darkness, nothing to tap.
//  The word changes through the day, so the home screen stays calm but never
//  quite static. No data sources, no permissions — pure design.
//

import WidgetKit
import SwiftUI
import UIKit


struct HushProvider: TimelineProvider {

    /// Single-word prompts. Kept lowercase on purpose — the whole point of
    /// Hush is that it never raises its voice.
    static let words = [
        "breathe", "pause", "notice", "soften", "arrive",
        "release", "settle", "listen", "slow down", "be here"
    ]

    /// One word per hour, derived from the hour itself so it's stable: the
    /// widget shows the same word all hour rather than flickering on refresh.
    private func word(for date: Date) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        let day = Calendar.current.component(.dayOfYear, from: date)
        return Self.words[(hour + day) % Self.words.count]
    }

    func placeholder(in context: Context) -> HushEntry {
        HushEntry(date: .now, word: "breathe")
    }

    func getSnapshot(in context: Context, completion: @escaping (HushEntry) -> Void) {
        completion(HushEntry(date: .now, word: word(for: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HushEntry>) -> Void) {
        // One entry, reloaded on the hour when the word changes. Keeping the
        // timeline tiny is what keeps the extension well inside its memory
        // budget (see AuroraWidget for the cautionary tale).
        let calendar = Calendar.current
        let nextHour = calendar.date(bySetting: .minute, value: 0, of: .now.addingTimeInterval(3600))
            ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [HushEntry(date: .now, word: word(for: .now))],
                            policy: .after(nextHour)))
    }
}

struct HushWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HushWidget", provider: HushProvider()) { entry in
            HushWidgetEntryView(entry: entry)
                .libraryGated("t-hush")
                // Kare's own language setting, not only the phone's.
                .environment(\.locale, WidgetLanguage.locale)
        }
        .configurationDisplayName("Hush")
        .description("One quiet word, changing through the day.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}
