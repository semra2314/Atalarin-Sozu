//
//  ProverbWidget.swift
//  KareWidget  (widget extension target)
//
//  "Söz" — a Turkish proverb (atasözü) or idiom (deyim) with its meaning,
//  changing every four hours. The idea Widgy started from as "Ataların Sözü",
//  now one widget among many; the name was shortened to sit alongside Aurora,
//  Focus, Frame, Hush and Daily.
//

import WidgetKit
import SwiftUI
import UIKit


struct ProverbProvider: TimelineProvider {

    func placeholder(in context: Context) -> ProverbEntry {
        ProverbEntry(date: .now, proverb: ProverbLibrary.all[0])
    }

    func getSnapshot(in context: Context, completion: @escaping (ProverbEntry) -> Void) {
        completion(ProverbEntry(date: .now, proverb: ProverbLibrary.entry(for: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ProverbEntry>) -> Void) {
        // Six slots ahead — a day's worth. These entries are pure text, so
        // unlike the image-backed widgets there's no memory cost to scheduling
        // them, and the widget keeps rotating even if the system is stingy
        // about waking us up.
        var entries: [ProverbEntry] = []
        var moment = Date.now
        for step in 0..<6 {
            entries.append(ProverbEntry(date: step == 0 ? .now : moment,
                                        proverb: ProverbLibrary.entry(for: moment)))
            moment = ProverbLibrary.nextRotation(after: moment)
        }
        completion(Timeline(entries: entries, policy: .after(moment)))
    }
}

struct ProverbWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ProverbWidget", provider: ProverbProvider()) { entry in
            ProverbWidgetEntryView(entry: entry)
                .libraryGated("t-proverb")
                // Kare's own language setting, not only the phone's.
                .environment(\.locale, WidgetLanguage.locale)
        }
        .configurationDisplayName("Söz")
        .description("A Turkish proverb or idiom every four hours, with its meaning.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryRectangular, .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}
