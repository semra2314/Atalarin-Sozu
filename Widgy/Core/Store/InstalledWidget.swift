//
//  InstalledWidget.swift
//  Kare
//

import Foundation
import SwiftData

/// A template the user has added to their library, persisted locally with SwiftData.
/// The catalog itself stays remote; only the user's own choices live on device.
@Model
final class InstalledWidget {
    @Attribute(.unique) var templateID: String
    var name: String
    /// Cached at install time. Read `authorName` below instead, which prefers
    /// the live catalogue. Renaming a creator used to leave every already
    /// installed widget showing the old name forever, with no way out short of
    /// removing and re-adding it, because this column is written once and
    /// never touched again.
    /// Was the `authorName` column before it became a cache; `originalName`
    /// lets an existing store migrate in place instead of failing to open.
    @Attribute(originalName: "authorName") private var authorNameStored: String = ""
    var categoryRaw: String
    var sizeRaw: String
    var themeData: Data?
    /// The user's editor payload (text/stickers/photo/style), JSON-encoded.
    /// Nil until the widget has been customised in the editor.
    var contentData: Data?
    var addedAt: Date
    var isFavorite: Bool
    var sortIndex: Int
    /// Cached copy of the flag/image from install time. Prefer the computed
    /// `isCustomizable` / `previewImageName` below, which re-check the live
    /// catalog — these raw fields only serve as a fallback for a template
    /// that's since been removed from the catalog entirely. Kept private so
    /// nothing outside this file can accidentally read the stale value.
    private var isCustomizableStored: Bool = true
    private var previewImageNameStored: String?

    init(
        templateID: String,
        name: String,
        authorName: String,
        categoryRaw: String,
        sizeRaw: String,
        themeData: Data? = nil,
        contentData: Data? = nil,
        addedAt: Date = .now,
        isFavorite: Bool = false,
        sortIndex: Int = 0,
        isCustomizable: Bool = true,
        previewImageName: String? = nil
    ) {
        self.templateID = templateID
        self.name = name
        self.authorNameStored = authorName
        self.categoryRaw = categoryRaw
        self.sizeRaw = sizeRaw
        self.themeData = themeData
        self.contentData = contentData
        self.addedAt = addedAt
        self.isFavorite = isFavorite
        self.sortIndex = sortIndex
        self.isCustomizableStored = isCustomizable
        self.previewImageNameStored = previewImageName
    }
}

extension InstalledWidget {
    var category: WidgetCategory { WidgetCategory(rawValue: categoryRaw) ?? .minimal }
    var size: WidgetSize { WidgetSize(rawValue: sizeRaw) ?? .small }

    /// The current catalog definition for this installed widget, if it's
    /// still there. Looking this up live (instead of trusting only what was
    /// cached at install time) means widgets added before a catalog change
    /// — like Aurora becoming a locked, fixed-design widget — self-heal the
    /// next time they're read, with no need to remove and re-add them.
    private var catalogTemplate: WidgetTemplate? {
        SampleCatalog.templates.first { $0.id == templateID }
    }

    /// Who made this, read live rather than from the copy taken at install.
    ///
    /// The same self-healing trick as `isCustomizable`: someone who installed
    /// a widget back when the catalogue credited invented studios sees the
    /// real creator the next time the row is drawn, with no migration and
    /// nothing to remove and re-add. The stored value is only a fallback for a
    /// template that has since left the catalogue entirely.
    var authorName: String {
        catalogTemplate?.author.displayName ?? authorNameStored
    }

    /// False for fixed-design widgets (Aurora, Focus, ...) that ship with a
    /// finished look and must never open the "make your own" editor.
    var isCustomizable: Bool {
        if let catalogTemplate { return catalogTemplate.isEditable }
        return isCustomizableStored
    }

    /// Store/marketing image for fixed-design widgets (e.g. "aurora_widget").
    /// Nil for customizable widgets, which render from `content` instead.
    ///
    /// Customizable widgets (presets, Custom) have market art too now, but in
    /// the user's library they show their own edited design, never the ad.
    var previewImageName: String? {
        guard !isCustomizable else { return nil }
        return catalogTemplate?.previewImageName ?? previewImageNameStored
    }

    var theme: WidgetTheme? {
        guard let themeData else { return nil }
        return try? JSONDecoder().decode(WidgetTheme.self, from: themeData)
    }

    /// The saved editor payload, if the user has customised this widget.
    var content: WidgetContent? {
        guard let contentData else { return nil }
        return try? JSONDecoder().decode(WidgetContent.self, from: contentData)
    }

    /// A sensible starting point for the editor when nothing is saved yet:
    /// seed the text from the name and the background from the template theme.
    func seededContent() -> WidgetContent {
        WidgetContent(
            text: name,
            fontStyle: .serif,
            fontSize: 22,
            textColorHex: theme?.foregroundHex ?? "FFFFFF",
            alignment: .leading,
            background: .color(theme?.backgroundHexes ?? ["1D1D1F", "3A3A3C"]),
            stickers: []
        )
    }

    /// Where tapping this widget in the user's library should navigate: Focus
    /// opens its live session screen, other fixed-design widgets (Aurora, ...)
    /// open the "put it on your home screen" setup screen, and only a genuinely
    /// customizable widget opens the editor. Single source of truth — every
    /// entry point (Library, Profile, ...) routes through this rather than
    /// deciding on its own.
    var libraryDestination: AppRoute {
        switch templateID {
        case "t-focus": return .focus
        case "t-frame": return .frame
        case "t-daily": return .daily
        case "t-exhale": return .exhale
        case "t-countdown": return .countdown
        case "t-progress": return .progress
        default:
            return isCustomizable ? .editor(templateID: templateID) : .setUpOnHome(templateID: templateID)
        }
    }

    convenience init(template: WidgetTemplate, size: WidgetSize, sortIndex: Int = 0) {
        self.init(
            templateID: template.id,
            name: template.name,
            authorName: template.author.displayName,
            categoryRaw: template.category.rawValue,
            sizeRaw: size.rawValue,
            themeData: try? JSONEncoder().encode(template.theme),
            contentData: template.content.flatMap { try? JSONEncoder().encode($0) },
            sortIndex: sortIndex,
            isCustomizable: template.isEditable,
            previewImageName: template.previewImageName
        )
    }
}
