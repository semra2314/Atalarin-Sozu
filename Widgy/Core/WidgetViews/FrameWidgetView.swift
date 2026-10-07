//
//  FrameWidgetView.swift
//  Kare  (shared: app + widget extension)
//
//  The Frame widget's entry and view, moved out of the extension so the app can
//  draw the real widget, at every size, on the detail page. The provider and
//  the Widget declaration stay in actual-widgets/FrameWidget.swift.
//

import WidgetKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

nonisolated struct FrameEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let meta: FramePhoto
}

struct FrameWidgetEntryView: View {
    var entry: FrameEntry
    @Environment(\.widgetFamily) private var environmentFamily
    /// Set by the in-app preview, which has no widget family of its own.
    var familyOverride: WidgetFamily? = nil
    private var family: WidgetFamily { familyOverride ?? environmentFamily }

    private var hasPhoto: Bool { entry.image != nil }
    private var isLarge: Bool { family == .systemLarge }

    /// Cream on a dark card, ink on a pale one, decided by the colour the user
    /// picked rather than hard-coded to the original brown.
    private var ink: Color { entry.meta.ink }

    /// Small is too tight for the split layout, so it goes full-bleed with the
    /// caption over a scrim. Medium and large put type on the left and the
    /// photo framed on the right.
    var body: some View {
        Group {
            if family == .systemSmall {
                compact
            } else {
                split
            }
        }
        .kareWidgetBackground { backdropLayer }
    }

    /// On small the photo *is* the background — that's what makes the caption
    /// sit on it correctly. Putting the image here rather than in a ZStack
    /// also lets WidgetKit clip it properly; as a plain layer its aspect-fill
    /// grew the stack past the widget bounds and pushed the caption off-screen,
    /// which is why the small widget looked like it was missing its text.
    @ViewBuilder private var backdropLayer: some View {
        if family == .systemSmall, let image = entry.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            card
        }
    }

    // MARK: Split layout (medium + large)

    private var split: some View {
        HStack(alignment: .center, spacing: isLarge ? 20 : 14) {
            VStack(alignment: .leading, spacing: isLarge ? 14 : 8) {
                Group {
                    if entry.meta.caption.isEmpty {
                        Text("make it yours")
                    } else {
                        Text(verbatim: entry.meta.caption)
                    }
                }
                    .font(AppFont.serif(size: isLarge ? 34 : 23, weight: .bold))
                    .foregroundStyle(ink)
                    .lineLimit(3)
                    // No `fixedSize` here any more. Asking for the ideal height
                    // while also asking to shrink to fit is contradictory, and
                    // SwiftUI resolved it by letting a long unbreakable word
                    // run straight out of the widget and get sliced by the
                    // container's clip. Scale first, then truncate.
                    .minimumScaleFactor(0.4)
                    .truncationMode(.tail)

                subtitleText
                    .font(AppFont.sans(size: isLarge ? 13 : 11, weight: .regular))
                    .foregroundStyle(ink.opacity(0.7))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            photoPanel
                .frame(width: isLarge ? 150 : 112)
                .frame(maxHeight: .infinity)
        }
        // Even margins on all four sides — the photo panel is inset from the
        // widget edge rather than bleeding into it.
        .padding(isLarge ? 22 : 16)
    }

    /// The user's own second line.
    ///
    /// The two fallbacks are `Text` literals rather than stored strings, so
    /// they translate. Anything the user typed is `Text(verbatim:)`, because
    /// their words are data and must never be looked up in the catalogue: a
    /// caption that happened to read "Share" would otherwise come back
    /// translated.
    @ViewBuilder private var subtitleText: some View {
        if !hasPhoto {
            Text("Pick a photo\nin Kare.")
        } else if entry.meta.subtitle.isEmpty {
            Text("Your moment,\nyour frame.")
        } else {
            Text(verbatim: entry.meta.subtitle)
        }
    }

    /// The framed photo on the right: inset and rounded, not bleeding to the
    /// widget's edge, which is what gives it the gallery feel.
    ///
    /// `Color.clear` takes the offered box and the image rides on top of it as
    /// an overlay. That matters: a `resizable().aspectRatio(.fill)` image is
    /// *larger* than its frame by definition, and when it was the layout view
    /// it grew the HStack, pushed the caption out of the widget and, on large,
    /// covered the whole thing so the text vanished entirely. As an overlay it
    /// cannot influence layout at all, and the clip shape hides the excess.
    @ViewBuilder private var photoPanel: some View {
        if let image = entry.image {
            Color.clear
                .overlay {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                }
                .clipShape(.rect(cornerRadius: 14, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ink.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(ink.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                )
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: isLarge ? 24 : 18, weight: .light))
                        .foregroundStyle(ink.opacity(0.5))
                )
        }
    }

    // MARK: Compact (small)

    @ViewBuilder private var compact: some View {
        if hasPhoto {
            // The photo is the container background here, so this layer only
            // carries the caption and the scrim that keeps it readable.
            VStack {
                Spacer(minLength: 0)
                if !entry.meta.caption.isEmpty {
                    Text(entry.meta.caption)
                        .font(AppFont.serif(size: 15, weight: .bold))
                        .foregroundStyle(Color(hex: "F0E3D5"))
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                        .truncationMode(.tail)
                        .shadow(color: .black.opacity(0.6), radius: 4, y: 1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(alignment: .bottom) {
                            LinearGradient(colors: [.clear, .black.opacity(0.65)],
                                           startPoint: .top, endPoint: .bottom)
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 22, weight: .light))
                Text("Pick a photo\nin Kare")
                    .font(AppFont.sans(size: 11, weight: .regular))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(ink.opacity(0.8))
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: Card

    /// The card behind the photo, built from the colour the user chose.
    ///
    /// This used to be a fixed brown gradient plus time-of-day artwork. The
    /// artwork is gone rather than tinted: it was drawn for one specific brown
    /// and fought every other colour in the palette. A two-stop gradient
    /// derived from the chosen hex keeps the depth without assuming the hue.
    private var card: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: entry.meta.backgroundHex),
                    Color.shaded(hex: entry.meta.backgroundHex, by: 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // A little light from the top right, where the photo sits, so the
            // left half stays calm under the serif caption.
            RadialGradient(
                colors: [ink.opacity(0.10), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 260
            )
        }
    }
}
