//
//  FocusWidget.swift
//  KareWidget  (widget extension target)
//
//  Live focus widget. Mirrors the running session from the App Group with an
//  auto-updating countdown + progress. When idle it shows a Start button
//  (interactive widget, iOS 17+). Add the focus-bg-* images to this target.
//

import WidgetKit
import SwiftUI
import AppIntents


struct FocusProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusEntry { FocusEntry(date: .now, session: nil) }

    func getSnapshot(in context: Context, completion: @escaping (FocusEntry) -> Void) {
        completion(FocusEntry(date: .now, session: FocusSessionStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusEntry>) -> Void) {
        let session = FocusSessionStore.load()
        var entries = [FocusEntry(date: .now, session: session)]
        if let session {
            // When it ends, flip to the idle state.
            entries.append(FocusEntry(date: session.endsAt, session: nil))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct FocusWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: FocusSessionStore.widgetKind, provider: FocusProvider()) { entry in
            FocusWidgetEntryView(entry: entry)
                .libraryGated("t-focus")
                // Kare's own language setting, not only the phone's.
                .environment(\.locale, WidgetLanguage.locale)
        }
        .configurationDisplayName("Focus Stack")
        .description("Live deep-work timer, on your home and lock screen.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}
