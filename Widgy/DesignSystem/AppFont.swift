//
//  AppFont.swift
//  Widgy
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

    static func serif(size: CGFloat, weight: Font.Weight) -> Font {
        if let name = resolvedSerifName(for: weight) {
            return .custom(name, fixedSize: size)
        }
        return .system(size: size, weight: weight, design: .serif)
    }

    static func sans(size: CGFloat, weight: Font.Weight) -> Font {
        if let name = sansName {
            return .custom(name, fixedSize: size).weight(weight)
        }
        return .system(size: size, weight: weight, design: .default)
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
