//
//  AddToHomeGuide.swift
//  Widgy
//
//  One-time guide shown after the user's first save, walking them through the
//  real friction point: placing the widget on the iOS home screen.
//

import SwiftUI

struct AddToHomeGuide: View {
    /// Exactly what to look for in the iOS widget gallery. Defaults to the
    /// build-your-own widget; fixed-design widgets pass their own name so we
    /// never send the user hunting for the wrong entry.
    var galleryName: String = "Widgy"

    @Environment(\.dismiss) private var dismiss

    private struct Step: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    private var steps: [Step] {
        [
            Step(icon: "hand.tap.fill", title: "Touch and hold",
                 detail: "Press an empty spot on your home screen until the icons jiggle."),
            Step(icon: "plus.circle.fill", title: "Tap +, search “\(galleryName)”",
                 detail: "Hit the plus in the top corner, then find \(galleryName) in the list."),
            Step(icon: "square.grid.2x2.fill", title: "Pick a size, add it",
                 detail: "Choose Small, Medium or Large. It's on your home screen.")
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Saved!\nNow add it home")
                    .font(Theme.Typography.displayLarge)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Your widget lives in Widgy. Put it on your home screen in three steps.")
                    .font(Theme.Typography.bodyLarge)
                    .foregroundStyle(Theme.Palette.subtleText)
            }

            VStack(spacing: Theme.Spacing.md) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Image(systemName: step.icon)
                            .font(.title3)
                            .foregroundStyle(Theme.Palette.accent)
                            .frame(width: 44, height: 44)
                            .background(Theme.Palette.accentTint, in: .circle)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(index + 1). \(step.title)")
                                .font(Theme.Typography.title)
                                .foregroundStyle(Theme.Palette.ink)
                            Text(step.detail)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Palette.subtleText)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Got it")
                    .font(Theme.Typography.title)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Theme.Palette.accent, in: .capsule)
            }
            .buttonStyle(.plain)
        }
        .padding(Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.xl)
        .background(Theme.Palette.background)
    }
}

#Preview {
    AddToHomeGuide()
}
