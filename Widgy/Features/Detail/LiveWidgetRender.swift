//
//  LiveWidgetRender.swift
//  Kare
//
//  The real widget, drawn inside the app at the size picked on the detail
//  page. It is the same SwiftUI view the home screen runs (see
//  Core/WidgetViews), fed sample data or the user's own where there is some,
//  so Small, Medium, Large and the lock-screen shapes each show what will
//  actually land on the phone rather than one marketing picture for all.
//

import SwiftUI
import WidgetKit

struct LiveWidgetRender: View {
    let templateID: String
    let size: WidgetSize

    static let supportedIDs: Set<String> = [
        "t-aurora", "t-focus", "t-frame", "t-hush", "t-daily", "t-proverb",
        "t-exhale", "t-countdown", "t-progress"
    ]

    private var family: WidgetFamily {
        switch size {
        case .small: .systemSmall
        case .medium: .systemMedium
        case .large: .systemLarge
        case .accessoryCircular: .accessoryCircular
        case .accessoryRectangular: .accessoryRectangular
        }
    }

    /// Widget sizes on a 6.1" iPhone, in points. The views lay themselves out
    /// against these exactly as they do on the home screen.
    private var canvas: CGSize {
        switch size {
        case .small: CGSize(width: 158, height: 158)
        case .medium: CGSize(width: 338, height: 158)
        case .large: CGSize(width: 338, height: 354)
        case .accessoryCircular: CGSize(width: 72, height: 72)
        case .accessoryRectangular: CGSize(width: 160, height: 72)
        }
    }

    var body: some View {
        let drawn = widget
            .frame(width: canvas.width, height: canvas.height)
            .environment(\.kareInAppPreview, true)
            // A preview, not a remote control: tapping it must not start a
            // focus session or reset someone's quit date.
            .allowsHitTesting(false)

        if size.isLockScreen {
            // Lock-screen widgets are drawn by iOS in white on the wallpaper.
            drawn
                .foregroundStyle(.white)
                .environment(\.colorScheme, .dark)
                .padding(.horizontal, 28)
                .padding(.vertical, 22)
                .background(
                    LinearGradient(colors: [Color(hex: "1B2735"), Color(hex: "3A4A5E")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: .rect(cornerRadius: 26, style: .continuous)
                )
        } else {
            drawn
                .clipShape(.rect(cornerRadius: 22, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
        }
    }

    @ViewBuilder private var widget: some View {
        switch templateID {
        case "t-aurora":
            AuroraWidgetEntryView(entry: AuroraEntry(date: .now), familyOverride: family)
        case "t-focus":
            FocusWidgetEntryView(entry: Self.focusSample, familyOverride: family)
        case "t-frame":
            FrameWidgetEntryView(entry: Self.frameSample, familyOverride: family)
        case "t-hush":
            HushWidgetEntryView(entry: HushEntry(date: .now, word: "breathe"), familyOverride: family)
        case "t-daily":
            DailyWidgetEntryView(entry: Self.dailySample, familyOverride: family)
        case "t-proverb":
            ProverbWidgetEntryView(entry: ProverbEntry(date: .now, proverb: ProverbLibrary.entry(for: .now)),
                                   familyOverride: family)
        case "t-exhale":
            ExhaleWidgetEntryView(entry: Self.exhaleSample, familyOverride: family)
        case "t-countdown":
            CountdownWidgetEntryView(entry: Self.countdownSample, familyOverride: family)
        case "t-progress":
            ProgressWidgetEntryView(entry: ProgressEntry(date: .now, kind: .year, unlocked: true),
                                    familyOverride: family)
        default:
            EmptyView()
        }
    }

    // MARK: - Sample data

    /// A session a third of the way through, so the preview shows the timer
    /// running rather than an idle Start button.
    private static var focusSample: FocusEntry {
        FocusEntry(date: .now,
                   session: FocusSession(title: "Deep work",
                                         startedAt: .now.addingTimeInterval(-15 * 60),
                                         durationMinutes: 45))
    }

    /// The user's own photo if they have set one; otherwise the widget's
    /// empty state, which is what they would see after adding it.
    private static var frameSample: FrameEntry {
        let image = FramePhotoStore.loadImageData().flatMap(UIImage.init(data:))
        return FrameEntry(date: .now, image: image, meta: FramePhotoStore.loadMeta() ?? FramePhoto())
    }

    private static var dailySample: DailyEntry {
        let source = DailyStore.loadSource()
        return DailyEntry(date: .now, passage: DailyStore.passage(for: .now, source: source), source: source)
    }

    /// Nine days in: past the first milestones, lungs visibly filling.
    private static var exhaleSample: ExhaleEntry {
        ExhaleEntry(date: .now,
                    plan: QuitStore.load() ?? QuitPlan.starting(now: .now.addingTimeInterval(-9 * 86_400)),
                    unlocked: true)
    }

    private static var countdownSample: CountdownEntry {
        let sample = CountdownEvent(title: String(localized: "Summer trip"), emoji: "✈️",
                                    date: .now.addingTimeInterval(23 * 86_400),
                                    createdAt: .now.addingTimeInterval(-19 * 86_400),
                                    theme: .trip)
        return CountdownEntry(date: .now,
                              event: CountdownStore.nextUpcoming(in: CountdownStore.all()) ?? sample,
                              unlocked: true)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 24) {
            LiveWidgetRender(templateID: "t-exhale", size: .small)
            LiveWidgetRender(templateID: "t-exhale", size: .medium)
            LiveWidgetRender(templateID: "t-countdown", size: .large)
            LiveWidgetRender(templateID: "t-progress", size: .accessoryRectangular)
        }
        .padding()
    }
}
