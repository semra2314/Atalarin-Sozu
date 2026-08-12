//
//  ProverbWidget.swift
//  WidgyWidget  (widget extension target)
//
//  "Söz" — a Turkish proverb (atasözü) or idiom (deyim) with its meaning,
//  changing every four hours. The idea Widgy started from as "Ataların Sözü",
//  now one widget among many; the name was shortened to sit alongside Aurora,
//  Focus, Frame, Hush and Daily.
//

import WidgetKit
import SwiftUI
import UIKit

struct ProverbEntry: TimelineEntry {
    let date: Date
    let proverb: Proverb
}

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

struct ProverbWidgetEntryView: View {
    var entry: ProverbProvider.Entry
    @Environment(\.widgetFamily) private var family

    private var ink: Color { Color(hex: "2A211C") }
    private var muted: Color { Color(hex: "2A211C").opacity(0.6) }
    private var accent: Color { Color(hex: "C05A3E") }

    private var isAccessory: Bool {
        family == .accessoryCircular || family == .accessoryRectangular || family == .accessoryInline
    }

    /// Type scale and margins, fitted to the real dataset rather than guessed:
    /// the longest saying is 55 characters, the longest meaning 100, the
    /// longest example 99. Each size was checked so that even the worst case
    /// fits inside the widget's content box — small shows the saying alone,
    /// medium adds the meaning, large adds an example underneath.
    private var metrics: (title: CGFloat, meaning: CGFloat, label: CGFloat, inset: CGFloat) {
        switch family {
        case .systemSmall: (14, 10, 10, 13)
        case .systemLarge: (31, 16, 13, 22)
        default:           (18, 12, 11, 15)
        }
    }

    /// Line budgets, so a long entry shrinks (minimumScaleFactor) instead of
    /// pushing the block below it off the card.
    ///
    /// Every size now carries the meaning and an example — the saying alone
    /// left the small widget looking like a fragment. The budgets are what
    /// makes that fit: two lines each on small and medium, checked against the
    /// dataset's median lengths (title 22, meaning 57, example 52 characters).
    private var lineBudget: (title: Int, meaning: Int, example: Int) {
        switch family {
        case .systemSmall: (2, 2, 2)
        case .systemLarge: (4, 4, 3)
        default:           (2, 2, 2)
        }
    }

    /// Medium reads as a caption card, so it's centred; the other two are
    /// left-aligned blocks.
    private var isCentred: Bool { family == .systemMedium }
    private var horizontal: HorizontalAlignment { isCentred ? .center : .leading }
    private var textAlignment: TextAlignment { isCentred ? .center : .leading }
    private var frameAlignment: Alignment { isCentred ? .center : .topLeading }

    var body: some View {
        if isAccessory {
            accessory
                .containerBackground(for: .widget) {
                    if family == .accessoryInline { Color.clear } else { AccessoryWidgetBackground() }
                }
        } else {
            home
        }
    }

    private var home: some View {
        VStack(alignment: horizontal, spacing: family == .systemSmall ? 4 : 6) {
            Text(entry.proverb.kindLabel)
                .font(.system(size: metrics.label, weight: .bold))
                .tracking(1)
                .foregroundStyle(accent)

            // On large, the saying sits in the optical centre with the example
            // at the foot. Anchoring everything to the top left a dead area in
            // the middle of the card — most sayings are short, and the layout
            // has to look composed for those, not just for the longest one.
            if family == .systemLarge { Spacer(minLength: 0) }

            Text(entry.proverb.title)
                .font(AppFont.serif(size: metrics.title, weight: .bold))
                .foregroundStyle(ink)
                .lineSpacing(family == .systemLarge ? 4 : 1)
                .lineLimit(lineBudget.title)
                .minimumScaleFactor(0.5)
                .fixedSize(horizontal: false, vertical: true)

            Text(entry.proverb.meaning)
                .font(AppFont.sans(size: metrics.meaning, weight: .regular))
                .foregroundStyle(muted)
                .lineSpacing(1)
                .lineLimit(lineBudget.meaning)
                .minimumScaleFactor(0.55)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 2)

            if !entry.proverb.example.isEmpty {
                VStack(alignment: horizontal, spacing: family == .systemSmall ? 4 : 6) {
                    Rectangle()
                        .fill(accent.opacity(0.35))
                        .frame(width: family == .systemSmall ? 18 : 24, height: 1.5)
                    Text(entry.proverb.example)
                        .font(AppFont.serif(size: metrics.meaning, weight: .regular))
                        .italic()
                        .foregroundStyle(muted.opacity(0.85))
                        .lineSpacing(1)
                        .lineLimit(lineBudget.example)
                        .minimumScaleFactor(0.55)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .multilineTextAlignment(textAlignment)
        .padding(metrics.inset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: frameAlignment)
        .containerBackground(for: .widget) { backdrop }
    }

    /// Time-of-day artwork, the same hour mapping the other widgets use.
    private var backgroundName: String {
        let hour = Calendar.current.component(.hour, from: entry.date)
        let base: String
        switch hour {
        case 5..<11: base = "proverb-bg-morning"
        case 11..<19: base = "proverb-bg-day"
        default: base = "proverb-bg-evening"
        }
        return family == .systemMedium ? base + "-wide" : base
    }

    /// Warm paper. Distinct from Daily's cream/gold so the two don't read as
    /// the same widget in the gallery. Uses the generated artwork when it's in
    /// the catalog and draws the same look in code when it isn't.
    private var backdrop: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FBF4EA"), Color(hex: "F0E2CE")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color(hex: "E3C49B").opacity(0.5), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 240
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
            VStack(spacing: 1) {
                Image(systemName: "quote.opening").font(.system(size: 14, weight: .light))
                Text(entry.proverb.isProverb ? "ATA" : "DEY")
                    .font(.system(size: 8, weight: .bold))
                    .opacity(0.8)
            }

        case .accessoryInline:
            Text(entry.proverb.title)

        default: // accessoryRectangular
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.proverb.title)
                    .font(.system(size: 13, weight: .semibold, design: .serif))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Text(entry.proverb.meaning)
                    .font(.system(size: 10, weight: .regular))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .opacity(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ProverbWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ProverbWidget", provider: ProverbProvider()) { entry in
            ProverbWidgetEntryView(entry: entry)
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
