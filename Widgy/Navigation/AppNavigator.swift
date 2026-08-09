//
//  AppNavigator.swift
//  Widgy
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
}
