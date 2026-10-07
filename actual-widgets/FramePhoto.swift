//
//  FramePhoto.swift
//  Kare  (shared: app + widget extension)
//
//  The photo behind the Frame widget. The app writes the picked image (already
//  downscaled) into the App Group; the widget reads it. Image data lives in a
//  separate file from the caption so the widget only pays for what it draws.
//
//  NOTE: this file is duplicated in actual-widgets/ for the extension target.
//  Change one, change both.
//

import Foundation
import SwiftUI
import WidgetKit

nonisolated struct FramePhoto: Codable, Hashable, Sendable {
    var caption: String
    /// The smaller line under the caption.
    ///
    /// Used to be hard-coded as "Your moment, your frame." in the widget, which
    /// made it the one piece of text on a personal photo that the person could
    /// not make their own.
    ///
    /// Empty means "use the stock line". Storing the English words as the
    /// default would have written our copy into the user's own data, and a
    /// Turkish user who never touched the field would have been stuck with
    /// English forever, because a stored string is data and data is not
    /// translated. Empty keeps the fallback a `Text` literal, which is.
    var subtitle: String
    /// Card colour behind the photo. The old brown is still the default, so
    /// anyone who never opens the picker sees exactly what they saw before.
    var backgroundHex: String
    var updatedAt: Date

    static let defaultBackgroundHex = "3A2C26"

    /// Colours that all carry either cream or ink type well. A free colour
    /// wheel would let someone pick a yellow that makes their own caption
    /// unreadable; this stays out of that trap while still feeling like a
    /// choice.
    static let backgroundPalette: [String] = [
        "3A2C26",   // warm brown, the original
        "1D1D1F",   // near black
        "24303A",   // deep blue
        "2A3A2E",   // forest
        "4A2A3A",   // plum
        "C05A3E",   // terracotta
        "E8DCCB",   // cream
        "D8D3CC"    // stone
    ]

    init(
        caption: String = "",
        subtitle: String = "",
        backgroundHex: String = FramePhoto.defaultBackgroundHex,
        updatedAt: Date = .now
    ) {
        self.caption = caption
        self.subtitle = subtitle
        self.backgroundHex = backgroundHex
        self.updatedAt = updatedAt
    }

    /// Decoded field by field so a payload written before the subtitle and the
    /// colour existed still loads, instead of throwing and leaving the widget
    /// showing its empty state.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        caption = try c.decodeIfPresent(String.self, forKey: .caption) ?? ""
        subtitle = try c.decodeIfPresent(String.self, forKey: .subtitle) ?? ""
        backgroundHex = try c.decodeIfPresent(String.self, forKey: .backgroundHex) ?? FramePhoto.defaultBackgroundHex
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
    }

    /// Cream on a dark card, near-black on a pale one. Computed rather than
    /// stored so the palette can grow without anyone remembering to pick a
    /// matching text colour.
    var ink: Color {
        Color.isLight(hex: backgroundHex) ? Color(hex: "2A211C") : Color(hex: "F0E3D5")
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

    static func save(imageData: Data, meta: FramePhoto) {
        guard let imageURL = url(imageFile) else { return }
        try? imageData.write(to: imageURL, options: .atomic)
        save(meta: meta)
    }

    /// Updates the text and colour, leaving the stored image alone.
    static func save(meta: FramePhoto) {
        guard let metaURL = url(metaFile),
              let data = try? JSONEncoder().encode(meta) else { return }
        try? data.write(to: metaURL, options: .atomic)
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
