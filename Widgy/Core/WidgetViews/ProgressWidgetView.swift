//
//  ProgressWidgetView.swift
//  Kare  (shared: app + widget extension)
//
//  The Progress widget's entry and view, moved out of the extension so the app can
//  draw the real widget, at every size, on the detail page. The provider and
//  the Widget declaration stay in actual-widgets/ProgressWidget.swift.
//

import WidgetKit
import SwiftUI
import AppIntents

nonisolated struct ProgressEntry: TimelineEntry {
    let date: Date
    let kind: ProgressKind
    let unlocked: Bool
}

struct ProgressWidgetEntryView: View {
    var entry: ProgressEntry
    @Environment(\.widgetFamily) private var environmentFamily
    /// Set by the in-app preview, which has no widget family of its own.
    var familyOverride: WidgetFamily? = nil
    private var family: WidgetFamily { familyOverride ?? environmentFamily }

    private var paper: Color { Color(hex: "F6F1E7") }
    private var ink: Color { entry.kind.isDark ? .white : Color(hex: "1D1D1F") }
    private var accent: Color { Color(hex: "D44A33") }

    private var isAccessory: Bool {
        family == .accessoryCircular || family == .accessoryRectangular || family == .accessoryInline
    }

    private var inset: CGFloat {
        switch family {
        case .systemSmall: 14
        case .systemLarge: 20
        default: 16
        }
    }

    private var fraction: Double? { entry.kind.fraction(at: entry.date) }

    var body: some View {
        if isAccessory {
            accessory
                .kareWidgetBackground {
                    if family == .accessoryInline { Color.clear } else { AccessoryWidgetBackground() }
                }
        } else {
            home
                .padding(inset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .foregroundStyle(ink)
                .kareWidgetBackground {
                    KarePlusBackground(
                        art: entry.unlocked ? entry.kind.art(at: entry.date) : nil,
                        family: family,
                        fallback: entry.kind.isDark
                            ? [Color(hex: "0B1026"), Color(hex: "2A2358")]
                            : [paper, Color(hex: "EDE4D3")],
                        scrim: entry.kind.isDark ? .black : .white,
                        scrimStrength: entry.kind.isDark ? 0.45 : 0.35
                    )
                }
        }
    }

    @ViewBuilder private var home: some View {
        if !entry.unlocked {
            centered(icon: "lock.fill", text: Text("Unlock with Kare+"))
        } else if let fraction {
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.kind.title(at: entry.date))
                    .font(.system(size: 12, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.6)
                    .opacity(0.6)

                Text(fraction, format: .percent.precision(.fractionLength(0)))
                    .font(AppFont.serif(size: family == .systemLarge ? 64 : (family == .systemSmall ? 44 : 36), weight: .heavy))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if let remaining = entry.kind.remainingText(at: entry.date) {
                    Text(remaining)
                        .font(.system(size: 11, weight: .semibold))
                        .opacity(0.65)
                }

                Spacer(minLength: 0)

                if family == .systemSmall {
                    bar(fraction)
                } else {
                    marks(fraction)
                }
            }
        } else {
            centered(icon: "birthday.cake", text: Text("Add your birthday in Kare"))
        }
    }

    private func bar(_ fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(ink.opacity(0.1))
                Capsule().fill(accent).frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 6)
    }

    /// One mark per unit. The current unit is drawn in the accent colour, so
    /// "now" is always findable at a glance.
    private func marks(_ fraction: Double) -> some View {
        let units = entry.kind.units(at: entry.date)
        let passed = Double(units) * fraction
        let current = min(units - 1, Int(passed))
        let dense = units > 40   // a life in years
        let columns = family == .systemLarge ? (dense ? 10 : 7) : (dense ? 27 : min(units, 16))
        let rows = (units + columns - 1) / columns
        let size: CGFloat = family == .systemLarge ? (dense ? 14 : 22) : (dense ? 6 : 9)

        return VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 4) {
                    ForEach(0..<min(columns, units - row * columns), id: \.self) { column in
                        let index = row * columns + column
                        Circle()
                            .fill(index == current ? accent : ink.opacity(index < current ? 0.85 : 0.12))
                            .frame(width: size, height: size)
                    }
                }
            }
        }
    }

    private func centered(icon: String, text: Text) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 18, weight: .bold))
            text
                .font(.system(size: 12, weight: .semibold))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(0.8)
    }

    // MARK: Lock screen

    @ViewBuilder private var accessory: some View {
        if let fraction, entry.unlocked {
            switch family {
            case .accessoryCircular:
                Gauge(value: fraction) {
                    Text(entry.kind.title(at: entry.date))
                } currentValueLabel: {
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                }
                .gaugeStyle(.accessoryCircularCapacity)
            case .accessoryInline:
                Text("\(entry.kind.title(at: entry.date)) · \(fraction.formatted(.percent.precision(.fractionLength(0))))")
            default:
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.kind.title(at: entry.date))
                        .font(.system(size: 12, weight: .semibold))
                    Text(fraction, format: .percent.precision(.fractionLength(0)))
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                    Gauge(value: fraction) { EmptyView() }
                        .gaugeStyle(.accessoryLinearCapacity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Image(systemName: "chart.bar.fill")
        }
    }
}
