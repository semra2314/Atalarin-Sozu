//
//  OnboardingKeys.swift
//  Widgy
//
//  Shared AppStorage keys for first-run state.
//

import Foundation

enum OnboardingKeys {
    static let completed = "hasCompletedOnboarding"
    /// True once the user has finished onboarding at least once. Stays true after
    /// logout, so returning users skip the intro slides and go straight to sign-in.
    static let hasOnboardedBefore = "hasOnboardedBefore"
    static let displayName = "displayName"
    static let username = "username"
    static let aesthetics = "selectedAesthetics"
    static let seenDiscoverTip = "hasSeenDiscoverTip"
    static let seenAddToHome = "hasSeenAddToHome"
    /// Raw value of `AppLanguage`. Not first-run state, but it lives here so
    /// every stored key has one home.
    static let language = "appLanguage"
    /// Whether the language question has been answered. Separate from
    /// `language` because "use the phone's language" is a real choice, and
    /// storing it would otherwise be indistinguishable from never having asked.
    static let languageChosen = "hasChosenLanguage"
}
