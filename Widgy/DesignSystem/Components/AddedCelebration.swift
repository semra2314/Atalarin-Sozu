//
//  AddedCelebration.swift
//  Kare
//
//  The moment something becomes yours: adding a free widget, buying one, or
//  joining Kare+. Four little squares ("kare") dance while it works, then
//  snap together into one, turn into a green tick and burst into confetti
//  squares, with a chime and a tap of haptics.
//

import SwiftUI
import AVFoundation

enum AddPhase: Equatable {
    case adding
    case added
}

/// What is being celebrated. Only the words change; the dance is the same.
enum CelebrationKind: Equatable {
    case add
    case purchase
    case subscribe

    var workingText: LocalizedStringKey {
        switch self {
        case .add: "Adding…"
        case .purchase, .subscribe: "Unlocking…"
        }
    }

    var doneText: LocalizedStringKey {
        switch self {
        case .add: "Added!"
        case .purchase: "It's yours!"
        case .subscribe: "Welcome to Kare+"
        }
    }
}

// MARK: - The dance

/// Four rounded squares circling a centre. They turn a quarter at a time like
/// a clock hand with a spring in it, breathe in and out, and the accent square
/// hops between corners. When `merged` is true they fly into the middle and
/// become one.
struct KareThinkingMark: View {
    var merged: Bool = false
    var size: CGFloat = 64

    /// With Reduce Motion on, the squares stay put and only the accent
    /// moves from corner to corner: still alive, nothing spinning.
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let ink = Theme.Palette.ink
    private let accent = Theme.Palette.accent

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: merged)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            mark(at: t)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func mark(at t: Double) -> some View {
        let beat = 1.05                                   // one quarter turn
        let step = floor(t / beat)
        let progress = (t / beat) - step
        // Overshoot a little, then settle: a quarter turn with a spring.
        let eased = Self.backOut(progress)
        let groupAngle = reduceMotion ? 0 : (step + eased) * 90

        let square = size * 0.30
        let breathe = reduceMotion ? 0.5 : 0.5 + 0.5 * sin(t * 2 * .pi / (beat * 2))
        let radius = merged ? 0 : size * (0.20 + 0.08 * breathe)
        let accentIndex = Int(step) % 4

        return ZStack {
            ForEach(0..<4, id: \.self) { i in
                let angle = Double(i) * 90 + 45
                let wobble = reduceMotion ? 0 : sin(t * 2 + Double(i)) * 0.06
                RoundedRectangle(cornerRadius: square * 0.32, style: .continuous)
                    .fill(i == accentIndex ? accent : ink)
                    .frame(width: square, height: square)
                    .scaleEffect(merged ? 1.6 : 1 + wobble)
                    .rotationEffect(.degrees(merged ? 0 : -groupAngle * 0.5))
                    .offset(x: radius * cos(angle * .pi / 180),
                            y: radius * sin(angle * .pi / 180))
                    .opacity(merged && i != accentIndex ? 0 : 1)
            }
        }
        .rotationEffect(.degrees(merged ? 0 : groupAngle))
        .animation(.spring(duration: 0.35, bounce: 0.4), value: merged)
    }

    /// Ease-out with a small overshoot past the target.
    private static func backOut(_ x: Double) -> Double {
        let c1 = 1.4, c3 = c1 + 1
        return 1 + c3 * pow(x - 1, 3) + c1 * pow(x - 1, 2)
    }
}

// MARK: - Confetti

/// Small squares thrown out from the tick once, then gone.
private struct SquareBurst: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var fired = false
    private let pieces = 14

    var body: some View {
        ZStack {
            ForEach(0..<pieces, id: \.self) { i in
                let angle = Double(i) / Double(pieces) * 2 * .pi + 0.3
                let distance: CGFloat = i.isMultiple(of: 2) ? 78 : 58
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .fill(Self.colors[i % Self.colors.count])
                    .frame(width: i.isMultiple(of: 3) ? 9 : 7, height: i.isMultiple(of: 3) ? 9 : 7)
                    .rotationEffect(.degrees(fired ? Double(i) * 47 + 180 : 0))
                    .offset(x: fired ? distance * cos(angle) : 0,
                            y: fired ? distance * sin(angle) : 0)
                    .scaleEffect(fired ? 0.6 : 1)
                    .opacity(fired ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .opacity(reduceMotion ? 0 : 1)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) { fired = true }
        }
    }

    private static let colors: [Color] = [
        Color(hex: "22C55E"), Theme.Palette.accent, Theme.Palette.ink, Color(hex: "86EFAC")
    ]
}

// MARK: - Overlay

/// Full-screen overlay shown while something is added or unlocked.
struct AddedCelebration: View {
    let phase: AddPhase
    var kind: CelebrationKind = .add

    @State private var merging = false
    private let green = Color(hex: "22C55E")

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.md) {
                ZStack {
                    if phase == .adding {
                        KareThinkingMark(merged: merging)
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    } else {
                        SquareBurst()
                        Circle()
                            .fill(green)
                            .frame(width: 84, height: 84)
                            .shadow(color: green.opacity(0.45), radius: 18, y: 6)
                            .overlay {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundStyle(.white)
                                    .symbolEffect(.bounce, value: phase)
                            }
                            .transition(.scale(scale: 0.3).combined(with: .opacity))
                    }
                }
                .frame(width: 96, height: 96)

                Group {
                    if phase == .adding {
                        Text(kind.workingText)
                    } else {
                        Text(kind.doneText)
                    }
                }
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Palette.ink)
                .multilineTextAlignment(.center)
                .contentTransition(.opacity)
            }
            .padding(Theme.Spacing.xl)
            .frame(width: 210, height: 210)
            .background(Theme.Palette.surface, in: .rect(cornerRadius: Theme.Radius.hero, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 30, y: 12)
        }
        .animation(.spring(duration: 0.45, bounce: 0.45), value: phase)
        .sensoryFeedback(.success, trigger: phase) { _, new in new == .added }
        .sensoryFeedback(.impact(weight: .light), trigger: merging) { _, new in new }
        .accessibilityElement(children: .combine)
        .task(id: phase) {
            // Just before the tick: the squares snap together.
            guard phase == .adding else { return }
            merging = false
            try? await Task.sleep(for: .milliseconds(CelebrationTiming.working - 350))
            merging = true
        }
    }
}

enum CelebrationTiming {
    /// How long the squares dance. Long enough to be seen, short enough that
    /// nobody waits on it; a purchase waits on the App Store anyway.
    static let working = 1_900
    static let done = 1_300
}

/// The chime. Uses the ambient category, so it respects the silent switch
/// and plays over music instead of stopping it.
@MainActor
enum AddedSound {
    private static var player: AVAudioPlayer?

    static func play() {
        guard let url = Bundle.main.url(forResource: "kare-added", withExtension: "wav") else { return }
        let session = AVAudioSession.sharedInstance()
        // Leave a running Focus sound alone: it owns the session while it plays.
        if session.category != .playback {
            try? session.setCategory(.ambient, options: [.mixWithOthers])
        }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.volume = 0.6
        player?.play()
    }
}

extension View {
    /// Shows the celebration overlay while `phase` is set.
    func addedCelebration(_ phase: Binding<AddPhase?>, kind: CelebrationKind = .add) -> some View {
        overlay {
            if let current = phase.wrappedValue {
                AddedCelebration(phase: current, kind: kind)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: phase.wrappedValue)
    }
}

/// Runs the whole moment: dance, tick, chime, then `completion`.
///
/// Pass `work` for something that takes real time, like a purchase: the
/// squares keep dancing until it finishes. If it returns false (cancelled,
/// failed) the overlay just goes away and `completion` is not called.
@MainActor
func runAddCelebration(_ phase: Binding<AddPhase?>,
                       work: (@MainActor () async -> Bool)? = nil,
                       then completion: @escaping () -> Void) {
    phase.wrappedValue = .adding
    Task { @MainActor in
        let started = ContinuousClock.now
        if let work {
            guard await work() else {
                phase.wrappedValue = nil
                return
            }
        }
        // Always let the dance finish its bar, even when the work was instant.
        let elapsed = ContinuousClock.now - started
        let minimum = Duration.milliseconds(CelebrationTiming.working)
        if elapsed < minimum { try? await Task.sleep(for: minimum - elapsed) }

        phase.wrappedValue = .added
        AddedSound.play()
        try? await Task.sleep(for: .milliseconds(CelebrationTiming.done))
        phase.wrappedValue = nil
        try? await Task.sleep(for: .milliseconds(200))
        completion()
    }
}

#Preview("Dance") {
    VStack(spacing: 40) {
        KareThinkingMark()
        KareThinkingMark(size: 32)
    }
    .padding(60)
}

#Preview("Overlay") {
    AddedCelebration(phase: .adding, kind: .subscribe)
}
