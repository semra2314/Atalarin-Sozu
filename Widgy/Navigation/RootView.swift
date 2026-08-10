//
//  RootView.swift
//  Widgy
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AppNavigator.self) private var navigator
    @State private var discoverPath = NavigationPath()
    @State private var libraryPath = NavigationPath()
    @State private var profilePath = NavigationPath()
    @State private var searchPath = NavigationPath()

    var body: some View {
        @Bindable var navigator = navigator
        // The bar floats over the content and each scrollable screen reserves
        // room for it with `.widgyTabBarInset()`.
        //
        // This used to use `.safeAreaInset`, which is the idiomatic tool but
        // never actually inset the scroll content here — the Discover list kept
        // ending underneath the bar however much the bar's own height was
        // corrected. Reserving the space explicitly is less elegant and
        // completely predictable.
        return selectedStack
            .overlay(alignment: .bottom) {
                if showsTabBar {
                    WidgyTabBar(selection: $navigator.selectedTab)
                }
            }
    }

    /// Hide the tab bar once a detail/editor is pushed, so the pushed screen's
    /// own bottom bar (e.g. the GET / Add button) becomes the sticky CTA.
    private var showsTabBar: Bool {
        switch navigator.selectedTab {
        case .discover: discoverPath.isEmpty
        case .library: libraryPath.isEmpty
        case .profile: profilePath.isEmpty
        case .search: searchPath.isEmpty
        case .settings: true
        }
    }

    @ViewBuilder
    private var selectedStack: some View {
        switch navigator.selectedTab {
        case .discover:
            NavigationStack(path: $discoverPath) {
                DiscoverView().withAppRoutes()
            }
        case .library:
            NavigationStack(path: $libraryPath) {
                LibraryView().withAppRoutes()
            }
        case .profile:
            NavigationStack(path: $profilePath) {
                ProfileView().withAppRoutes()
            }
        case .search:
            NavigationStack(path: $searchPath) {
                SearchView().withAppRoutes()
            }
        case .settings:
            NavigationStack {
                SettingsView()
            }
        }
    }
}

extension View {
    /// Attaches the app's route table. Applied once per NavigationStack.
    func withAppRoutes() -> some View {
        navigationDestination(for: AppRoute.self) { route in
            switch route {
            case let .templateDetail(templateID):
                TemplateDetailView(templateID: templateID)
            case let .category(category):
                CategoryView(category: category)
            case let .author(authorID):
                AuthorView(authorID: authorID)
            case let .editor(templateID):
                WidgetEditorView(templateID: templateID)
            case let .setUpOnHome(templateID):
                SetUpOnHomeView(templateID: templateID)
            case .focus:
                FocusView()
            case .frame:
                FrameSetupView()
            case .daily:
                DailySetupView()
            }
        }
    }
}

#Preview {
    RootView()
        .environment(\.appEnvironment, .preview)
        .environment(AppNavigator())
        .modelContainer(for: InstalledWidget.self, inMemory: true)
}
