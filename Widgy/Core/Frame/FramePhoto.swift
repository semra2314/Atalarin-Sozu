//
//  FramePhoto.swift
//  Widgy  (shared: app + widget extension)
//
//  The photo behind the Frame widget. The app writes the picked image (already
//  downscaled) into the App Group; the widget reads it. Image data lives in a
//  separate file from the caption so the widget only pays for what it draws.
//

import Foundation
import WidgetKit

nonisolated struct FramePhoto: Codable, Hashable, Sendable {
    var caption: String
    var updatedAt: Date

    init(caption: String = "", updatedAt: Date = .now) {
        self.caption = caption
        self.updatedAt = updatedAt
    }
}

/// Reads/writes the Frame widget's photo + caption in the App Group container.
nonisolated enum FramePhotoStore {
    static let widgetKind = "FrameWidget"

    private static let metaFile = "frame-photo.json"
    private static let imageFile = "frame-photo.jpg"

    /// Widget extensions run on a tight memory budget, so the app downscales
    /// before writing. This is the longest edge we store.
    static let maxPixelSize: CGFloat = 1200

    private static func url(_ name: String) -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: SharedWidgetStore.appGroupID)?
            .appendingPathComponent(name)
    }

    static func save(imageData: Data, caption: String) {
        guard let imageURL = url(imageFile), let metaURL = url(metaFile) else { return }
        try? imageData.write(to: imageURL, options: .atomic)
        if let meta = try? JSONEncoder().encode(FramePhoto(caption: caption)) {
            try? meta.write(to: metaURL, options: .atomic)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    /// Updates just the caption, leaving the stored image alone.
    static func save(caption: String) {
        guard let metaURL = url(metaFile),
              let meta = try? JSONEncoder().encode(FramePhoto(caption: caption)) else { return }
        try? meta.write(to: metaURL, options: .atomic)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func loadImageData() -> Data? {
        guard let imageURL = url(imageFile) else { return nil }
        return try? Data(contentsOf: imageURL)
    }

    static func loadMeta() -> FramePhoto? {
        guard let metaURL = url(metaFile), let data = try? Data(contentsOf: metaURL) else { return nil }
        return try? JSONDecoder().decode(FramePhoto.self, from: data)
    }

    static func clear() {
        [imageFile, metaFile].compactMap(url).forEach { try? FileManager.default.removeItem(at: $0) }
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }
}
