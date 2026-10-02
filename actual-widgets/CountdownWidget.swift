//
//  CountdownWidget.swift
//  KareWidget  (widget extension target)
//
//  Kare+ · Days until something you are looking forward to. One mark per day
//  of the wait, filling in as it passes.
//

import WidgetKit
import SwiftUI
import AppIntents


struct CountdownProvider: AppIntentTimelineProvider {
    private var sample: CountdownEvent {
        CountdownEvent(title: "Summer trip", emoji: "✈️",
                       date: .now.addingTimeInterval(23 * 86_400),
                       createdAt: .now.addingTimeInterval(-19 * 86_400))
    }

    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: .now, event: sample, unlocked: true)
    }

    func snapshot(for configuration: SelectCountdownIntent, in context: Context) async -> CountdownEntry {
        let event = CountdownStore.event(id: configuration.countdown?.id)
        if context.isPreview, event == nil {
            return placeholder(in: context)
        }
        return CountdownEntry(date: .now, event: event, unlocked: KarePlusAccess.isUnlocked(kind: CountdownStore.widgetKind))
    }

    func timeline(for configuration: SelectCountdownIntent, in context: Context) async -> Timeline<CountdownEntry> {
        let entry = CountdownEntry(date: .now,
                                   event: CountdownStore.event(id: configuration.countdown?.id),
                                   unlocked: KarePlusAccess.isUnlocked(kind: CountdownStore.widgetKind))
        // The number only changes at midnight.
        let midnight = Calendar.current.nextDate(after: .now,
                                                 matching: DateComponents(hour: 0, minute: 0),
                                                 matchingPolicy: .nextTime) ?? .now.addingTimeInterval(3_600)
        return Timeline(entries: [entry], policy: .after(midnight))
    }
}

// MARK: - Widget

struct CountdownWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: CountdownStore.widgetKind,
            intent: SelectCountdownIntent.self,
            provider: CountdownProvider()
        ) { entry in
            CountdownWidgetEntryView(entry: entry)
                .libraryGated("t-countdown")
                // Kare's own language setting, not only the phone's.
                .environment(\.locale, WidgetLanguage.locale)
        }
        .configurationDisplayName("Countdown")
        .description("Days until the day you are waiting for.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}
