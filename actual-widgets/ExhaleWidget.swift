//
//  ExhaleWidget.swift
//  KareWidget  (widget extension target)
//
//  Kare+ · For people who have stopped smoking.
//
//  The lungs fill as the body recovers, following WHO's timeline. Tap them and
//  they fill all the way for a breath. Below: days smoke-free and the money
//  kept. A restart button asks twice.
//

import WidgetKit
import SwiftUI
import AppIntents


struct ExhaleProvider: TimelineProvider {
    func placeholder(in context: Context) -> ExhaleEntry {
        var plan = QuitPlan.starting(now: .now.addingTimeInterval(-9 * 86_400))
        plan.packPrice = 5
        return ExhaleEntry(date: .now, plan: plan, unlocked: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (ExhaleEntry) -> Void) {
        // The gallery shows a sample so people see what they are adding.
        if context.isPreview, QuitStore.load() == nil {
            completion(placeholder(in: context))
        } else {
            completion(ExhaleEntry(date: .now, plan: QuitStore.load(), unlocked: KarePlusAccess.isUnlocked(kind: QuitStore.widgetKind)))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ExhaleEntry>) -> Void) {
        let plan = QuitStore.load()
        let unlocked = KarePlusAccess.isUnlocked(kind: QuitStore.widgetKind)
        let now = Date.now

        var dates: [Date] = [now]
        // The end of a breath and the end of an armed restart are both
        // moments the widget has to change on its own.
        if let breathUntil = plan?.breathUntil, breathUntil > now { dates.append(breathUntil) }
        if let armedUntil = plan?.resetArmedUntil, armedUntil > now { dates.append(armedUntil) }
        // Hourly after that: money and the lungs move slowly, and a short
        // timeline keeps the extension inside its memory budget.
        for hour in 1...6 {
            dates.append(now.addingTimeInterval(Double(hour) * 3_600))
        }

        let entries = dates.sorted().map { ExhaleEntry(date: $0, plan: plan, unlocked: unlocked) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Widget

struct ExhaleWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: QuitStore.widgetKind, provider: ExhaleProvider()) { entry in
            ExhaleWidgetEntryView(entry: entry)
                .libraryGated("t-exhale")
                // Kare's own language setting, not only the phone's.
                .environment(\.locale, WidgetLanguage.locale)
        }
        .configurationDisplayName("Exhale")
        .description("Days smoke-free, money kept, and lungs that fill as you heal.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}
