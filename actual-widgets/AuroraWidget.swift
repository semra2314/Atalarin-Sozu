//
//  AuroraWidget.swift
//  WidgyWidget  (widget extension target)
//
//  Live clock widget. Shows the current time + date over an aurora background
//  that changes with the time of day. Add the aurora-bg-* images to this target.
//

import WidgetKit
import SwiftUI
import UIKit

struct AuroraEntry: TimelineEntry {
    let date: Date
}

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

struct AuroraWidgetEntryView: View {
    var entry: AuroraProvider.Entry
    @Environment(\.widgetFamily) private var family

    private var hour: Int { Calendar.current.component(.hour, from: entry.date) }

    private var greeting: String {
        switch hour {
        case 5..<12: "Good morning"
        case 12..<17: "Good afternoon"
        case 17..<21: "Good evening"
        default: "Good night"
        }
    }

    /// Time-of-day artwork. Small and large are square-ish, so they use the
    /// square art; medium is a wide 2.13:1 letterbox, which would badly crop
    /// the square version — it gets a purpose-made "-wide" crop instead.
    private var backgroundName: String {
        let base: String
        switch hour {
        case 5..<8: base = "aurora-bg-dawn"
        case 8..<11: base = "aurora-bg-morning"
        case 11..<16: base = "aurora-bg-midday"
        case 16..<20: base = "aurora-bg-sunset"
        default: base = "aurora-bg-night"
        }
        return family == .systemMedium ? base + "-wide" : base
    }

    /// A self-updating clock. Using `Text(_:style:.time)` lets SwiftUI tick the
    /// minutes on its own, so the timeline stays at a single entry.
    private var clock: some View {
        Text(entry.date, style: .time)
            .minimumScaleFactor(0.7)
            .lineLimit(1)
    }
    /// "Tue, 22 July" — sentence case, exactly as the promo art shows it.
    /// (It used to be uppercased, which read louder than the design intends.)
    private var dateStringLong: String {
        let f = DateFormatter(); f.dateFormat = "EEE, d MMMM"; return f.string(from: entry.date)
    }
    private var dateStringShort: String {
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: entry.date)
    }

    /// Lock screen families render vibrant/monochrome — artwork and colour are
    /// flattened away — so they get their own typographic treatment instead of
    /// a shrunken version of the home-screen design.
    private var isAccessory: Bool {
        family == .accessoryCircular || family == .accessoryRectangular || family == .accessoryInline
    }

    var body: some View {
        if isAccessory {
            accessory
                .containerBackground(for: .widget) {
                    // Inline sits on the wallpaper itself and must stay clear.
                    if family == .accessoryInline {
                        Color.clear
                    } else {
                        AccessoryWidgetBackground()
                    }
                }
        } else {
            content
                .containerBackground(for: .widget) { background }
        }
    }

    @ViewBuilder private var accessory: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 0) {
                Text(entry.date, style: .time)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(dateStringShort.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .opacity(0.75)
            }
            .padding(2)

        case .accessoryInline:
            // Inline is a single line next to the lock screen clock.
            Text("\(greeting) · \(dateStringShort)")

        default: // accessoryRectangular
            VStack(alignment: .leading, spacing: 1) {
                Text(greeting)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(entry.date, style: .time)
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(dateStringLong)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .opacity(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Always paints something. The gradient is a real fallback, not just a
    /// placeholder: if the aurora image ever fails to load in the extension
    /// (missing from the target, wrong name), the widget still looks right
    /// instead of rendering blank.
    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "2C1E5C"), Color(hex: "7B3FA0"), Color(hex: "E0639A")],
                startPoint: .top,
                endPoint: .bottom
            )
            Image(backgroundName)
                .resizable()
                .aspectRatio(contentMode: .fill)
        }
    }

    /// Type scale per family: greeting, clock, date, and the inset.
    /// `.contentMarginsDisabled()` lets the art run edge to edge, which also
    /// means we owe the text its own padding — without it the type ran off
    /// the widget's rounded corners.
    private var metrics: (greeting: CGFloat, clock: CGFloat, date: CGFloat, inset: CGFloat) {
        switch family {
        case .systemSmall: (14, 32, 10, 14)
        case .systemLarge: (27, 66, 14, 22)
        default:           (18, 42, 11, 17)
        }
    }

    /// Matches the promo art: an airy serif stack in the top-left corner, all
    /// one light weight, no scrim — the artwork is dark enough at the top for
    /// white type to sit on it unaided.
    private var content: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 0 : 2) {
            Text(family == .systemSmall
                 ? (greeting.components(separatedBy: " ").last ?? greeting)
                 : greeting)
                .font(AppFont.serif(size: metrics.greeting, weight: .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            clock
                .font(AppFont.serif(size: metrics.clock, weight: .regular))

            Text(family == .systemSmall ? dateStringShort : dateStringLong)
                .font(.system(size: metrics.date, weight: .regular))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .opacity(0.92)
                .padding(.top, 2)
        }
        .foregroundStyle(.white)
        // Just enough shadow to hold the thin serif together on a bright sky,
        // without the heavy scrim the promo doesn't have.
        .shadow(color: .black.opacity(0.22), radius: 6, y: 1)
        .padding(metrics.inset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct AuroraWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AuroraWidget", provider: AuroraProvider()) { entry in
            AuroraWidgetEntryView(entry: entry)
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
