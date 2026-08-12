//
//  WidgyApp.swift
//  Widgy
//
//  Created by Z. Erden Dereli on 20.07.2026.
//

import SwiftUI
import SwiftData
//
@main
struct WidgyApp: App {
    private let appEnvironment = AppEnvironment.live
    @State private var navigator = AppNavigator()
    @AppStorage(OnboardingKeys.language) private var languageRaw = AppLanguage.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    init() {
        // Picks up Fraunces / DM Sans if their TTFs are bundled in Resources/Fonts.
        FontRegistrar.registerBundledFonts()
    }

    private let modelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: InstalledWidget.self)
        } catch {
            // A failure here means the on-device store is unreadable.
            // Falling back to memory keeps the app usable instead of dead on launch.
            assertionFailure("Persistent store failed: \(error)")
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try! ModelContainer(for: InstalledWidget.self, configurations: config)
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootGate()
                .environment(\.appEnvironment, appEnvironment)
                .environment(navigator)
                // Applied at the root so a change in Settings reaches every
                // screen at once.
                .widgyLanguage(language)
        }
        .modelContainer(modelContainer)
    }
}
