//
//  FrameWidget.swift
//  KareWidget  (widget extension target)
//
//  The user's own photo on the home screen, with an optional caption. Falls
//  back to an inviting empty state so a freshly-placed widget still looks
//  designed rather than broken.
//

import WidgetKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif


struct FrameProvider: TimelineProvider {

    private func currentEntry() -> FrameEntry {
        let image = FramePhotoStore.loadImageData().flatMap(UIImage.init(data:))
        return FrameEntry(date: .now, image: image, meta: FramePhotoStore.loadMeta() ?? FramePhoto())
    }

    func placeholder(in context: Context) -> FrameEntry {
        FrameEntry(date: .now, image: nil, meta: FramePhoto())
    }

    func getSnapshot(in context: Context, completion: @escaping (FrameEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FrameEntry>) -> Void) {
        // Content only changes when the user picks a new photo, and the store
        // reloads us then — so a single entry with no refresh policy is right.
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }
}

struct FrameWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: FramePhotoStore.widgetKind, provider: FrameProvider()) { entry in
            FrameWidgetEntryView(entry: entry)
                .libraryGated("t-frame")
                // Kare's own language setting, not only the phone's.
                .environment(\.locale, WidgetLanguage.locale)
        }
        .configurationDisplayName("Frame")
        .description("Your own photo, framed on the home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
