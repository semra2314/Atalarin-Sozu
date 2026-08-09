//
//  FrameWidget.swift
//  WidgyWidget  (widget extension target)
//
//  The user's own photo on the home screen, with an optional caption. Falls
//  back to an inviting empty state so a freshly-placed widget still looks
//  designed rather than broken.
//

import WidgetKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct FrameEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let caption: String
}

struct FrameProvider: TimelineProvider {

    private func currentEntry() -> FrameEntry {
        let image = FramePhotoStore.loadImageData().flatMap(UIImage.init(data:))
        return FrameEntry(date: .now, image: image, caption: FramePhotoStore.loadMeta()?.caption ?? "")
    }

    func placeholder(in context: Context) -> FrameEntry {
        FrameEntry(date: .now, image: nil, caption: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (FrameEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FrameEntry>) -> Void) {
        // Content only changes when the user picks a new photo, and the store
        // reloads us then — so a single entry with no refresh policy is right.
        completion(Timeline(entries: [currentEntry()], policy: .never))
    }
}

struct FrameWidgetEntryView: View {
    var entry: FrameProvider.Entry
    @Environment(\.widgetFamily) private var family

    private var hasPhoto: Bool { entry.image != nil }

    /// Small is too tight for the promo's split layout, so it goes full-bleed
    /// with the caption over a scrim. Medium and large use the real design:
    /// type on the left, the photo framed on the right.
    var body: some View {
        Group {
            if family == .systemSmall {
                compact
            } else {
                split
            }
        }
        .containerBackground(for: .widget) { backdropLayer }
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
            warmBackdrop
        }
    }

    private var cream: Color { Color(hex: "F0E3D5") }

    // MARK: Split layout (medium + large) — matches the promo art

    private var split: some View {
        HStack(alignment: .center, spacing: family == .systemLarge ? 20 : 14) {
            VStack(alignment: .leading, spacing: family == .systemLarge ? 14 : 8) {
                Text(entry.caption.isEmpty ? "make it yours" : entry.caption)
                    .font(AppFont.serif(size: family == .systemLarge ? 34 : 23, weight: .bold))
                    .foregroundStyle(cream)
                    .lineLimit(3)
                    .minimumScaleFactor(0.55)
                    .fixedSize(horizontal: false, vertical: true)

                Text(hasPhoto ? "Your moment,\nyour frame." : "Pick a photo\nin Widgy.")
                    .font(AppFont.sans(size: family == .systemLarge ? 13 : 11, weight: .regular))
                    .foregroundStyle(cream.opacity(0.7))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            photoPanel
                .frame(width: family == .systemLarge ? 150 : 112)
                .frame(maxHeight: .infinity)
        }
        // Even margins on all four sides, like the promo — the photo panel is
        // inset from the widget edge rather than bleeding into it.
        .padding(family == .systemLarge ? 22 : 16)
    }

    /// The framed photo on the right — inset and rounded, not bleeding to the
    /// widget's edge, which is what gives the promo its "gallery" feel.
    @ViewBuilder private var photoPanel: some View {
        if let image = entry.image {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipShape(.rect(cornerRadius: 14, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(cream.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(cream.opacity(0.22), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                )
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: family == .systemLarge ? 24 : 18, weight: .light))
                        .foregroundStyle(cream.opacity(0.5))
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
                if !entry.caption.isEmpty {
                    Text(entry.caption)
                        .font(AppFont.serif(size: 15, weight: .bold))
                        .foregroundStyle(cream)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
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
                Text("Pick a photo\nin Widgy")
                    .font(AppFont.sans(size: 11, weight: .regular))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(cream.opacity(0.8))
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Time-of-day artwork, the same hour mapping Aurora and Hush use.
    private var backgroundName: String {
        let hour = Calendar.current.component(.hour, from: entry.date)
        let base: String
        switch hour {
        case 5..<11: base = "frame-bg-morning"
        case 11..<19: base = "frame-bg-warm"
        default: base = "frame-bg-dusk"
        }
        return family == .systemMedium ? base + "-wide" : base
    }

    /// The warm brown card from the promo. Uses the generated artwork when it's
    /// in the catalog, and otherwise draws the same look in code — so the widget
    /// never depends on an asset being present to look finished.
    @ViewBuilder private var warmBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "3A2C26"), Color(hex: "241C1C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Golden light from the right only — the left half stays calm so
            // the serif caption over there stays readable.
            RadialGradient(
                colors: [Color(hex: "E8C9A0").opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 260
            )
            if UIImage(named: backgroundName) != nil {
                Image(backgroundName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                // The photo panel and caption sit on top of this, so keep the
                // artwork from overpowering them.
                    .overlay(Color.black.opacity(0.18))
            }
        }
    }
}

struct FrameWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: FramePhotoStore.widgetKind, provider: FrameProvider()) { entry in
            FrameWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Frame")
        .description("Your own photo, framed on the home screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
