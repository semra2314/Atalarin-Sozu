//
//  CatalogSection.swift
//  Kare
//

import Foundation

/// A merchandised row on the Discover screen. The backend decides the
/// curation; the client just renders whatever sections it receives.
nonisolated struct CatalogSection: Identifiable, Hashable, Sendable {
    enum Style: Hashable, Sendable {
        case spotlight
        case carousel
        case compactList
    }

    let id: String
    var title: String
    var subtitle: String?
    var style: Style
    var templates: [WidgetTemplate]
}
