//
//  AppNavigator.swift
//  Kare
//
//  Shared cross-tab navigation state. Lets a screen inside one tab (e.g. the
//  detail's "Add to library") switch the whole app to another tab.
//

import SwiftUI
import Observation

@MainActor
@Observable
final class AppNavigator {
    var selectedTab: AppTab = .discover

    /// A screen to open inside the Library tab. Set by `openInLibrary`,
    /// consumed by `RootView`, which pushes it and clears this.
    var pendingLibraryRoute: AppRoute?

    /// Switch to the Library and open one widget there straight away,
    /// instead of leaving the user to find it in the list.
    func openInLibrary(_ route: AppRoute) {
        pendingLibraryRoute = route
        selectedTab = .library
    }
}
