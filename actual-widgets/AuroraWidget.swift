//
//  AuroraWidget.swift
//  KareWidget  (widget extension target)
//
//  Live clock widget. Shows the current time + date over an aurora background
//  that changes with the time of day. Add the aurora-bg-* images to this target.
//

import WidgetKit
import SwiftUI
import UIKit


struct AuroraProvider: TimelineProvider {
    func placeholder(in context: Context) -> AuroraEntry { AuroraEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (AuroraEntry) -> Void) {
        completion(AuroraEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AuroraEntry>) -> Void) {
        // ONE entry only. The clock itself ticks via `Text(_:style:.time)`, which
        // SwiftUI updates on its own — no timeline entry per minute needed.
        //
        // This matters: WidgetKit pre-renders every entry in the timeline, and
        // each of ours draws a full-bleed background image. Returning 60 entries
        // blew past the widget extension's ~30MB memory limit, the process got
        // killed, and the widget rendered blank white. Only the greeting and the
        // background change with the hour, so we just reload on the hour.
        let calendar = Calendar.current
        let nextHour = calendar.date(bySetting: .minute, value: 0, of: .now.addingTimeInterval(3600))
            ?? .now.addingTimeInterval(3600)
        completion(Timeline(entries: [AuroraEntry(date: .now)], policy: .after(nextHour)))
    }
}

struct AuroraWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AuroraWidget", provider: AuroraProvider()) { entry in
            AuroraWidgetEntryView(entry: entry)
                .libraryGated("t-aurora")
                // Kare's own language setting, not only the phone's.
                .environment(\.locale, WidgetLanguage.locale)
        }
        .configurationDisplayName("Aurora")
        .description("A clock that follows the light of day.")
        .supportedFamilies([
            .systemSmall, .systemMedium, .systemLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}
