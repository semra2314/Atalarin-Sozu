//
//  KareApp.swift
//  Kare
//
//  Created by Z. Erden Dereli on 20.07.2026.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseCrashlytics

@main
struct KareApp: App {
    private let appEnvironment = AppEnvironment.live
    @State private var navigator = AppNavigator()
    /// Owned by the app, not by the paywall. Renewals, refunds and
    /// cancellations arrive whether or not that screen is open, and a widget
    /// card three taps away needs to know about them too.
    @State private var subscriptions = SubscriptionStore()
    @AppStorage(OnboardingKeys.language) private var languageRaw = AppLanguage.system.rawValue
    @AppStorage(OnboardingKeys.appearance) private var appearanceRaw = AppAppearance.system.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: languageRaw) ?? .system
    }

    init() {
        // Picks up Fraunces / DM Sans if their TTFs are bundled in Resources/Fonts.
        FontRegistrar.registerBundledFonts()
        // Firebase only when its config file is bundled, so the app still
        // runs before the project is connected to a Firebase project.
        if FirebaseApp.app() == nil,
           Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
            // Crash reports from real users only. A crash while developing
            // is already in front of us in Xcode, and would only bury the
            // ones we need to see.
            #if DEBUG
            Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(false)
            #endif
        }
        // A "signed in" flag with no Firebase user behind it goes back to guest.
        AuthService.reconcile()
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
                .environment(\.subscriptions, subscriptions)
                // Applied at the root so a change in Settings reaches every
                // screen at once.
                .kareLanguage(language)
                // Every Theme colour has a light and a dark value; this
                // picks one, or follows the phone when nil.
                .preferredColorScheme((AppAppearance(rawValue: appearanceRaw) ?? .system).colorScheme)
                // Products and entitlements are fetched once, at launch, so a
                // locked widget card knows whether it is locked before the
                // user ever opens the paywall.
                .task { await subscriptions.load() }
                // Removal answers given offline go out on the next launch.
                .task { await RemovalFeedbackStore.flush() }
                // Keeps the public profile in step with the one on this phone.
                .task { await PublicProfileService.shared.publishMine() }
                // Widgets run in their own process and cannot see the
                // in-app language; hand it to them through the App Group.
                .task { WidgetLanguage.save(appLanguageRaw: languageRaw) }
                .onChange(of: languageRaw) { _, newValue in
                    WidgetLanguage.save(appLanguageRaw: newValue)
                }
        }
        .modelContainer(modelContainer)
    }
}
