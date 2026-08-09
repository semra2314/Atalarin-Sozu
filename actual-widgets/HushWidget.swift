//
//  HushWidget.swift
//  WidgyWidget  (widget extension target)
//
//  A deliberately quiet widget: one word, lots of darkness, nothing to tap.
//  The word changes through the day, so the home screen stays calm but never
//  quite static. No data sources, no permissions — pure design.
//

import WidgetKit
import SwiftUI
import UIKit

struct HushEntry: TimelineEntry {
    let date: Date
    let word: String
}

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

struct HushWidgetEntryView: View {
    var entry: HushProvider.Entry
    @Environment(\.widgetFamily) private var family

    private var wordSize: CGFloat {
        switch family {
        case .systemSmall: 25
        case .systemLarge: 44
        default: 34
        }
    }

    /// Lock screen families render vibrant/monochrome, so the dark card is
    /// dropped and the word simply stands on the wallpaper.
    private var isAccessory: Bool {
        family == .accessoryCircular || family == .accessoryRectangular || family == .accessoryInline
    }

    var body: some View {
        if isAccessory {
            accessory
                .containerBackground(for: .widget) {
                    if family == .accessoryInline {
                        Color.clear
                    } else {
                        AccessoryWidgetBackground()
                    }
                }
        } else {
            home
        }
    }

    /// The word alone in the optical centre. Nothing else — the emptiness is
    /// the design, not a gap waiting to be filled. (iOS already prints the
    /// widget's name under the card, so a label inside it just repeats itself.)
    private var home: some View {
        Text(entry.word)
            .font(AppFont.serif(size: wordSize, weight: .regular))
            .foregroundStyle(Color(hex: "C9C6C1"))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(family == .systemSmall ? 14 : 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) { backdrop }
    }

    /// Time-of-day artwork name, mirroring Aurora's hour mapping.
    private var backgroundName: String {
        let hour = Calendar.current.component(.hour, from: entry.date)
        let base: String
        switch hour {
        case 5..<11: base = "hush-bg-dawn"
        case 11..<20: base = "hush-bg-still"
        default: base = "hush-bg-night"
        }
        return family == .systemMedium ? base + "-wide" : base
    }

    /// Uses the generated artwork when it's in the catalog, and otherwise draws
    /// an equivalent look in code — so the widget is never blank while the art
    /// is still being made, and never depends on an asset shipping correctly.
    private var backdrop: some View {
        let hour = Calendar.current.component(.hour, from: entry.date)
        let palette: (top: String, bottom: String, glow: String)
        switch hour {
        case 5..<11:  palette = ("121316", "2A2E38", "39404E")  // dawn: cool
        case 11..<20: palette = ("101010", "2A2A2A", "3A3A3A")  // still: neutral
        default:      palette = ("121011", "2E2620", "2E2620")  // night: warm
        }

        return ZStack {
            LinearGradient(
                colors: [Color(hex: palette.top), Color(hex: palette.bottom)],
                startPoint: .top,
                endPoint: .bottom
            )
            // Glow pushed to the edges, leaving the centre calm for the word —
            // the same composition rule the art prompts describe.
            RadialGradient(
                colors: [.clear, Color(hex: palette.glow).opacity(0.5)],
                center: .center,
                startRadius: 10,
                endRadius: 190
            )
            if UIImage(named: backgroundName) != nil {
                Image(backgroundName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
        }
    }

    @ViewBuilder private var accessory: some View {
        switch family {
        case .accessoryCircular:
            Text(entry.word)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .minimumScaleFactor(0.4)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(4)

        case .accessoryInline:
            Text(entry.word)

        default: // accessoryRectangular
            Text(entry.word)
                .font(.system(size: 22, weight: .regular, design: .serif))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

struct HushWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HushWidget", provider: HushProvider()) { entry in
            HushWidgetEntryView(entry: entry)
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
