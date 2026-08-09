//
//  CustomWidgetView.swift
//  Widgy
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
    let content: WidgetContent
    var size: WidgetSize = .small
    /// Reference width the design was authored against, so font/sticker sizes
    /// scale proportionally when the view is rendered larger or smaller.
    var referenceWidth: CGFloat = 320
    /// iOS home-screen widgets use a continuous ~22pt corner. Callers can tune it.
    var cornerRadius: CGFloat = 22
    /// When true, the view fills whatever space it's given (the widget container)
    /// instead of forcing its own aspect ratio. Use this in the WidgetKit render
    /// so nothing letterboxes or stretches.
    var fills: Bool = false

    private var canvas: some View {
        GeometryReader { geo in
            let scale = geo.size.width / referenceWidth

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
                    photoView(photo, in: geo.size)
                }

                ForEach(content.texts) { element in
                    textView(element, in: geo.size, scale: scale)
                }

                ForEach(content.stickers) { sticker in
                    Image(systemName: sticker.symbolName)
                        .font(.system(size: referenceWidth * 0.14 * sticker.scale * scale))
                        .foregroundStyle(Color(hex: sticker.colorHex))
                        .opacity(sticker.opacity)
                        .rotationEffect(.degrees(sticker.rotation))
                        .position(x: geo.size.width * sticker.x,
                                  y: geo.size.height * sticker.y)
                }
            }
        }
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
    private func photoView(_ photo: WidgetContent.PhotoElement, in canvas: CGSize) -> some View {
        #if canImport(UIKit)
        if let image = UIImage(data: photo.imageData) {
            let width = canvas.width * photo.scale
            let ratio = image.size.height / max(image.size.width, 1)
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: width * ratio)
                .clipShape(.rect(cornerRadius: photo.cornerRadius * (canvas.width / referenceWidth),
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
