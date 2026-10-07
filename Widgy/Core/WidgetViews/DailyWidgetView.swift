//
//  DailyWidgetView.swift
//  Kare  (shared: app + widget extension)
//
//  The Daily widget's entry and view, moved out of the extension so the app can
//  draw the real widget, at every size, on the detail page. The provider and
//  the Widget declaration stay in actual-widgets/DailyWidget.swift.
//

import WidgetKit
import SwiftUI
import UIKit

nonisolated struct DailyEntry: TimelineEntry {
    let date: Date
    let passage: DailyPassage
    let source: DailySource
}

struct DailyWidgetEntryView: View {
    var entry: DailyEntry
    @Environment(\.widgetFamily) private var environmentFamily
    /// Set by the in-app preview, which has no widget family of its own.
    var familyOverride: WidgetFamily? = nil
    private var family: WidgetFamily { familyOverride ?? environmentFamily }

    // Dark ink on warm paper. The passage should read like something printed,
    // not like something lit up.
    private var ink: Color { Color(hex: "2B2018") }
    private var muted: Color { Color(hex: "2B2018").opacity(0.55) }

    private var isAccessory: Bool {
        family == .accessoryCircular || family == .accessoryRectangular || family == .accessoryInline
    }

    /// Passages vary a lot in length, so the type scale is a starting point and
    /// `minimumScaleFactor` does the rest rather than truncating mid-sentence.
    private var metrics: (quote: CGFloat, reference: CGFloat, inset: CGFloat, lines: Int) {
        switch family {
        case .systemSmall: (16, 10, 13, 7)
        case .systemLarge: (33, 15, 22, 11)
        default:           (21, 12, 17, 5)
        }
    }

    var body: some View {
        if isAccessory {
            accessory
                .kareWidgetBackground {
                    if family == .accessoryInline { Color.clear } else { AccessoryWidgetBackground() }
                }
        } else {
            home
        }
    }

    /// Centred on both axes — the passage sits in the middle of the page like
    /// an epigraph, rather than being pinned to a corner.
    private var home: some View {
        VStack(spacing: family == .systemSmall ? 7 : 12) {
            Text(entry.passage.text)
                .font(AppFont.serif(size: metrics.quote, weight: .regular))
                .foregroundStyle(ink)
                .lineSpacing(family == .systemLarge ? 6 : 3)
                .lineLimit(metrics.lines)
                .minimumScaleFactor(0.45)
                .fixedSize(horizontal: false, vertical: true)

            if !entry.passage.reference.isEmpty {
                Text(entry.passage.reference)
                    .font(AppFont.sans(size: metrics.reference, weight: .medium))
                    .foregroundStyle(muted)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
            }
        }
        .multilineTextAlignment(.center)
        .padding(metrics.inset)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .kareWidgetBackground { backdrop }
    }

    /// Time-of-day artwork. Deliberately keyed to the hour rather than to the
    /// chosen source: colour-coding scripture by tradition would turn a neutral
    /// widget into a statement about whose book is whose.
    private var backgroundName: String {
        let hour = Calendar.current.component(.hour, from: entry.date)
        let base: String
        switch hour {
        case 5..<11: base = "daily-bg-morning"
        case 11..<19: base = "daily-bg-day"
        default: base = "daily-bg-evening"
        }
        return family == .systemMedium ? base + "-wide" : base
    }

    /// Warm cream paper with a low gold light. Neutral on purpose: this widget
    /// carries scripture for some people and philosophy for others, so it
    /// shouldn't look like it belongs to any one of them. Uses the generated
    /// artwork when it's in the catalog, and draws the same look in code when
    /// it isn't.
    private var backdrop: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "FAF3E7"), Color(hex: "EBDCC4")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            RadialGradient(
                colors: [Color(hex: "E8C88A").opacity(0.55), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 260
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
            Image(systemName: entry.source.symbolName)
                .font(.system(size: 18, weight: .light))

        case .accessoryInline:
            Text(entry.passage.text)

        default: // accessoryRectangular
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.passage.text)
                    .font(.system(size: 13, weight: .regular, design: .serif))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Text(entry.passage.reference)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .opacity(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
