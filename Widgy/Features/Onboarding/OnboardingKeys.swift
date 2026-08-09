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
}
