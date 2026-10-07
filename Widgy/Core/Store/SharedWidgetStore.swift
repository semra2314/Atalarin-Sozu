//
//  SharedWidgetStore.swift
//  Kare  (shared with the WidgetKit extension)
//
//  Bridges the editor and the home-screen widget. The app writes each saved
//  design into the App Group container; the widget extension reads them back.
//
//  Storage is **per design**, keyed by the widget's id. It used to be a single
//  `current-widget.json`, which meant every custom widget placed on the home
//  screen showed whichever design was saved last — place two, get the same one
//  twice. Each design now gets its own file, and a placed widget remembers
//  which id it's showing (see `KareSelection` / the widget's AppIntent config).
//
//  IMPORTANT: add this file's target membership to BOTH the app and the widget
//  extension, and set `appGroupID` to the App Group you create in Signing &
//  Capabilities (the same id on both targets).
//
//  Until the App Group capability exists, `containerURL` is nil and every call
//  here is a safe no-op, so the app keeps working.
//

import Foundation
import WidgetKit

/// `nonisolated` because it's pure file I/O with no shared mutable state, and
/// the other App Group stores (Focus, Frame, Daily) are themselves nonisolated
/// and read `appGroupID` from here.
nonisolated enum SharedWidgetStore {
    /// Must match the App Group id enabled on both targets.
    static let appGroupID = "group.com.zeddy.Widgy"
    /// Must match the `kind` used by the Widget in the extension.
    static let widgetKind = "WidgyWidget"

    /// Legacy single-slot file, still read once so designs saved by an older
    /// build survive the upgrade instead of vanishing from the home screen.
    private static let legacyFileName = "current-widget.json"
    private static let directoryName = "designs"
    private static let indexFileName = "designs-index.json"

    struct Payload: Codable, Sendable, Identifiable, Hashable {
        /// The `InstalledWidget.templateID` this design belongs to.
        var id: String
        var content: WidgetContent
        var familyRaw: String
        var name: String
        var updatedAt: Date

        var family: WidgetSize { WidgetSize(rawValue: familyRaw) ?? .small }

        init(id: String, content: WidgetContent, familyRaw: String, name: String, updatedAt: Date = .now) {
            self.id = id
            self.content = content
            self.familyRaw = familyRaw
            self.name = name
            self.updatedAt = updatedAt
        }

        // Older payloads had no id/updatedAt.
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decodeIfPresent(String.self, forKey: .id) ?? "legacy"
            content = try c.decode(WidgetContent.self, forKey: .content)
            familyRaw = try c.decode(String.self, forKey: .familyRaw)
            name = try c.decode(String.self, forKey: .name)
            updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .distantPast
        }
    }

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    private static var directoryURL: URL? {
        guard let container = containerURL else { return nil }
        let url = container.appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    private static func fileURL(for id: String) -> URL? {
        // Ids come from our own catalog, but sanitise anyway — an id with a
        // slash in it would silently write outside the directory.
        let safe = id.replacingOccurrences(of: "/", with: "_")
        return directoryURL?.appendingPathComponent("\(safe).json")
    }

    // MARK: - Writing

    /// Persist one design and refresh every placed instance of the widget.
    static func save(id: String, content: WidgetContent, family: WidgetSize, name: String) {
        guard let url = fileURL(for: id) else { return }
        let payload = Payload(id: id, content: content, familyRaw: family.rawValue, name: name)
        guard let data = try? JSONEncoder().encode(payload) else { return }
        try? data.write(to: url, options: .atomic)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    static func remove(id: String) {
        guard let url = fileURL(for: id) else { return }
        try? FileManager.default.removeItem(at: url)
        WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
    }

    // MARK: - Reading

    /// One design by id. Falls back to the most recent one when the requested
    /// design is gone — a widget whose design was deleted should show
    /// *something* rather than an error state.
    static func load(id: String?) -> Payload? {
        if let id, let url = fileURL(for: id), let data = try? Data(contentsOf: url),
           let payload = try? JSONDecoder().decode(Payload.self, from: data) {
            return payload
        }
        return mostRecent()
    }

    /// Every saved design, newest first. Used to populate the widget's
    /// configuration picker.
    static func all() -> [Payload] {
        migrateLegacyIfNeeded()
        guard let directory = directoryURL,
              let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        else { return [] }

        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { try? Data(contentsOf: $0) }
            .compactMap { try? JSONDecoder().decode(Payload.self, from: $0) }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    static func mostRecent() -> Payload? { all().first }

    // MARK: - Migration

    /// Moves a design saved by the old single-slot build into the new
    /// per-design storage, once.
    private static func migrateLegacyIfNeeded() {
        guard let container = containerURL else { return }
        let legacy = container.appendingPathComponent(legacyFileName)
        guard FileManager.default.fileExists(atPath: legacy.path),
              let data = try? Data(contentsOf: legacy),
              let payload = try? JSONDecoder().decode(Payload.self, from: data),
              let destination = fileURL(for: payload.id == "legacy" ? "t-custom" : payload.id)
        else { return }

        var migrated = payload
        if migrated.id == "legacy" { migrated.id = "t-custom" }
        migrated.updatedAt = .now
        if let encoded = try? JSONEncoder().encode(migrated) {
            try? encoded.write(to: destination, options: .atomic)
        }
        try? FileManager.default.removeItem(at: legacy)
    }
}
