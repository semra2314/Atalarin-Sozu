//
//  CustomWidgetView.swift
//  Kare
//
//  Display-only renderer for user-built `WidgetContent`. Used both in the
//  editor's live canvas and as a thumbnail in the library. Interaction
//  (dragging stickers) lives in the editor, layered on top of this.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct CustomWidgetView: View {
    /// How much a design shrinks or grows inside a canvas of this size.
    ///
    /// Exposed as a static so the editor's drag handles can ask the renderer
    /// rather than reimplement the formula. They were two separate copies of
    /// `canvas.width / referenceWidth`, which is fine until one of them
    /// changes: then every handle sits somewhere the user's finger is not.
    static func scale(in canvas: CGSize, referenceWidth: CGFloat) -> CGFloat {
        min(canvas.width, canvas.height) / referenceWidth
    }

    /// The canvas width every design is authored against.
    ///
    /// This number was written out four times: 329 in the widget extension,
    /// 329 in the editor's metrics, and the default 320 here, which the
    /// catalog previews and the share card both used. So a design drawn in the
    /// editor rendered about three percent larger in a preview than on the
    /// home screen. One constant, one truth.
    static let authoringWidth: CGFloat = 329

    let content: WidgetContent
    var size: WidgetSize = .small
    /// Reference width the design was authored against, so font/sticker sizes
    /// scale proportionally when the view is rendered larger or smaller.
    var referenceWidth: CGFloat = CustomWidgetView.authoringWidth
    /// iOS home-screen widgets use a continuous ~22pt corner. Callers can tune it.
    var cornerRadius: CGFloat = 22
    /// When true, the view fills whatever space it's given (the widget container)
    /// instead of forcing its own aspect ratio. Use this in the WidgetKit render
    /// so nothing letterboxes or stretches.
    var fills: Bool = false

    private var canvas: some View {
        GeometryReader { geo in
            // Scale from the *shorter* side, not the width.
            //
            // A medium widget is a small widget made wider: 360x170 against
            // 170x170. Dividing by width made everything on a medium more than
            // twice the size it was on a small, while the height stayed put, so
            // type and photos authored on one family burst out of the other.
            // The shorter side is the dimension that actually constrains a
            // design, and it is nearly identical for small and medium, so the
            // same design now renders at the same physical size on both and
            // simply gets more room to breathe sideways. Large is genuinely
            // twice the size and scales up, which is what anyone would expect.
            let unit = min(geo.size.width, geo.size.height)
            let scale = Self.scale(in: geo.size, referenceWidth: referenceWidth)

            ZStack {
                content.background.view(direction: content.gradientDirection)

                if content.textScrim {
                    LinearGradient(
                        colors: [.black.opacity(0.45), .black.opacity(0.05)],
                        startPoint: content.verticalAlign == .bottom ? .bottom : .top,
                        endPoint: content.verticalAlign == .bottom ? .top : .bottom
                    )
                }

                // Placed photos sit above the background but below the text and
                // stickers, so type stays legible on top of them.
                ForEach(content.photos) { photo in
                    photoView(photo, in: geo.size, unit: unit)
                }

                ForEach(content.texts) { element in
                    textView(element, in: geo.size, scale: scale)
                }

                ForEach(content.stickers) { sticker in
                    stickerView(sticker, in: geo.size, scale: scale)
                }
            }
        }
    }

    /// A sticker: either an emoji drawn as text in Apple's own colours, or a
    /// monochrome SF Symbol tinted with the chosen colour.
    @ViewBuilder
    private func stickerView(
        _ sticker: WidgetContent.Sticker,
        in canvas: CGSize,
        scale: CGFloat
    ) -> some View {
        let size = referenceWidth * 0.14 * sticker.scale * scale
        Group {
            if let data = sticker.imageData, let image = UIImage(data: data) {
                // A cut-out keeps its own proportions — forcing it square
                // would squash whatever the user lifted out of their photo.
                let ratio = image.size.height / max(image.size.width, 1)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size * 1.6, height: size * 1.6 * ratio)
            } else if let emoji = sticker.emoji {
                Text(emoji)
                    // Emoji glyphs sit a little smaller than a symbol at the
                    // same point size, so nudge them up to match visually.
                    .font(.system(size: size * 1.1))
            } else {
                Image(systemName: sticker.symbolName)
                    .font(.system(size: size))
                    .foregroundStyle(Color(hex: sticker.colorHex))
            }
        }
        .opacity(sticker.opacity)
        .rotationEffect(.degrees(sticker.rotation))
        .position(x: canvas.width * sticker.x, y: canvas.height * sticker.y)
    }

    /// One placed text block, optionally on its own tinted plate.
    private func textView(
        _ element: WidgetContent.TextElement,
        in canvas: CGSize,
        scale: CGFloat
    ) -> some View {
        Text(element.text)
            .font(element.fontStyle.font(size: element.fontSize * scale, weight: element.fontWeight))
            .foregroundStyle(Color(hex: element.colorHex))
            .multilineTextAlignment(element.alignment.textAlignment)
            .lineSpacing(element.lineSpacing * scale)
            // A single long word cannot wrap, so `maxWidth` alone does not
            // contain it: SwiftUI lets it overflow and the widget's clip mask
            // slices it off mid-letter. Shrinking to fit is the only graceful
            // answer, and people do type "isqwerqwerqwerq" into a text field.
            .minimumScaleFactor(0.5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: canvas.width * element.widthFraction)
            .padding(element.hasBackground ? element.backgroundPadding * scale : 0)
            .background {
                if element.hasBackground {
                    RoundedRectangle(
                        cornerRadius: element.backgroundCornerRadius * scale,
                        style: .continuous
                    )
                    .fill(Color(hex: element.backgroundHex).opacity(element.backgroundOpacity))
                }
            }
            .rotationEffect(.degrees(element.rotation))
            .position(x: canvas.width * element.x, y: canvas.height * element.y)
    }

    @ViewBuilder
    private func photoView(
        _ photo: WidgetContent.PhotoElement,
        in canvas: CGSize,
        unit: CGFloat
    ) -> some View {
        #if canImport(UIKit)
        if let image = UIImage(data: photo.imageData) {
            // Sized off the shorter side for the same reason the type is: a
            // photo at 0.6 used to mean 60% of a medium widget's *width*,
            // which is more than its whole height, so it bled off the top and
            // bottom edges.
            let width = unit * photo.scale
            let ratio = image.size.height / max(image.size.width, 1)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: width * ratio)
                .clipShape(.rect(cornerRadius: photo.cornerRadius * (unit / referenceWidth),
                                 style: .continuous))
                .opacity(photo.opacity)
                .rotationEffect(.degrees(photo.rotation))
                .position(x: canvas.width * photo.x, y: canvas.height * photo.y)
        }
        #endif
    }

    var body: some View {
        if fills {
            canvas
                .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
        } else {
            canvas
                .aspectRatio(size.aspectRatio, contentMode: .fit)
                .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )
        }
    }
}

#Preview {
    CustomWidgetView(
        content: WidgetContent(
            text: "Stay\nfocused",
            fontStyle: .serif,
            fontSize: 24,
            textColorHex: "FFFFFF",
            alignment: .leading,
            background: .color(["D44A33", "8C2E1E"]),
            stickers: [.init(symbolName: "sparkles", x: 0.8, y: 0.25, scale: 1.2, colorHex: "FFFFFF")]
        ),
        size: .medium
    )
    .frame(width: 320)
    .padding()
}
