//
//  LibraryGate.swift
//  Kare widget extension
//
//  A widget draws only when it is in the user's library. WidgetKit cannot hide
//  a widget from the system picker at runtime, so one that has not been added
//  in Kare shows this face instead of its design.
//

import SwiftUI
import WidgetKit

private struct LibraryGate: ViewModifier {
    let templateID: String

    func body(content: Content) -> some View {
        if LibraryMirror.has(templateID) {
            content
        } else {
            NotInLibraryView()
        }
    }
}

private struct NotInLibraryView: View {
    @Environment(\.widgetFamily) private var family

    private var isAccessory: Bool {
        switch family {
        case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge: false
        default: true
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.square.dashed")
                .font(isAccessory ? .body : .title2)
            if !isAccessory {
                Text("Add this widget in Kare first")
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding()
        .containerBackground(for: .widget) { Color(hex: "1D1D1F") }
    }
}

extension View {
    /// Shows the widget only when `templateID` is in the user's library.
    func libraryGated(_ templateID: String) -> some View {
        modifier(LibraryGate(templateID: templateID))
    }
}
