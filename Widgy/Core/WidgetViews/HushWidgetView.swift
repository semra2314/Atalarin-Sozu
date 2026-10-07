//
//  HushWidgetView.swift
//  Kare  (shared: app + widget extension)
//
//  The Hush widget's entry and view, moved out of the extension so the app can
//  draw the real widget, at every size, on the detail page. The provider and
//  the Widget declaration stay in actual-widgets/HushWidget.swift.
//

import WidgetKit
import SwiftUI
import UIKit

nonisolated struct HushEntry: TimelineEntry {
    let date: Date
    let word: String
}

struct HushWidgetEntryView: View {
    var entry: HushEntry
    @Environment(\.widgetFamily) private var environmentFamily
    /// Set by the in-app preview, which has no widget family of its own.
    var familyOverride: WidgetFamily? = nil
    private var family: WidgetFamily { familyOverride ?? environmentFamily }

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
                .kareWidgetBackground {
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
        Text(verbatim: WidgetLanguage.localized(entry.word))
            .font(AppFont.serif(size: wordSize, weight: .regular))
            .foregroundStyle(Color(hex: "C9C6C1"))
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(family == .systemSmall ? 14 : 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .kareWidgetBackground { backdrop }
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
            Text(verbatim: WidgetLanguage.localized(entry.word))
                .font(.system(size: 13, weight: .medium, design: .serif))
                .minimumScaleFactor(0.4)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(4)

        case .accessoryInline:
            Text(verbatim: WidgetLanguage.localized(entry.word))

        default: // accessoryRectangular
            Text(verbatim: WidgetLanguage.localized(entry.word))
                .font(.system(size: 22, weight: .regular, design: .serif))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}
