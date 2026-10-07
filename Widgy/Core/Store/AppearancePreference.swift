//
//  AppearancePreference.swift
//  Kare
//
//  Light, dark, or whatever the phone is set to. Every colour in
//  `Theme.Palette` has both values, so this only picks which one shows.
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "Same as phone"
        case .light: "Light mode"
        case .dark: "Dark mode"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    /// `nil` follows the phone.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
