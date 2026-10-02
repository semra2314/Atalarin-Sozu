//
//  DailyWidget.swift
//  KareWidget  (widget extension target)
//
//  A passage a day, from whichever source the user chose in the app. Quiet
//  typography, always with its reference — an unattributed quotation is how
//  misattribution spreads, and that matters more than usual here.
//

import WidgetKit
import SwiftUI
import UIKit


struct DailyProvider: TimelineProvider {

    private func entry(for date: Date) -> DailyEntry {
        let source = DailyStore.loadSource()
        return DailyEntry(date: date,
                          passage: DailyStore.passage(for: date, source: source),
                          source: source)
    }

    func placeholder(in context: Context) -> DailyEntry {
        DailyEntry(date: .now,
                   passage: .init(text: "Slow and steady wins the race.", reference: "Traditional"),
                   source: .proverbs)
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyEntry) -> Void) {
        completion(entry(for: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyEntry>) -> Void) {
        // One entry, refreshed at midnight when the passage changes. Keeping
        // the timeline to a single entry is what keeps the extension inside
        // its memory budget.
        let tomorrow = Calendar.current.nextDate(after: .now,
                                                 matching: DateComponents(hour: 0, minute: 0),
                                                 matchingPolicy: .nextTime) ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [entry(for: .now)], policy: .after(tomorrow)))
    }
}

struct DailyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: DailyStore.widgetKind, provider: DailyProvider()) { entry in
            DailyWidgetEntryView(entry: entry)
                .libraryGated("t-daily")
                // Kare's own language setting, not only the phone's.
                .environment(\.locale, WidgetLanguage.locale)
        }
        .configurationDisplayName("Daily")
        .description("A passage a day, from the source you choose.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}
