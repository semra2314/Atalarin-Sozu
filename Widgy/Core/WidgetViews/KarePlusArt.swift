//
//  KarePlusArt.swift
//  Kare  (shared: app + widget extension)
//
//  Background artwork for the Kare+ widgets, with a fallback.
//
//  The art is generated separately (see widgy-kareplus-image-prompts.md) and
//  dropped into the asset catalogue by name. Until an image exists the widget
//  draws its gradient instead, so a missing asset is never a blank widget.
//

import SwiftUI
import UIKit
import WidgetKit

enum KarePlusArt {
    /// `base` for square widgets, `base-wide` for medium, falling back to the
    /// square image when there is no wide one yet.
    static func image(_ base: String, family: WidgetFamily) -> Image? {
        if family == .systemMedium, UIImage(named: base + "-wide") != nil {
            return Image(base + "-wide")
        }
        if UIImage(named: base) != nil {
            return Image(base)
        }
        return nil
    }
}

/// Art if there is some, a gradient if not, and a soft scrim either way so the
/// type on top stays readable whatever the picture does.
struct KarePlusBackground: View {
    let art: String?
    let family: WidgetFamily
    let fallback: [Color]
    /// Darkens the bottom for white type, or lightens it for dark type.
    var scrim: Color = .black
    var scrimStrength: Double = 0.45

    var body: some View {
        ZStack {
            LinearGradient(colors: fallback, startPoint: .topLeading, endPoint: .bottomTrailing)
            if let art, let image = KarePlusArt.image(art, family: family) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            }
            LinearGradient(colors: [scrim.opacity(scrimStrength * 0.3), scrim.opacity(scrimStrength)],
                           startPoint: .top, endPoint: .bottom)
        }
    }
}
