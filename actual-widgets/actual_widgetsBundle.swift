//
//  WidgyWidget.swift
//  WidgyWidget  (Widget Extension target)
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

struct WidgyEntry: TimelineEntry {
    let date: Date
    let payload: SharedWidgetStore.Payload?
}

/// Reads whichever design this particular placed widget was configured with.
/// Each instance carries its own `SelectDesignIntent`, which is what lets two
/// custom widgets on the same home screen show two different designs.
struct WidgyProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> WidgyEntry {
        WidgyEntry(date: .now, payload: SharedWidgetStore.mostRecent())
    }

    func snapshot(for configuration: SelectDesignIntent, in context: Context) async -> WidgyEntry {
        WidgyEntry(date: .now, payload: SharedWidgetStore.load(id: configuration.design?.id))
    }

    func timeline(for configuration: SelectDesignIntent, in context: Context) async -> Timeline<WidgyEntry> {
        let entry = WidgyEntry(date: .now, payload: SharedWidgetStore.load(id: configuration.design?.id))
        // Content only changes when the user edits, and save() reloads us then.
        return Timeline(entries: [entry], policy: .never)
    }
}

// MARK: - View

struct WidgyWidgetEntryView: View {
    var entry: WidgyProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let payload = entry.payload {
                CustomWidgetView(
                    content: payload.content,
                    size: mappedSize,
                    referenceWidth: 329,
                    cornerRadius: 0            // the widget container already clips
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
            Text("Open Widgy to design this")
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding()
    }
}

// MARK: - Widget

struct WidgyWidget: Widget {
    var body: some WidgetConfiguration {
        // AppIntentConfiguration (not Static) so each placed widget stores its
        // own choice of design — long-press > Edit Widget > Design.
        AppIntentConfiguration(
            kind: SharedWidgetStore.widgetKind,
            intent: SelectDesignIntent.self,
            provider: WidgyProvider()
        ) { entry in
            WidgyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Widgy")
        .description("Your custom widget, designed in the app.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        // Let our own design paint edge to edge.
        .contentMarginsDisabled()
    }
}

@main
struct WidgyWidgetBundle: WidgetBundle {
    init() {
        // Register Fraunces inside the extension too (fonts must be added to
        // the extension target). Safe no-op if none are bundled.
        FontRegistrar.registerBundledFonts()
    }

    var body: some Widget {
        WidgyWidget()
        AuroraWidget()
        FocusWidget()
        FrameWidget()
        HushWidget()
        DailyWidget()
    }
}
