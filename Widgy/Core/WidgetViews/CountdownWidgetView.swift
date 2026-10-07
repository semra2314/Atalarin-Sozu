//
//  CountdownWidgetView.swift
//  Kare  (shared: app + widget extension)
//
//  The Countdown widget's entry and view, moved out of the extension so the app can
//  draw the real widget, at every size, on the detail page. The provider and
//  the Widget declaration stay in actual-widgets/CountdownWidget.swift.
//

import WidgetKit
import SwiftUI
import AppIntents

nonisolated struct CountdownEntry: TimelineEntry {
    let date: Date
    let event: CountdownEvent?
    let unlocked: Bool
}

struct CountdownWidgetEntryView: View {
    var entry: CountdownEntry
    @Environment(\.widgetFamily) private var environmentFamily
    /// Set by the in-app preview, which has no widget family of its own.
    var familyOverride: WidgetFamily? = nil
    private var family: WidgetFamily { familyOverride ?? environmentFamily }

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
                .foregroundStyle(.white)
                .kareWidgetBackground {
                    KarePlusBackground(art: entry.unlocked ? entry.event?.theme?.art : nil,
                                       family: family,
                                       fallback: (entry.event?.fallbackHexes ?? ["1D1D1F", "3A3A3C"]).map { Color(hex: $0) },
                                       scrimStrength: 0.45)
                }
        }
    }

    @ViewBuilder private var home: some View {
        if !entry.unlocked {
            centered(icon: "lock.fill", text: Text("Unlock with Kare+"))
        } else if let event = entry.event {
            let days = event.daysLeft(from: entry.date)
            VStack(alignment: .leading, spacing: 6) {
                header(event)

                Spacer(minLength: 0)

                switch family {
                case .systemSmall:
                    HStack {
                        number(days)
                        Spacer(minLength: 0)
                        if event.style != .bold, days > 0 { ring(event) }
                    }
                case .systemLarge:
                    number(days)
                    details(event, days: days)
                    if event.style != .bold { marks(event) }
                default:
                    HStack(alignment: .bottom) {
                        number(days)
                        Spacer(minLength: 0)
                        dateLine(event)
                    }
                    if event.style != .bold { marks(event) }
                }
            }
        } else {
            centered(icon: "calendar.badge.plus", text: Text("Add a countdown in Kare"))
        }
    }

    private func header(_ event: CountdownEvent) -> some View {
        HStack(spacing: 6) {
            Text(event.emoji)
                .font(.system(size: family == .systemLarge ? 30 : (family == .systemSmall ? 18 : 22)))
            Text(event.title)
                .font(.system(size: family == .systemLarge ? 16 : 13, weight: .semibold))
                .lineLimit(1)
                .opacity(0.95)
        }
    }

    private func dateLine(_ event: CountdownEvent) -> some View {
        Text(event.date, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
            .font(.system(size: 11, weight: .semibold))
            .opacity(0.8)
    }

    /// The large widget's extra line: the date in full, and the wait in
    /// weeks, which is how people actually think about anything far away.
    @ViewBuilder private func details(_ event: CountdownEvent, days: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(event.date, format: .dateTime.weekday(.wide).day().month(.wide).year())
                .font(.system(size: 13, weight: .semibold))
            if days >= 7 {
                Text("\(days / 7) weeks · \(days % 7) days")
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.75)
            }
        }
    }

    /// A ring that closes as the day approaches.
    private func ring(_ event: CountdownEvent) -> some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.2), lineWidth: 5)
            Circle()
                .trim(from: 0, to: event.progress(at: entry.date))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Image(systemName: event.style == .hearts ? "heart.fill" : "circle.fill")
                .font(.system(size: 8))
        }
        .frame(width: 38, height: 38)
    }

    @ViewBuilder private func number(_ days: Int) -> some View {
        let size: CGFloat = switch family {
        case .systemSmall: entry.event?.style == .bold ? 58 : 44
        case .systemLarge: 72
        default: 52
        }
        if days > 0 {
            VStack(alignment: .leading, spacing: -4) {
                Text(days, format: .number)
                    .font(AppFont.serif(size: size, weight: .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Group {
                    if days == 1 { Text("day to go") } else { Text("days to go") }
                }
                .font(.system(size: 12, weight: .medium))
                .opacity(0.75)
            }
        } else if days == 0 {
            Text("Today!")
                .font(AppFont.serif(size: size * 0.75, weight: .heavy))
        } else {
            Text("\(-days) days ago")
                .font(AppFont.serif(size: size * 0.45, weight: .bold))
                .opacity(0.85)
        }
    }

    /// One mark per day of the wait: filled for days behind you, faint for
    /// days still to come. Capped, so a countdown made a year out still fits.
    private func marks(_ event: CountdownEvent) -> some View {
        let cap = family == .systemLarge ? 72 : 42
        let total = min(event.totalDays, cap)
        let filled = Int((Double(total) * event.progress(at: entry.date)).rounded())
        let columns = family == .systemLarge ? 12 : 21
        let symbol = event.style == .hearts ? "heart.fill" : "circle.fill"
        let markSize: CGFloat = family == .systemLarge ? 13 : 8

        let rows = (total + columns - 1) / columns

        // Plain stacks rather than a lazy grid: widgets are rendered once,
        // ahead of time, and lazy containers buy nothing there.
        return VStack(alignment: .leading, spacing: 3) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<min(columns, total - row * columns), id: \.self) { column in
                        let index = row * columns + column
                        Image(systemName: symbol)
                            .font(.system(size: markSize))
                            .opacity(index < filled ? 1 : 0.25)
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
        .opacity(0.85)
    }

    // MARK: Lock screen

    @ViewBuilder private var accessory: some View {
        if let event = entry.event, entry.unlocked {
            let days = event.daysLeft(from: entry.date)
            switch family {
            case .accessoryCircular:
                Gauge(value: event.progress(at: entry.date)) {
                    Text(event.emoji)
                } currentValueLabel: {
                    Text(max(0, days), format: .number)
                }
                .gaugeStyle(.accessoryCircularCapacity)
            case .accessoryInline:
                Text("\(event.emoji) \(max(0, days)) days · \(event.title)")
            default:
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(event.emoji) \(event.title)")
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                    Text("\(max(0, days)) days")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                    Gauge(value: event.progress(at: entry.date)) { EmptyView() }
                        .gaugeStyle(.accessoryLinearCapacity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Image(systemName: "calendar")
        }
    }
}
