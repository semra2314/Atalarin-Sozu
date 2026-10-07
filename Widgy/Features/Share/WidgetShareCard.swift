//
//  WidgetShareCard.swift
//  Kare
//
//  The image a user posts when they like what they made.
//
//  Kare is being launched on TikTok and Instagram, and until now someone who
//  built a widget they were proud of had no way to show it. They screenshot
//  their home screen instead, which crops badly, leaks their notifications and
//  carries no mark saying where the widget came from. Every one of those posts
//  was reach we were giving away.
//
//  So the card is 9:16 on purpose: that is the native shape of both channels,
//  and a square would letterbox on the one place this is most likely to be
//  posted. It is drawn at 360x640 points and rendered at 3x, which lands on
//  exactly 1080x1920.
//
//  The background is pulled from the design's own colours rather than a fixed
//  Kare gradient. Two reasons: every share looks different, so a feed of them
//  does not read as an ad campaign, and the user recognises the post as theirs
//  rather than ours. The wordmark at the bottom is small for the same reason.
//  A share people are embarrassed to post is worth nothing.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct WidgetShareCard: View {
    let content: WidgetContent
    let size: WidgetSize
    let name: String

    /// Point size of the card. Rendered at 3x for a 1080x1920 image.
    static let canvas = CGSize(width: 360, height: 640)

    /// Colours lifted from the design itself, so the card frames the widget
    /// instead of competing with it. A photo background has no hexes to read,
    /// so those fall back to a neutral pair that flatters most images.
    private var backdropHexes: [String] {
        if case let .color(hexes) = content.background, !hexes.isEmpty {
            return hexes
        }
        return ["2A2A2E", "141416"]
    }

    private var backdrop: LinearGradient {
        LinearGradient(
            colors: backdropHexes.map { Color(hex: $0) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// White or near-black text, whichever the backdrop can carry. Picked from
    /// the first colour because that is what sits behind the top of the card.
    private var overlayInk: Color {
        Color.isLight(hex: backdropHexes[0]) ? Color(hex: "1D1D1F") : .white
    }

    var body: some View {
        ZStack {
            backdrop

            // A darkened wash so a pale design still reads against its own
            // colours, and so the widget below keeps its edges.
            LinearGradient(
                colors: [.black.opacity(0.06), .black.opacity(0.26)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 26) {
                Spacer()

                CustomWidgetView(content: content, size: size)
                    .frame(width: widgetWidth)
                    .aspectRatio(size.aspectRatio, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 26, style: .continuous))
                    .shadow(color: .black.opacity(0.28), radius: 24, y: 12)

                Text(name)
                    .font(.system(size: 21, weight: .semibold, design: .serif))
                    .foregroundStyle(overlayInk)
                    .lineLimit(1)

                Spacer()

                footer
            }
            .padding(.vertical, 44)
        }
        .frame(width: Self.canvas.width, height: Self.canvas.height)
    }

    /// Large enough to be the subject of the image, narrow enough that a large
    /// widget still fits the 9:16 frame with air around it.
    private var widgetWidth: CGFloat {
        switch size {
        case .large: 232
        case .medium: 268
        default: 200
        }
    }

    private var footer: some View {
        VStack(spacing: 7) {
            // The wordmark ships as a dark glyph, which would vanish on a dark
            // backdrop. Template rendering tints it by its alpha instead, so
            // one asset works on any colour the user's design happens to be.
            Image("KareWordmark")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 74)
                .foregroundStyle(overlayInk.opacity(0.85))

            Text("Made with Kare")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.6)
                .foregroundStyle(overlayInk.opacity(0.62))
        }
    }
}

// MARK: - Rendering

@MainActor
enum ShareImage {
    /// Renders the card to a UIImage.
    ///
    /// `ImageRenderer` is main-actor only and returns nil if the view fails to
    /// lay out, so every caller has to handle the optional rather than force
    /// unwrap it into a crash on someone's phone.
    static func render(content: WidgetContent, size: WidgetSize, name: String) -> UIImage? {
        let card = WidgetShareCard(content: content, size: size, name: name)
        let renderer = ImageRenderer(content: card)
        // 3x over a 360x640 card gives 1080x1920, the size both TikTok and
        // Instagram want. Reading the screen's scale instead would produce a
        // smaller image on a 2x device for no reason.
        renderer.scale = 3
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

#Preview {
    WidgetShareCard(
        content: WidgetContent(
            text: "",
            background: .color(["FF9A6C", "F76B8A", "8E44AD"]),
            texts: [.init(text: "good\nevening", fontWeight: .heavy, fontSize: 30,
                          alignment: .leading, x: 0.36, y: 0.32)]
        ),
        size: .small,
        name: "Sunset"
    )
}
