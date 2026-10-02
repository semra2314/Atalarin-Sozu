//
//  MacScale.swift
//  Kare
//
//  On a Mac, an iPad app is drawn at about 77% of its size, so everything
//  Kare shows (pages, cards, the tab bar, buttons) comes out small next to
//  real Mac apps. This lays the screen out in a smaller space and scales it
//  back up, which makes every element bigger by the same amount without
//  touching a single font or frame. On iPhone and iPad it does nothing.
//

import SwiftUI

enum MacScale {
    /// How much bigger Kare draws on a Mac. 1.3 undoes the system's shrink
    /// exactly; a little under that keeps more on screen.
    static let factor: CGFloat = 1.25

    static var isActive: Bool { ProcessInfo.processInfo.isiOSAppOnMac }
}

private struct MacScaled: ViewModifier {
    func body(content: Content) -> some View {
        if MacScale.isActive {
            GeometryReader { proxy in
                content
                    .frame(width: proxy.size.width / MacScale.factor,
                           height: proxy.size.height / MacScale.factor)
                    .scaleEffect(MacScale.factor, anchor: .topLeading)
            }
        } else {
            content
        }
    }
}

extension View {
    /// Draws this screen larger on a Mac. Apply once at the root of the app
    /// and once at the root of each sheet, since sheets are separate windows
    /// of their own as far as layout goes.
    func kareMacScaled() -> some View { modifier(MacScaled()) }
}
