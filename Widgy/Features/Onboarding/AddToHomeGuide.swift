//
//  AddToHomeGuide.swift
//  Kare
//
//  How to put a widget on the iOS home screen.
//
//  This is the most important screen in the app and it is worth saying why.
//  Everything else we do, every install from search or a video, ends here. A
//  user who cannot complete these three steps has a widget app that shows them
//  nothing, and they delete it the next day. The catalogue, the editor and the
//  marketplace are all downstream of this sheet working.
//
//  Three things were wrong with the first version:
//
//  1. It described gestures in words. "Touch and hold" is not a sentence
//     people can act on if they have never done it; it needs a picture.
//  2. It told people to *find* Kare in the gallery. That list is long and
//     alphabetical, and hunting through it is where most give up. The gallery
//     has a search field at the top, and saying so turns the hardest step into
//     the easiest one.
//  3. It could be seen once and never again. Anyone who dismissed it and then
//     forgot had no way back.
//

import SwiftUI
import UIKit   // UIImage(named:), to ask whether a screenshot exists yet

struct AddToHomeGuide: View {
    /// Exactly what to look for in the iOS widget gallery. Defaults to the
    /// build-your-own widget; fixed-design widgets pass their own name so we
    /// never send the user hunting for the wrong entry.
    var galleryName: String = "Kare"

    /// The name as the iOS widget gallery shows it. The gallery follows the
    /// phone's language, not Kare's in-app one, so this uses the bundle
    /// lookup rather than the SwiftUI locale.
    private var shownGalleryName: String { NSLocalizedString(galleryName, comment: "Widget gallery name") }

    /// Shown after a save (celebratory) or opened from Settings (reference).
    var isCelebration: Bool = true

    @Environment(\.dismiss) private var dismiss

    private struct Step: Identifiable {
        let id = UUID()
        let icon: String
        let title: LocalizedStringKey
        let detail: LocalizedStringKey
        /// Optional screenshot of the real iOS step. Drawn when the image is in
        /// the asset catalogue, skipped silently when it is not, so the guide
        /// works today and gets better the day the screenshots are added.
        let imageName: String
    }

    private var steps: [Step] {
        [
            Step(icon: "hand.tap.fill",
                 title: "Touch and hold the home screen",
                 detail: "Press an empty spot until the icons start to jiggle.",
                 imageName: "guide-step-hold"),
            Step(icon: "magnifyingglass",
                 title: "Tap + and search",
                 detail: "Hit the plus in the corner, then type “\(shownGalleryName)” in the search box. Do not scroll the list, it is long.",
                 imageName: "guide-step-search"),
            Step(icon: "square.grid.2x2.fill",
                 title: "Pick a size and add it",
                 detail: "Small, medium or large. Drag it where you want and tap Done.",
                 imageName: "guide-step-place"),
        ]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                header
                stepList
                lockScreenNote
            }
            .padding(Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, 96)
        }
        .background(Theme.Palette.background)
        .safeAreaInset(edge: .bottom) { doneButton }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(isCelebration ? "Saved!\nNow add it home" : "Adding a widget")
                .font(Theme.Typography.displayLarge)
                .foregroundStyle(Theme.Palette.ink)
            Text("Your widget lives in Kare. Put it on your home screen in three steps.")
                .font(Theme.Typography.bodyLarge)
                .foregroundStyle(Theme.Palette.subtleText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var stepList: some View {
        VStack(spacing: Theme.Spacing.xl) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack(alignment: .top, spacing: Theme.Spacing.md) {
                        Image(systemName: step.icon)
                            .font(.title3)
                            .foregroundStyle(Theme.Palette.accent)
                            .frame(width: 44, height: 44)
                            .background(Theme.Palette.accentTint, in: .circle)
                        VStack(alignment: .leading, spacing: 3) {
                            // verbatim: the step number is a numeral in every
                            // language, and interpolating it into a
                            // LocalizedStringKey would fork the catalogue key.
                            (Text(verbatim: "\(index + 1). ")
                                .foregroundStyle(Theme.Palette.subtleText)
                             + Text(step.title)
                                .foregroundStyle(Theme.Palette.ink))
                                .font(Theme.Typography.title)
                            Text(step.detail)
                                .font(Theme.Typography.body)
                                .foregroundStyle(Theme.Palette.subtleText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                    }

                    // The imagesets exist but are empty until the screenshots
                    // are dropped in, so check for real pixels, not just a
                    // non-nil UIImage.
                    if let shot = UIImage(named: step.imageName), shot.size.width > 1 {
                        Image(uiImage: shot)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(.rect(cornerRadius: Theme.Radius.card))
                            .overlay {
                                RoundedRectangle(cornerRadius: Theme.Radius.card)
                                    .stroke(Theme.Palette.hairline, lineWidth: 0.5)
                            }
                    }
                }
            }
        }
    }

    /// Half the catalogue also runs on the lock screen and almost nobody finds
    /// that by themselves, so it is worth one sentence here.
    private var lockScreenNote: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: "lock.fill")
                .font(.footnote)
                .foregroundStyle(Theme.Palette.ink)
                .frame(width: 34, height: 34)
                .background(Theme.Palette.surfaceMuted, in: .circle)
            VStack(alignment: .leading, spacing: 2) {
                Text("Lock screen too")
                    .font(Theme.Typography.cardTitle)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Touch and hold the lock screen, tap Customise, then the area under the clock.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.lg)
        .kareCard()
    }

    private var doneButton: some View {
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
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.lg)
        .background(.ultraThinMaterial)
    }
}

#Preview {
    AddToHomeGuide()
}
