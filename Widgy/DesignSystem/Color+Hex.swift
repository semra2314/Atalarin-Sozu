//
//  Color+Hex.swift
//  Kare
//

import SwiftUI

extension Color {
    /// Accepts "RRGGBB", "#RRGGBB" or "RRGGBBAA". Falls back to gray on bad input.
    nonisolated init(hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }

        guard cleaned.count == 6 || cleaned.count == 8,
              let value = UInt64(cleaned, radix: 16) else {
            self = .gray
            return
        }

        let r, g, b, a: Double
        if cleaned.count == 6 {
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1
        } else {
            r = Double((value & 0xFF00_0000) >> 24) / 255
            g = Double((value & 0x00FF_0000) >> 16) / 255
            b = Double((value & 0x0000_FF00) >> 8) / 255
            a = Double(value & 0x0000_00FF) / 255
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Whether text placed over this colour should be dark rather than light.
    ///
    /// Uses the Rec. 601 luma weights rather than a plain average, because the
    /// eye is far more sensitive to green than to blue: a pure yellow and a
    /// pure blue have almost the same arithmetic mean and could not be more
    /// different to read against. The 0.6 threshold sits slightly above the
    /// midpoint, which errs toward white text on the mid-tones where either
    /// would technically pass.
    ///
    /// Takes a hex string rather than a `Color` on purpose: SwiftUI gives no
    /// portable way to read components back out of a `Color`, and every caller
    /// here already has the hex it was built from.
    nonisolated static func isLight(hex: String) -> Bool {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count >= 6, let value = UInt64(cleaned.prefix(6), radix: 16) else {
            return false
        }
        let r = Double((value & 0xFF0000) >> 16) / 255
        let g = Double((value & 0x00FF00) >> 8) / 255
        let b = Double(value & 0x0000FF) / 255
        return (0.299 * r + 0.587 * g + 0.114 * b) > 0.6
    }

    /// The same colour, darker by `amount` (0...1).
    ///
    /// Lets one stored hex become a two-stop gradient, so a card the user
    /// picked a flat colour for still has some depth instead of reading like
    /// a rectangle of paint.
    nonisolated static func shaded(hex: String, by amount: Double) -> Color {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") { cleaned.removeFirst() }
        guard cleaned.count >= 6, let value = UInt64(cleaned.prefix(6), radix: 16) else {
            return Color(hex: hex)
        }
        let factor = max(0, 1 - amount)
        let r = Double((value & 0xFF0000) >> 16) / 255 * factor
        let g = Double((value & 0x00FF00) >> 8) / 255 * factor
        let b = Double(value & 0x0000FF) / 255 * factor
        return Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
