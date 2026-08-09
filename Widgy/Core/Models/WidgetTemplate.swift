//
//  WidgetTemplate.swift
//  Widgy
//

import Foundation

/// A single item in the marketplace catalog.
nonisolated struct WidgetTemplate: Identifiable, Hashable, Codable, Sendable {
    let id: String
    var name: String
    var summary: String
    var author: Author
    var category: WidgetCategory
    var supportedSizes: [WidgetSize]
    var theme: WidgetTheme
    /// The ready-made, editable design shipped with this template.
    var content: WidgetContent? = nil
    /// Marketing/store image asset name shown in the catalog (e.g. "aurora_widget").
    var previewImageName: String? = nil
    /// Base name for per-size product images on the detail page, e.g. "aurora"
    /// resolves to "aurora_small" / "aurora_medium" / "aurora_large".
    var sizePreviewBaseName: String? = nil
    /// The exact name this widget appears under in the iOS widget gallery
    /// (its WidgetKit `configurationDisplayName`), so the in-app setup screen
    /// can tell the user precisely what to look for. Nil if it has no live
    /// WidgetKit widget of its own.
    var galleryName: String? = nil
    var tags: [String]
    var installCount: Int
    var rating: Double
    var ratingCount: Int
    var price: Price
    var publishedAt: Date
    /// True only for the build-your-own template. Every other widget ships a
    /// fixed design of ours and must never open the editor. This is an explicit
    /// flag rather than being inferred from whether a store image exists —
    /// that inference quietly broke as soon as a fixed widget (Daily) shipped
    /// without marketing art.
    var isEditable: Bool = false

    enum Price: Hashable, Codable, Sendable {
        case free
        case paid(amount: Decimal, currencyCode: String)

        var isFree: Bool {
            if case .free = self { return true }
            return false
        }

        var displayText: String {
            switch self {
            case .free:
                return "Free"
            case let .paid(amount, currencyCode):
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                formatter.currencyCode = currencyCode
                return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
            }
        }
    }

    var primarySize: WidgetSize { supportedSizes.first ?? .small }

    var installCountText: String {
        let count = Double(installCount)
        switch count {
        case 1_000_000...:
            return String(format: "%.1fM", count / 1_000_000)
        case 1_000...:
            return String(format: "%.1fK", count / 1_000)
        default:
            return "\(installCount)"
        }
    }
}
