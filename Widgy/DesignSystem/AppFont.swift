//
//  AppFont.swift
//  Kare
//
//  Typography bridge. The design calls for Fraunces (serif display/headings)
//  and DM Sans (sans body/labels). Until those TTFs are bundled, we fall back
//  to the system serif (New York) and SF Pro so the app builds and reads
//  identically in structure. Drop the .ttf files into `Resources/Fonts` and
//  they are picked up automatically at launch — no code change required.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
import CoreText
#endif

enum AppFont {

    /// Serif = Fraunces 72pt Soft. Each weight is a separate static instance,
    /// so map the requested weight to the matching PostScript name. If a file
    /// isn't bundled, fall back to the next lighter one, then to system serif.
    private static let serifByWeight: [Font.Weight: String] = [
        .black:    "Fraunces72ptSoft-Black",
        .heavy:    "Fraunces72ptSoft-Black",
        .bold:     "Fraunces72ptSoft-Bold",
        .semibold: "Fraunces72ptSoft-SemiBold",
        .medium:   "Fraunces72ptSoft-SemiBold",
        .regular:  "Fraunces72ptSoft-Regular",
    ]

    /// Sans body/labels. DM Sans if bundled, otherwise SF Pro.
    private static let sansCandidates = ["DMSans-Regular", "DM Sans", "DMSans"]
    private static let sansName: String? = resolve(sansCandidates)

    /// `relativeTo` is the text style whose Dynamic Type curve this size
    /// follows: at the default text size the font is exactly `size`.
    static func serif(size: CGFloat, weight: Font.Weight, relativeTo style: Font.TextStyle = .body) -> Font {
        if let name = resolvedSerifName(for: weight) {
            return .custom(name, size: size, relativeTo: style)
        }
        return .system(size: scaled(size, style), weight: weight, design: .serif)
    }

    static func sans(size: CGFloat, weight: Font.Weight, relativeTo style: Font.TextStyle = .body) -> Font {
        if let name = sansName {
            return .custom(name, size: size, relativeTo: style).weight(weight)
        }
        // SF Pro: the text style's own font when the size matches it exactly
        // (it then scales live), otherwise the size scaled once.
        if size == defaultSize(of: style) {
            return .system(style, design: .default, weight: weight)
        }
        return .system(size: scaled(size, style), weight: weight, design: .default)
    }

    private static func defaultSize(of style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption: 12
        case .caption2: 11
        @unknown default: 17
        }
    }

    private static func scaled(_ size: CGFloat, _ style: Font.TextStyle) -> CGFloat {
        #if canImport(UIKit)
        return UIFontMetrics(forTextStyle: style.uiKit).scaledValue(for: size)
        #else
        return size
        #endif
    }

    /// The static file already carries its weight, so no `.weight()` is applied.
    private static func resolvedSerifName(for weight: Font.Weight) -> String? {
        let order: [Font.Weight] = [weight, .bold, .semibold, .regular]
        for w in order {
            if let name = serifByWeight[w], isAvailable(name) { return name }
        }
        return nil
    }

    private static func resolve(_ candidates: [String]) -> String? {
        for name in candidates where isAvailable(name) { return name }
        return nil
    }

    private static func isAvailable(_ name: String) -> Bool {
        #if canImport(UIKit)
        return UIFont(name: name, size: 12) != nil
        #else
        return false
        #endif
    }
}

/// Registers any bundled font files at launch so `AppFont` can find them.
/// Safe to call when no fonts are bundled — it simply does nothing.
enum FontRegistrar {
    static func registerBundledFonts() {
        #if canImport(UIKit)
        let exts = ["ttf", "otf"]
        var urls: [URL] = []
        for ext in exts {
            urls += Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            urls += Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Fonts") ?? []
        }
        for url in Set(urls) {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
        #endif
    }
}

#if canImport(UIKit)
private extension Font.TextStyle {
    var uiKit: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        default: .body
        }
    }
}
#endif
