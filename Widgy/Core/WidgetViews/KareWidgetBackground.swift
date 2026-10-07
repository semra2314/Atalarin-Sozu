//
//  KareWidgetBackground.swift
//  Kare  (shared: app + widget extension)
//
//  Lets the same widget view run on the home screen and inside the app.
//
//  On the home screen a widget's background must go through
//  `containerBackground(for: .widget)`, which the system draws behind the
//  content (and removes in StandBy and on the lock screen). Inside the app
//  there is no widget container, so that background would never be drawn. The
//  in-app preview sets `kareInAppPreview`, and this modifier then draws the
//  same background as a plain `.background`.
//

import SwiftUI
import WidgetKit

extension EnvironmentValues {
    /// True when a widget view is being drawn inside the app, as a preview.
    @Entry var kareInAppPreview: Bool = false
}

private struct KareWidgetBackground<Background: View>: ViewModifier {
    @Environment(\.kareInAppPreview) private var inApp
    let background: Background

    func body(content: Content) -> some View {
        if inApp {
            content.background { background }
        } else {
            content.containerBackground(for: .widget) { background }
        }
    }
}

extension View {
    /// `containerBackground(for: .widget)` on the home screen, a plain
    /// background in the in-app preview.
    func kareWidgetBackground<Background: View>(@ViewBuilder _ background: () -> Background) -> some View {
        modifier(KareWidgetBackground(background: background()))
    }
}
