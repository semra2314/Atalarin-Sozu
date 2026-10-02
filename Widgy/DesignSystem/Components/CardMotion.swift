//
//  CardMotion.swift
//  Kare
//
//  Two small pieces of motion that make the catalogue feel like objects you
//  can pick up: cards press in under your finger, and opening one zooms the
//  card itself into its page instead of sliding a new screen over it.
//

import SwiftUI

/// Cards sink a little while pressed and spring back on release.
struct KarePressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .opacity(configuration.isPressed && reduceMotion ? 0.8 : 1)
            .animation(.spring(duration: 0.28, bounce: 0.35), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == KarePressStyle {
    static var karePress: KarePressStyle { KarePressStyle() }
}

extension EnvironmentValues {
    /// The namespace a NavigationStack's zoom transitions share. Set by
    /// `withAppRoutes()`, read by cards and by the pages they open.
    @Entry var zoomNamespace: Namespace.ID? = nil
}

extension View {
    /// Marks a card as the place its page zooms out of. `id` must be unique on
    /// screen, which is why it carries the section as well as the widget.
    @ViewBuilder
    func zoomSource(_ id: String?) -> some View {
        modifier(ZoomSource(id: id))
    }
}

private struct ZoomSource: ViewModifier {
    let id: String?
    @Environment(\.zoomNamespace) private var namespace

    func body(content: Content) -> some View {
        if let id, let namespace {
            // No clip shape here: rounding the source's corners also rounds
            // them at rest, which cut the first letter off the author line
            // in the card's bottom-left corner.
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

/// The page side of the zoom. Falls back to the normal push when the page
/// was not opened from a card (a deep link, the hero banner on iPad, ...).
struct ZoomDestination: ViewModifier {
    let sourceID: String?
    @Environment(\.zoomNamespace) private var namespace

    func body(content: Content) -> some View {
        if let sourceID, let namespace {
            content.navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            content
        }
    }
}
