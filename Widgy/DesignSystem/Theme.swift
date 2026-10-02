//
//  Theme.swift
//  Kare
//
//  Design tokens. Every magic number in the UI should come from here,
//  so a restyle is one file rather than a scavenger hunt.
//
//  Locked to the "editorial App Store" direction:
//  warm off-white surfaces, a single coral accent, serif display + sans body.
//

import SwiftUI
import UIKit

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
    ///
    /// Every token has a light and a dark value and follows the phone (or
    /// the Appearance setting). The dark side keeps the same warmth: a
    /// brown-black page instead of pure black, cream ink instead of white.
    enum Palette {
        static let background   = Color(light: "FDF8F8", dark: "141111")   // page
        static let surface      = Color(light: "FFFFFF", dark: "1F1B1B")   // cards, nav, sheets
        static let surfaceMuted = Color(light: "F1EDEC", dark: "2B2626")   // placeholders, 2nd level
        static let ink          = Color(light: "1D1D1F", dark: "F5F1F0")   // primary text
        static let subtleText   = Color(light: "5E5E63", dark: "A8A2A1")   // secondary text
        static let hairline     = Color(light: "E5E2E1", dark: "3A3434")   // dividers, thin borders
        static let accent       = Color(light: "D44A33", dark: "E25A42")   // the ONLY vivid colour
        static let accentTint   = Color(light: "D44A331F", dark: "E25A422E")
        /// Text and icons drawn on top of an `ink` fill.
        static let onInk        = Color(light: "FFFFFF", dark: "1D1D1F")
        /// The soft stage widget previews sit on (editor canvas, onboarding).
        static let stageTop     = Color(light: "EFE9E7", dark: "2A2525")
        static let stageBottom  = Color(light: "E2DAD8", dark: "1F1B1B")
    }

    /// Editorial type scale. Serif (Fraunces) for display/headings,
    /// sans (DM Sans) for body/labels. Falls back to system serif/SF Pro
    /// until the TTFs are bundled — see `AppFont`.
    enum Typography {
        // Each size is the default; all of them grow and shrink with the
        // user's text size setting, following the text style next to it.
        static let displayLarge  = AppFont.serif(size: 34, weight: .heavy, relativeTo: .largeTitle)  // hero title
        static let headline      = AppFont.serif(size: 24, weight: .bold, relativeTo: .title2)       // section title (md)
        static let headlineSmall = AppFont.serif(size: 20, weight: .bold, relativeTo: .title3)       // card / row title
        static let title         = AppFont.serif(size: 17, weight: .semibold, relativeTo: .headline)

        static let body          = AppFont.sans(size: 15, weight: .regular, relativeTo: .subheadline)
        static let bodyLarge     = AppFont.sans(size: 17, weight: .regular, relativeTo: .body)
        static let label         = AppFont.sans(size: 13, weight: .medium, relativeTo: .footnote)
        static let labelCaps     = AppFont.sans(size: 12, weight: .bold, relativeTo: .caption)       // pair with .tracking + uppercase

        // Legacy aliases kept so existing call sites keep compiling.
        static let sectionTitle  = headlineSmall
        static let cardTitle     = AppFont.sans(size: 15, weight: .semibold, relativeTo: .subheadline)
        static let caption       = label
        static let hero          = displayLarge
    }

    /// Standard soft editorial shadow.
    enum Shadow {
        static let color = Color(light: "0000000A", dark: "00000066")
        static let radius: CGFloat = 30
        static let y: CGFloat = 10
    }
}

extension Theme {
    enum Layout {
        /// The widest a column of text and cards gets. Wider than any iPhone,
        /// narrow enough that an iPad line is still easy to read.
        static let readableWidth: CGFloat = 680
        /// For the catalogue screens, which are grids and shelves rather than
        /// text. Stops them stretching edge to edge in a wide Mac window.
        static let wideWidth: CGFloat = 1040
    }
}

extension View {
    /// Standard editorial card: white surface, generous radius, soft shadow.
    func kareCard(cornerRadius: CGFloat = Theme.Radius.card) -> some View {
        background(Theme.Palette.surface, in: .rect(cornerRadius: cornerRadius))
            .shadow(
                color: Theme.Shadow.color,
                radius: Theme.Shadow.radius,
                x: 0,
                y: Theme.Shadow.y
            )
    }

    /// Keeps a screen's content in a comfortable column on iPad. On iPhone
    /// the screen is already narrower than this, so nothing changes there.
    func kareReadableWidth(_ maxWidth: CGFloat = Theme.Layout.readableWidth) -> some View {
        frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
    }

    /// The same column for a List or ScrollView, done with content margins so
    /// the whole width still scrolls. Only kicks in when the screen is wider
    /// than the column, so iPhone lists keep their usual insets.
    func kareReadableScrollMargins(_ maxWidth: CGFloat = Theme.Layout.readableWidth) -> some View {
        modifier(ReadableScrollMargins(maxWidth: maxWidth))
    }

    /// The big title at the top of a tab, drawn in the content column so it
    /// lines up with what is under it at any window width. The system large
    /// title sits at the window edge, which on a wide Mac window is far away
    /// from a centred column.
    func kareScreenTitle() -> some View {
        font(.largeTitle.weight(.bold))
            .foregroundStyle(Theme.Palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.lg)
            .accessibilityAddTraits(.isHeader)
    }

    /// A caps label: 12pt, bold, letter-spaced, uppercased.
    func kareCapsLabel() -> some View {
        font(Theme.Typography.labelCaps)
            .textCase(.uppercase)
            .tracking(0.6)
    }
}

extension Color {
    /// A colour with one value for light appearance and one for dark,
    /// resolved by the system whenever the appearance changes.
    nonisolated init(light: String, dark: String) {
        self.init(uiColor: UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        })
    }
}

private struct ReadableScrollMargins: ViewModifier {
    let maxWidth: CGFloat
    @State private var width: CGFloat = 0

    func body(content: Content) -> some View {
        let extra = max(0, (width - maxWidth) / 2)
        Group {
            if extra > 0 {
                content.contentMargins(.horizontal, extra, for: .scrollContent)
            } else {
                content
            }
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
    }
}
