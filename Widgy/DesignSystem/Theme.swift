//
//  Theme.swift
//  Widgy
//
//  Design tokens. Every magic number in the UI should come from here,
//  so a restyle is one file rather than a scavenger hunt.
//
//  Locked to the "editorial App Store" direction:
//  warm off-white surfaces, a single coral accent, serif display + sans body.
//

import SwiftUI

enum Theme {

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 20      // container margin
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 40     // section gap
    }

    enum Radius {
        static let card: CGFloat = 20    // standard card
        static let hero: CGFloat = 28    // hero / large card
        static let chip: CGFloat = 999   // fully rounded pills
        static let sheet: CGFloat = 28
    }

    /// The one source of colour. Nothing vivid outside `accent`.
    enum Palette {
        static let background   = Color(hex: "FDF8F8")   // warm off-white page
        static let surface      = Color(hex: "FFFFFF")   // cards, nav, sheets
        static let surfaceMuted = Color(hex: "F1EDEC")   // preview placeholders, 2nd level
        static let ink          = Color(hex: "1D1D1F")   // primary text
        static let subtleText   = Color(hex: "5E5E63")   // secondary text
        static let hairline     = Color(hex: "E5E2E1")   // dividers, thin borders
        static let accent       = Color(hex: "D44A33")   // the ONLY vivid colour
        static let accentTint   = Color(hex: "D44A33").opacity(0.12)
    }

    /// Editorial type scale. Serif (Fraunces) for display/headings,
    /// sans (DM Sans) for body/labels. Falls back to system serif/SF Pro
    /// until the TTFs are bundled — see `AppFont`.
    enum Typography {
        static let displayLarge  = AppFont.serif(size: 34, weight: .heavy)   // hero title
        static let headline      = AppFont.serif(size: 24, weight: .bold)    // section title (md)
        static let headlineSmall = AppFont.serif(size: 20, weight: .bold)    // card / row title
        static let title         = AppFont.serif(size: 17, weight: .semibold)

        static let body          = AppFont.sans(size: 15, weight: .regular)
        static let bodyLarge     = AppFont.sans(size: 17, weight: .regular)
        static let label         = AppFont.sans(size: 13, weight: .medium)
        static let labelCaps     = AppFont.sans(size: 12, weight: .bold)     // pair with .tracking + uppercase

        // Legacy aliases kept so existing call sites keep compiling.
        static let sectionTitle  = headlineSmall
        static let cardTitle     = AppFont.sans(size: 15, weight: .semibold)
        static let caption       = label
        static let hero          = displayLarge
    }

    /// Standard soft editorial shadow.
    enum Shadow {
        static let color = Color.black.opacity(0.04)
        static let radius: CGFloat = 30
        static let y: CGFloat = 10
    }
}

extension View {
    /// Standard editorial card: white surface, generous radius, soft shadow.
    func widgyCard(cornerRadius: CGFloat = Theme.Radius.card) -> some View {
        background(Theme.Palette.surface, in: .rect(cornerRadius: cornerRadius))
            .shadow(
                color: Theme.Shadow.color,
                radius: Theme.Shadow.radius,
                x: 0,
                y: Theme.Shadow.y
            )
    }

    /// A caps label: 12pt, bold, letter-spaced, uppercased.
    func widgyCapsLabel() -> some View {
        font(Theme.Typography.labelCaps)
            .textCase(.uppercase)
            .tracking(0.6)
    }
}
