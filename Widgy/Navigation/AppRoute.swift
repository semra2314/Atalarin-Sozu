//
//  AppRoute.swift
//  Widgy
//

import Foundation

/// Every push destination in the app. Keeping them in one enum means a
/// deep link only has to build a value, not know about any view.
enum AppRoute: Hashable {
    case templateDetail(templateID: String)
    case category(WidgetCategory)
    case author(authorID: String)
    case editor(templateID: String)
    /// "Put this on your home screen" screen for a fixed-design widget
    /// (Aurora, ...): shows its sizes and how to place it from the gallery.
    case setUpOnHome(templateID: String)
    case focus
    /// Photo picker that feeds the Frame widget.
    case frame
    /// Source picker that feeds the Daily widget.
    case daily
}

enum AppTab: String, Hashable, CaseIterable {
    case discover
    case library
    case profile
    case search
    case settings

    var title: String {
        switch self {
        case .discover: "Discover"
        case .library: "Widgets"
        case .profile: "Profile"
        case .search: "Search"
        case .settings: "Settings"
        }
    }

    var symbolName: String {
        switch self {
        case .discover: "square.grid.2x2.fill"
        case .library: "rectangle.stack.fill"
        case .profile: "person.crop.circle.fill"
        case .search: "magnifyingglass"
        case .settings: "gearshape.fill"
        }
    }
}
