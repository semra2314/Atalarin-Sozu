//
//  KareWidget.swift
//  KareWidget  (Widget Extension target)
//
//  Renders the user's saved widget on the home screen by reading the payload
//  the app wrote into the App Group, and drawing it with the SHARED
//  `CustomWidgetView` (same colours + fonts as the editor).
//
//  This file belongs to the Widget Extension target only. See
//  WIDGET_EXTENSION_SETUP.md for the exact Xcode steps.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline

struct KareEntry: TimelineEntry {
    let date: Date
    let payload: SharedWidgetStore.Payload?
}

/// Reads whichever design this particular placed widget was configured with.
/// Each instance carries its own `SelectDesignIntent`, which is what lets two
/// custom widgets on the same home screen show two different designs.
struct KareProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> KareEntry {
        KareEntry(date: .now, payload: SharedWidgetStore.mostRecent())
    }

    func snapshot(for configuration: SelectDesignIntent, in context: Context) async -> KareEntry {
        KareEntry(date: .now, payload: SharedWidgetStore.load(id: configuration.design?.id))
    }

    func timeline(for configuration: SelectDesignIntent, in context: Context) async -> Timeline<KareEntry> {
        let entry = KareEntry(date: .now, payload: SharedWidgetStore.load(id: configuration.design?.id))
        // Content only changes when the user edits, and save() reloads us then.
        return Timeline(entries: [entry], policy: .never)
    }
}

// MARK: - View

struct KareWidgetEntryView: View {
    var entry: KareProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let payload = entry.payload {
                CustomWidgetView(
                    content: payload.content,
                    size: mappedSize,
                    cornerRadius: 0,           // the widget container already clips
                    // `fills` exists precisely for this call and was never
                    // passed. Without it the renderer forces its own aspect
                    // ratio inside the widget container, so the canvas is a
                    // few points narrower than the space iOS gave us, gets
                    // centred with gutters, and draws a hairline border meant
                    // for in-app previews. Every normalised position is then
                    // measured against the wrong width.
                    fills: true
                )
            } else {
                emptyState
            }
        }
        .containerBackground(for: .widget) { Color(hex: "1D1D1F") }
    }

    private var mappedSize: WidgetSize {
        switch family {
        case .systemMedium: .medium
        case .systemLarge:  .large
        default:            .small
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.grid.2x2")
            Text("Open Kare to design this")
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding()
    }
}

// MARK: - Widget

struct KareWidget: Widget {
    var body: some WidgetConfiguration {
        // AppIntentConfiguration (not Static) so each placed widget stores its
        // own choice of design — long-press > Edit Widget > Design.
        AppIntentConfiguration(
            kind: SharedWidgetStore.widgetKind,
            intent: SelectDesignIntent.self,
            provider: KareProvider()
        ) { entry in
            KareWidgetEntryView(entry: entry)
                // Kare's own language setting, not only the phone's.
                .environment(\.locale, WidgetLanguage.locale)
        }
        .configurationDisplayName("Kare")
        .description("Your custom widget, designed in the app.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        // Let our own design paint edge to edge.
        .contentMarginsDisabled()
    }
}

@main
struct KareWidgetBundle: WidgetBundle {
    init() {
        // Register Fraunces inside the extension too (fonts must be added to
        // the extension target). Safe no-op if none are bundled.
        FontRegistrar.registerBundledFonts()
    }

    var body: some Widget {
        KareWidget()
        AuroraWidget()
        FocusWidget()
        FrameWidget()
        HushWidget()
        DailyWidget()
        ProverbWidget()
        // Kare+
        ExhaleWidget()
        CountdownWidget()
        ProgressWidget()
    }
}
