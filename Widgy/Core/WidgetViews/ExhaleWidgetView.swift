//
//  ExhaleWidgetView.swift
//  Kare  (shared: app + widget extension)
//
//  The Exhale widget's entry and view, moved out of the extension so the app can
//  draw the real widget, at every size, on the detail page. The provider and
//  the Widget declaration stay in actual-widgets/ExhaleWidget.swift.
//

import WidgetKit
import SwiftUI
import AppIntents

nonisolated struct ExhaleEntry: TimelineEntry {
    let date: Date
    let plan: QuitPlan?
    let unlocked: Bool
}

struct ExhaleWidgetEntryView: View {
    var entry: ExhaleEntry
    @Environment(\.widgetFamily) private var environmentFamily
    /// Set by the in-app preview, which has no widget family of its own.
    var familyOverride: WidgetFamily? = nil
    private var family: WidgetFamily { familyOverride ?? environmentFamily }

    private var ink: Color { Color.white }
    private var money: Color { Color(hex: "FDE68A") }

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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundStyle(ink)
                .kareWidgetBackground {
                    let stage = entry.plan?.stage(at: entry.date) ?? .forest
                    KarePlusBackground(art: entry.unlocked ? stage.art : nil,
                                       family: family,
                                       fallback: stage.fallbackHexes.map { Color(hex: $0) },
                                       scrimStrength: 0.5)
                }
        }
    }

    // MARK: Home screen

    @ViewBuilder private var home: some View {
        if !entry.unlocked {
            locked
        } else if let plan = entry.plan {
            switch family {
            case .systemSmall: small(plan)
            case .systemLarge: large(plan)
            default: medium(plan)
            }
        } else {
            setUp
        }
    }

    private func lungsButton(_ plan: QuitPlan) -> some View {
        let breathing = plan.isBreathing(at: entry.date)
        return Button(intent: TakeBreathIntent()) {
            LungsGauge(level: plan.drawnLevel(at: entry.date))
                // A glow that swells with the breath.
                .shadow(color: Color(hex: "6EE7B7").opacity(breathing ? 0.9 : 0.35),
                        radius: breathing ? 16 : 6)
                .scaleEffect(breathing ? 1.06 : 1)
        }
        .buttonStyle(.plain)
    }

    /// Five marks, one per WHO milestone, filled as they are reached.
    private func milestoneDots(_ plan: QuitPlan) -> some View {
        let reached = plan.milestonesReached(at: entry.date)
        return HStack(spacing: 4) {
            ForEach(0..<QuitMilestone.all.count, id: \.self) { index in
                Capsule()
                    .fill(index < reached ? Color(hex: "6EE7B7") : Color.white.opacity(0.22))
                    .frame(width: family == .systemLarge ? 10 : 6, height: 4)
            }
        }
    }

    private func headline(_ plan: QuitPlan) -> Text {
        let days = plan.days(at: entry.date)
        if days >= 1 {
            return Text("\(days) days")
        }
        return Text("\(plan.hours(at: entry.date)) hours")
    }

    private func caption(_ plan: QuitPlan) -> Text {
        plan.isBreathing(at: entry.date) ? Text("Breathe in…") : Text("smoke-free")
    }

    private func small(_ plan: QuitPlan) -> some View {
        VStack(spacing: 6) {
            lungsButton(plan)
                .frame(maxHeight: .infinity)
            VStack(spacing: 0) {
                headline(plan)
                    .font(AppFont.serif(size: 20, weight: .heavy))
                    .contentTransition(.numericText())
                Text(plan.moneyText(at: entry.date))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(money)
                    .contentTransition(.numericText())
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            milestoneDots(plan)
        }
    }

    private func medium(_ plan: QuitPlan) -> some View {
        HStack(spacing: 16) {
            lungsButton(plan)

            VStack(alignment: .leading, spacing: 4) {
                caption(plan)
                    .font(.system(size: 11, weight: .semibold))
                    .textCase(.uppercase)
                    .opacity(0.7)
                headline(plan)
                    .font(AppFont.serif(size: 26, weight: .heavy))
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                milestoneDots(plan)

                HStack(spacing: 10) {
                    stat(value: Text(plan.moneyText(at: entry.date)), label: Text("saved"), color: money)
                    stat(value: Text("\(plan.cigarettesAvoided(at: entry.date))"), label: Text("not smoked"), color: ink)
                }

                Spacer(minLength: 0)
                restartButton(plan)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// The full picture: the numbers, and what the body is doing right now.
    private func large(_ plan: QuitPlan) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(plan.stage(at: entry.date).titleKey))
                        .font(.system(size: 12, weight: .semibold))
                        .textCase(.uppercase)
                        .opacity(0.7)
                    headline(plan)
                        .font(AppFont.serif(size: 34, weight: .heavy))
                        .contentTransition(.numericText())
                }
                Spacer()
                restartButton(plan)
            }

            HStack(spacing: 14) {
                lungsButton(plan)
                    .frame(maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 8) {
                    stat(value: Text(plan.moneyText(at: entry.date)), label: Text("saved"), color: money)
                    stat(value: Text("\(plan.cigarettesAvoided(at: entry.date))"), label: Text("not smoked"), color: ink)
                    stat(value: Text(plan.lifeRegainedText(at: entry.date)), label: Text("of life won back"),
                         color: Color(hex: "A7F3D0"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            milestoneDots(plan)

            if let now = plan.currentMilestone(at: entry.date) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: now.part.symbolName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "6EE7B7"))
                        .frame(width: 18)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Now")
                            .font(.system(size: 10, weight: .bold))
                            .textCase(.uppercase)
                            .opacity(0.6)
                        Text(LocalizedStringKey(now.detailKey))
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                    }
                }
            }

            if let next = plan.nextMilestone(at: entry.date) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: next.part.symbolName)
                        .font(.system(size: 13, weight: .semibold))
                        .opacity(0.6)
                        .frame(width: 18)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Next · \(next.remainingText(from: plan.elapsed(at: entry.date)))")
                            .font(.system(size: 10, weight: .bold))
                            .textCase(.uppercase)
                            .opacity(0.6)
                        Text(LocalizedStringKey(next.titleKey))
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
        }
    }

    private func stat(value: Text, label: Text, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            value
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            label
                .font(.system(size: 10, weight: .medium))
                .opacity(0.65)
        }
    }

    /// Two taps: the first turns the button into a question.
    private func restartButton(_ plan: QuitPlan) -> some View {
        let armed = plan.isResetArmed(at: entry.date)
        return Button(intent: RestartQuitIntent()) {
            HStack(spacing: 4) {
                Image(systemName: armed ? "exclamationmark.arrow.circlepath" : "arrow.counterclockwise")
                if armed { Text("Sure? Tap again") } else { Text("Restart") }
            }
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(armed ? Color(hex: "F87171").opacity(0.35) : Color.white.opacity(0.14), in: .capsule)
        }
        .buttonStyle(.plain)
    }

    private var setUp: some View {
        VStack(spacing: 8) {
            LungsGauge(level: 0.15)
                .frame(maxHeight: 60)
            Text("Set your quit date in Kare")
                .font(.system(size: 12, weight: .semibold))
                .multilineTextAlignment(.center)
        }
    }

    private var locked: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.fill")
                .font(.system(size: 18, weight: .bold))
            Text("Unlock with Kare+")
                .font(.system(size: 12, weight: .semibold))
                .multilineTextAlignment(.center)
        }
        .opacity(0.85)
    }

    // MARK: Lock screen

    @ViewBuilder private var accessory: some View {
        if let plan = entry.plan, entry.unlocked {
            switch family {
            case .accessoryCircular:
                Gauge(value: plan.recovery(at: entry.date)) {
                    Image(systemName: "lungs.fill")
                } currentValueLabel: {
                    Text("\(plan.days(at: entry.date))")
                }
                .gaugeStyle(.accessoryCircularCapacity)
            case .accessoryInline:
                Label {
                    Text("\(plan.days(at: entry.date)) days · \(plan.moneyText(at: entry.date))")
                } icon: {
                    Image(systemName: "lungs.fill")
                }
            default:
                VStack(alignment: .leading, spacing: 2) {
                    headline(plan)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                    Text("\(plan.moneyText(at: entry.date)) saved")
                        .font(.system(size: 12, weight: .medium))
                    Gauge(value: plan.recovery(at: entry.date)) { EmptyView() }
                        .gaugeStyle(.accessoryLinearCapacity)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            Image(systemName: "lungs")
        }
    }
}
