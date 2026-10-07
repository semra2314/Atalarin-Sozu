//
//  WidgetTheme.swift
//  Kare
//

import SwiftUI

/// The visual recipe for a template. Stored as plain data so it can round-trip
/// through Firestore/JSON without touching SwiftUI types.
nonisolated struct WidgetTheme: Hashable, Codable, Sendable {
    var backgroundHexes: [String]
    var foregroundHex: String
    var accentHex: String
    var cornerRadius: Double
    var usesGlassEffect: Bool

    init(
        backgroundHexes: [String],
        foregroundHex: String = "FFFFFF",
        accentHex: String = "5E5CE6",
        cornerRadius: Double = 22,
        usesGlassEffect: Bool = false
    ) {
        self.backgroundHexes = backgroundHexes
        self.foregroundHex = foregroundHex
        self.accentHex = accentHex
        self.cornerRadius = cornerRadius
        self.usesGlassEffect = usesGlassEffect
    }

    var backgroundColors: [Color] { backgroundHexes.map(Color.init(hex:)) }
    var foreground: Color { Color(hex: foregroundHex) }
    var accent: Color { Color(hex: accentHex) }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: backgroundColors.isEmpty ? [.gray] : backgroundColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
