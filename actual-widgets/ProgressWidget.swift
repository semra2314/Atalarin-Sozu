//
//  ProgressWidget.swift
//  KareWidget  (widget extension target)
//
//  Kare+ · The year in months, the month in days, the day in hours, a life in
//  years. A big percentage and one mark per unit, filling as time passes.
//

import WidgetKit
import SwiftUI
import AppIntents


struct ProgressProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> ProgressEntry {
        ProgressEntry(date: .now, kind: .year, unlocked: true)
    }

    func snapshot(for configuration: SelectProgressIntent, in context: Context) async -> ProgressEntry {
        ProgressEntry(date: .now, kind: configuration.measure.kind,
                      unlocked: context.isPreview ? true : KarePlusAccess.isUnlocked(kind: LifeProgressStore.widgetKind))
    }

    func timeline(for configuration: SelectProgressIntent, in context: Context) async -> Timeline<ProgressEntry> {
        let kind = configuration.measure.kind
        let unlocked = KarePlusAccess.isUnlocked(kind: LifeProgressStore.widgetKind)
        // Today moves every hour; everything else barely moves in a day, so
        // six hourly entries cover all of them and keep the timeline small.
        let entries = (0..<6).map { hour in
            ProgressEntry(date: .now.addingTimeInterval(Double(hour) * 3_600), kind: kind, unlocked: unlocked)
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

// MARK: - Widget

struct ProgressWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: LifeProgressStore.widgetKind,
            intent: SelectProgressIntent.self,
            provider: ProgressProvider()
        ) { entry in
            ProgressWidgetEntryView(entry: entry)
                .libraryGated("t-progress")
                // Kare's own language setting, not only the phone's.
                .environment(\.locale, WidgetLanguage.locale)
        }
        .configurationDisplayName("Progress")
        .description("How much of the day, month, year or your life has passed.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}
