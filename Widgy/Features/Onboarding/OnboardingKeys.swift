//
//  OnboardingKeys.swift
//  Kare
//
//  Shared AppStorage keys for first-run state.
//

import Foundation
import SwiftUI   // LocalizedStringKey, for the reason shown on each gate

/// Where an account is required, and where it is not.
///
/// The account exists for three things: writing a review, giving a rating, and
/// having a creator profile. All three attach your name to something other
/// people see, so all three need to know who you are.
///
/// Browsing the catalogue, building a widget and putting it on your own home
/// screen need none of that. Guideline 5.1.1(v) draws the line in the same
/// place: an app may require an account for account-based features, and only
/// those. Blocking the door instead would fail review for a requirement the
/// app cannot yet justify, and it would ask people to commit before they have
/// seen anything. Someone who has already made a widget they like signs up
/// with a reason.
enum AccountPolicy {
    /// Kare opens without an account. The gates are further in.
    static let allowsGuestAccess = true

    /// True only once the user has actually signed in. Finishing onboarding as
    /// a guest sets `completed`, not this: the two are deliberately different
    /// questions, and conflating them is what would let a guest post a review.
    static var hasAccount: Bool {
        UserDefaults.standard.bool(forKey: OnboardingKeys.hasAccount)
    }

    /// What the account is for, in the user's words rather than ours. Each
    /// case supplies the one line shown on the sign-in prompt, so the reason
    /// is always specific to what the person just tried to do.
    enum GatedAction {
        case writeReview
        case creatorProfile

        var reason: LocalizedStringKey {
            switch self {
            case .writeReview:
                "Reviews and ratings carry your name, so they need an account."
            case .creatorProfile:
                "A creator profile is how people find your widgets, so it needs an account."
            }
        }
    }
}

enum OnboardingKeys {
    static let completed = "hasCompletedOnboarding"
    /// True once the user has finished onboarding at least once. Stays true after
    /// logout, so returning users skip the intro slides and go straight to sign-in.
    static let hasOnboardedBefore = "hasOnboardedBefore"
    static let displayName = "displayName"
    static let username = "username"
    /// Set only when the user signs in with Apple or email. A guest who taps
    /// "Continue without account" finishes onboarding with this still false.
    static let hasAccount = "hasAccount"
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
    /// Raw value of `AppAppearance`.
    static let appearance = "appAppearance"
}
