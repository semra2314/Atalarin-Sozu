//
//  FocusView.swift
//  Widgy
//
//  In-app focus session control: pick a duration + ambient sound, start, and
//  watch a live ring count down. State is shared to the App Group so the
//  home-screen Focus widget mirrors it.
//

import SwiftUI
import Combine

struct FocusView: View {
    @State private var session: FocusSession? = FocusSessionStore.load()
    @State private var now = Date()
    @State private var duration = 45
    @State private var soundName: String?

    private let durations = [25, 45, 60, 90]
    private let sounds: [(label: String, name: String?)] = [
        ("Silent", nil), ("Rain", "rain"), ("Cafe", "cafe"), ("Waves", "waves"), ("White noise", "whitenoise")
    ]
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xxl) {
                if let session, !session.isFinished(at: now) {
                    running(session)
                } else {
                    setup
                }
            }
            .padding(Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
        }
        .background(Theme.Palette.background)
        .navigationTitle("Focus")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(ticker) { date in
            now = date
            if let session, session.isFinished(at: date) { finish() }
        }
    }

    // MARK: Running

    private func running(_ session: FocusSession) -> some View {
        VStack(spacing: Theme.Spacing.xl) {
            Text(session.title)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Palette.ink)

            ZStack {
                Circle()
                    .stroke(Theme.Palette.hairline, lineWidth: 14)
                Circle()
                    .trim(from: 0, to: session.progress(at: now))
                    .stroke(Theme.Palette.accent, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: now)
                VStack(spacing: 2) {
                    Text(remainingString(session))
                        .font(AppFont.serif(size: 44, weight: .bold))
                        .foregroundStyle(Theme.Palette.ink)
                        .monospacedDigit()
                    Text("remaining")
                        .font(Theme.Typography.label)
                        .foregroundStyle(Theme.Palette.subtleText)
                }
            }
            .frame(width: 240, height: 240)
            .padding(.vertical, Theme.Spacing.lg)

            if let s = session.soundName {
                Label(s.capitalized, systemImage: "speaker.wave.2.fill")
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.subtleText)
            }

            Button(role: .destructive) {
                stop()
            } label: {
                Text("End session")
                    .font(Theme.Typography.title).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Theme.Palette.ink, in: .capsule)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Setup

    private var setup: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Deep work")
                    .font(Theme.Typography.displayLarge)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Pick a length and a sound, then start. Your Focus widget counts down live.")
                    .font(Theme.Typography.bodyLarge)
                    .foregroundStyle(Theme.Palette.subtleText)
            }

            section("Duration") {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(durations, id: \.self) { minutes in
                        chip("\(minutes)m", selected: duration == minutes) { duration = minutes }
                    }
                }
            }

            section("Sound") {
                ScrollView(.horizontal) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(sounds, id: \.label) { option in
                            chip(option.label, selected: soundName == option.name) { soundName = option.name }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            Button {
                start()
            } label: {
                Text("Start focus")
                    .font(Theme.Typography.title).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Theme.Palette.accent, in: .capsule)
            }
            .buttonStyle(.plain)
            .padding(.top, Theme.Spacing.sm)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title).widgyCapsLabel().foregroundStyle(Theme.Palette.subtleText)
            content()
        }
    }

    private func chip(_ label: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(Theme.Typography.label)
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.vertical, Theme.Spacing.md)
                .background(selected ? Theme.Palette.accent : Theme.Palette.surfaceMuted, in: .capsule)
                .foregroundStyle(selected ? Color.white : Theme.Palette.ink)
        }
        .buttonStyle(.plain)
    }

    // MARK: Actions

    private func start() {
        let new = FocusSession(title: "Deep work", startedAt: .now, durationMinutes: duration, soundName: soundName)
        session = new
        now = .now
        FocusSessionStore.save(new)
        FocusAudioPlayer.shared.play(soundName)
    }

    private func stop() {
        FocusSessionStore.clear()
        FocusAudioPlayer.shared.stop()
        session = nil
    }

    private func finish() {
        FocusSessionStore.clear()
        FocusAudioPlayer.shared.stop()
        session = nil
    }

    private func remainingString(_ session: FocusSession) -> String {
        let total = Int(session.remaining(at: now).rounded())
        return String(format: "%02d:%02d", total / 60, total % 60)
    }
}

#Preview {
    NavigationStack { FocusView() }
}
