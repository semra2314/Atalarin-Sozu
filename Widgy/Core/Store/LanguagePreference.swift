//
//  LanguagePreference.swift
//  Widgy
//
//  In-app language choice.
//
//  This could have been a link to iOS's per-app language screen, which has the
//  advantage of also covering the widgets — they're separate processes and
//  don't see this setting. It was rejected because it throws the user out of
//  the app mid-task, and the mismatch it avoids only appears when someone
//  deliberately picks an app language different from their phone's. Rare case,
//  common flow: keep the common flow smooth and be honest about the rest.
//

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system
    case turkish = "tr"
    case english = "en"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: String(localized: "Phone language")
        case .turkish: "Türkçe"
        case .english: "English"
        }
    }

    /// `nil` means "don't override" — SwiftUI then uses the system locale.
    var locale: Locale? {
        switch self {
        case .system: nil
        case .turkish: Locale(identifier: "tr")
        case .english: Locale(identifier: "en")
        }
    }
}

extension View {
    /// Applies the chosen language to everything below this point.
    func widgyLanguage(_ language: AppLanguage) -> some View {
        modifier(LanguageModifier(language: language))
    }
}

private struct LanguageModifier: ViewModifier {
    let language: AppLanguage

    func body(content: Content) -> some View {
        if let locale = language.locale {
            content
                .environment(\.locale, locale)
                // Re-create the tree on change: views that read a localized
                // string once, on appear, wouldn't otherwise pick up the new
                // language until they were rebuilt for some other reason.
                .id(locale.identifier)
        } else {
            content.id("system")
        }
    }
}
