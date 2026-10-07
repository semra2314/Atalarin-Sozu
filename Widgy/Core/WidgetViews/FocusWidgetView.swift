//
//  FocusWidgetView.swift
//  Kare  (shared: app + widget extension)
//
//  The Focus widget's entry and view, moved out of the extension so the app can
//  draw the real widget, at every size, on the detail page. The provider and
//  the Widget declaration stay in actual-widgets/FocusWidget.swift.
//

import WidgetKit
import SwiftUI
import AppIntents

nonisolated struct FocusEntry: TimelineEntry {
    let date: Date
    let session: FocusSession?
}

struct FocusWidgetEntryView: View {
    var entry: FocusEntry
    @Environment(\.widgetFamily) private var environmentFamily
    /// Set by the in-app preview, which has no widget family of its own.
    var familyOverride: WidgetFamily? = nil
    private var family: WidgetFamily { familyOverride ?? environmentFamily }

    /// Medium is a wide 2.13:1 letterbox and would badly crop the square art,
    /// so it uses the purpose-made "-wide" version.
    private var backgroundName: String {
        let base: String
        if entry.session == nil {
            base = "focus-bg-ready"
        } else {
            let hour = Calendar.current.component(.hour, from: entry.date)
            base = hour >= 20 || hour < 6 ? "focus-bg-night" : "focus-bg-deep"
        }
        return family == .systemMedium ? base + "-wide" : base
    }

    /// `.contentMarginsDisabled()` lets the art bleed to the edges, so the
    /// content owes itself padding — without it the title clipped the corners.
    private var inset: CGFloat {
        switch family {
        case .systemSmall: 14
        case .systemLarge: 20
        default: 16
        }
    }

    private var accent: Color { Color(hex: "4CC9F0") }

    /// Lock screen families render vibrant/monochrome, so they get a stripped
    /// typographic treatment rather than the full artwork.
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
            content
                .padding(inset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .kareWidgetBackground {
                    ZStack {
                        Color(hex: "10151F")
                        Image(backgroundName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder private var accessory: some View {
        let session = entry.session

        switch family {
        case .accessoryCircular:
            if let session {
                // A ring that empties as the session runs — readable at a glance
                // without needing to parse digits.
                ZStack {
                    if session.isPaused {
                        Gauge(value: session.progress()) { EmptyView() }
                            .gaugeStyle(.accessoryCircularCapacity)
                        Image(systemName: "pause.fill").font(.system(size: 12, weight: .bold))
                    } else {
                        ProgressView(timerInterval: session.startedAt...session.endsAt,
                                     countsDown: true) { EmptyView() } currentValueLabel: {
                            Text(session.endsAt, style: .timer)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                        }
                        .progressViewStyle(.circular)
                    }
                }
            } else {
                VStack(spacing: 1) {
                    Image(systemName: "bolt.fill").font(.system(size: 14, weight: .bold))
                    Text("Focus").font(.system(size: 9, weight: .semibold))
                }
            }

        case .accessoryInline:
            if let session {
                if session.isPaused {
                    Label("Focus paused · \(session.remainingText)", systemImage: "pause.fill")
                } else {
                    Label {
                        Text(session.endsAt, style: .timer)
                    } icon: {
                        Image(systemName: "bolt.fill")
                    }
                }
            } else {
                Label("No focus session", systemImage: "bolt.slash")
            }

        default: // accessoryRectangular
            if let session {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if session.isPaused {
                        Text(session.remainingText)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    } else {
                        Text(session.endsAt, style: .timer)
                            .font(.system(size: 22, weight: .heavy, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    if session.isPaused {
                        ProgressView(value: session.progress()).progressViewStyle(.linear)
                    } else {
                        ProgressView(timerInterval: session.startedAt...session.endsAt, countsDown: false)
                            .labelsHidden()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Focus").font(.system(size: 14, weight: .semibold))
                    Text("No session running")
                        .font(.system(size: 11, weight: .medium))
                        .opacity(0.75)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private var content: some View {
        if let session = entry.session {
            active(session)
        } else {
            idle
        }
    }

    // MARK: Shared pieces

    /// Centred title + status. The title is sized generously against the
    /// widget so it reads as the headline of the card rather than a caption.
    private var titleSize: CGFloat {
        switch family {
        case .systemSmall: 22
        case .systemLarge: 40
        default: 30
        }
    }

    private func titleBlock(_ title: String, subtitle: String?, showsDot: Bool) -> some View {
        VStack(spacing: 5) {
            Text(verbatim: WidgetLanguage.localized(title))
                .font(AppFont.sans(size: titleSize, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let subtitle {
                HStack(spacing: 6) {
                    if showsDot {
                        Circle().fill(accent).frame(width: 8, height: 8)
                    }
                    Text(verbatim: WidgetLanguage.localized(subtitle))
                        .font(AppFont.sans(size: family == .systemSmall ? 11 : 14, weight: .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    /// "45 min / 90 min" — elapsed over total, exactly as the promo reads.
    private func elapsedText(_ session: FocusSession) -> String {
        let remaining = Int(ceil(session.remaining() / 60))
        let elapsed = max(0, session.durationMinutes - remaining)
        return String(format: WidgetLanguage.localized("%lld min / %lld min"), elapsed, session.durationMinutes)
    }

    /// Live countdown while running; a frozen figure while paused.
    @ViewBuilder private func countdown(_ session: FocusSession, size: CGFloat) -> some View {
        Group {
            if session.isPaused {
                Text(session.remainingText)
            } else {
                Text(session.endsAt, style: .timer)
            }
        }
        .font(AppFont.sans(size: size, weight: .bold))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }

    @ViewBuilder private func progressBar(_ session: FocusSession) -> some View {
        Group {
            if session.isPaused {
                ProgressView(value: session.progress())
            } else {
                ProgressView(timerInterval: session.startedAt...session.endsAt, countsDown: false)
            }
        }
        .tint(accent)
        .labelsHidden()
    }

    /// Pause/resume + stop. Compact icon-only pills on small, labelled on the
    /// bigger families.
    private func controls(_ session: FocusSession, compact: Bool) -> some View {
        HStack(spacing: 8) {
            // Two separate buttons rather than one with a ternary intent:
            // `Button(intent:)` is generic over the intent type, so the two
            // branches can't be folded into a single expression.
            if session.isPaused {
                Button(intent: ResumeFocusIntent()) {
                    label(icon: "play.fill", text: "Resume", compact: compact, filled: true)
                }
                .buttonStyle(.plain)
            } else {
                Button(intent: PauseFocusIntent()) {
                    label(icon: "pause.fill", text: "Pause", compact: compact, filled: true)
                }
                .buttonStyle(.plain)
            }

            Button(intent: StopFocusIntent()) {
                label(icon: "stop.fill", text: "Stop", compact: compact, filled: false)
            }
            .buttonStyle(.plain)
        }
    }

    private func label(icon: String, text: String, compact: Bool, filled: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: compact ? 11 : 13, weight: .bold))
            if !compact {
                Text(verbatim: WidgetLanguage.localized(text)).font(AppFont.sans(size: 14, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: compact ? 28 : 36)
        .background(filled ? AnyShapeStyle(accent) : AnyShapeStyle(.white.opacity(0.16)), in: .capsule)
        .foregroundStyle(filled ? Color(hex: "0C111B") : .white)
    }

    // MARK: Active

    @ViewBuilder private func active(_ session: FocusSession) -> some View {
        let status = session.isPaused ? "Paused" : "In progress"

        switch family {
        case .systemSmall:
            VStack(alignment: .leading, spacing: 6) {
                titleBlock(session.title, subtitle: status, showsDot: !session.isPaused)
                Spacer(minLength: 2)
                countdown(session, size: 24)
                progressBar(session)
                Spacer(minLength: 2)
                controls(session, compact: true)
            }

        case .systemLarge:
            // The promo layout: title, status, progress bar, elapsed/total,
            // then the quiet line at the bottom.
            VStack(alignment: .leading, spacing: 14) {
                titleBlock(session.title, subtitle: status, showsDot: !session.isPaused)
                progressBar(session)
                HStack(alignment: .firstTextBaseline) {
                    Text(elapsedText(session))
                        .font(AppFont.sans(size: 15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    countdown(session, size: 17)
                        .foregroundStyle(.white.opacity(0.9))
                }
                Spacer(minLength: 0)
                HStack(alignment: .bottom) {
                    Text("Stay focused.")
                        .font(AppFont.sans(size: 15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.45))
                    Spacer()
                    friendsFocusing
                }
                controls(session, compact: false)
            }

        default: // medium
            VStack(alignment: .leading, spacing: 9) {
                titleBlock(session.title, subtitle: status, showsDot: !session.isPaused)
                progressBar(session)
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(elapsedText(session))
                        .font(AppFont.sans(size: 13, weight: .regular))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 0)
                    controls(session, compact: true)
                        .frame(maxWidth: 120)
                }
            }
        }
    }

    private var friendsFocusing: some View {
        HStack(spacing: -8) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color(hex: ["7C3AED", "D44A33", "1D9E75"][i]))
                    .frame(width: 26, height: 26)
                    .overlay(Image(systemName: "person.fill").font(.system(size: 11)).foregroundStyle(.white))
                    .overlay(Circle().stroke(Color(hex: "10151F"), lineWidth: 2))
            }
        }
    }

    // MARK: Idle

    private var idle: some View {
        VStack(alignment: .leading, spacing: 10) {
            titleBlock(
                "Focus",
                subtitle: family == .systemSmall ? nil : "Start a deep-work session.",
                showsDot: false
            )
            Spacer(minLength: 0)
            Button(intent: StartFocusIntent()) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                        .font(.system(size: family == .systemSmall ? 11 : 13, weight: .bold))
                    Text(family == .systemSmall ? "Start" : "Start focus")
                        .font(AppFont.sans(size: family == .systemSmall ? 13 : 15, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .frame(maxWidth: .infinity)
                .frame(height: family == .systemSmall ? 30 : 38)
                .background(accent, in: .capsule)
                .foregroundStyle(Color(hex: "0C111B"))
            }
            .buttonStyle(.plain)
        }
    }
}
