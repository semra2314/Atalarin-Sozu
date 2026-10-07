//
//  PhotoCropView.swift
//  Kare
//
//  Crops a photo by letting the user pan and zoom it inside a fixed frame,
//  the way every photo app does it.
//
//  The result is produced with `ImageRenderer` over the very same view the
//  user is looking at, rather than by recomputing the visible rectangle in
//  image coordinates. Doing the maths by hand means scale, offset, aspect fill
//  and image orientation all have to agree, and any disagreement shows up as a
//  crop that doesn't match the preview. Rendering what's on screen can't drift.
//

import SwiftUI
import UIKit

struct PhotoCropView: View {
    let imageData: Data
    /// Handed the cropped image as JPEG data.
    let onDone: (Data) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var aspect: CropAspect = .square
    @State private var scale: CGFloat = 1
    @State private var committedScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero

    /// The shapes a widget actually needs, plus the photo's own.
    enum CropAspect: String, CaseIterable, Identifiable {
        case square, wide, tall, original
        var id: String { rawValue }

        var title: String {
            switch self {
            case .square: "Square"
            case .wide: "Wide"
            case .tall: "Tall"
            case .original: "Original"
            }
        }

        /// Width ÷ height. `nil` means keep the source photo's own ratio.
        var ratio: CGFloat? {
            switch self {
            case .square: 1
            case .wide: 2.13      // the medium widget
            case .tall: 0.75
            case .original: nil
            }
        }
    }

    private var uiImage: UIImage? { UIImage(data: imageData) }

    private var sourceRatio: CGFloat {
        guard let uiImage, uiImage.size.height > 0 else { return 1 }
        return uiImage.size.width / uiImage.size.height
    }

    private var frameRatio: CGFloat { aspect.ratio ?? sourceRatio }

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.xl) {
                Spacer(minLength: 0)

                GeometryReader { geo in
                    let width = geo.size.width
                    let height = min(width / frameRatio, geo.size.height)
                    cropFrame(width: width, height: height)
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
                }
                .frame(height: 340)

                aspectPicker

                Text("Drag to reposition, pinch to zoom.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Palette.background)
            .navigationTitle("Crop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { finish() }
                        .fontWeight(.semibold)
                        .tint(Theme.Palette.accent)
                }
            }
        }
    }

    // MARK: - Frame

    private func cropFrame(width: CGFloat, height: CGFloat) -> some View {
        croppedContent(width: width, height: height)
            .overlay {
                // Rule-of-thirds guides, the usual crop affordance.
                ZStack {
                    ForEach(1..<3) { i in
                        Rectangle().fill(.white.opacity(0.35)).frame(width: 0.5)
                            .offset(x: width * (CGFloat(i) / 3 - 0.5))
                        Rectangle().fill(.white.opacity(0.35)).frame(height: 0.5)
                            .offset(y: height * (CGFloat(i) / 3 - 0.5))
                    }
                }
                .allowsHitTesting(false)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .stroke(.white.opacity(0.9), lineWidth: 2)
            }
            .gesture(
                SimultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: committedOffset.width + value.translation.width,
                                height: committedOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in committedOffset = offset },
                    MagnifyGesture()
                        .onChanged { value in
                            scale = max(1, min(committedScale * value.magnification, 6))
                        }
                        .onEnded { _ in committedScale = scale }
                )
            )
    }

    /// Exactly what gets rendered on Done — declared once so preview and
    /// output can't disagree.
    @ViewBuilder
    private func croppedContent(width: CGFloat, height: CGFloat) -> some View {
        if let uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .scaleEffect(scale)
                .offset(offset)
                .frame(width: width, height: height)
                .clipShape(.rect(cornerRadius: Theme.Radius.card, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .fill(Theme.Palette.surfaceMuted)
                .frame(width: width, height: height)
                .overlay(Text("Couldn't load that photo").font(Theme.Typography.caption))
        }
    }

    private var aspectPicker: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(CropAspect.allCases) { option in
                Button {
                    withAnimation(.snappy) {
                        aspect = option
                        // Reframing invalidates the old pan/zoom.
                        scale = 1; committedScale = 1
                        offset = .zero; committedOffset = .zero
                    }
                } label: {
                    Text(option.title)
                        .font(Theme.Typography.label)
                        .padding(.horizontal, Theme.Spacing.md)
                        .frame(height: 36)
                        .background(aspect == option ? Theme.Palette.accent : Theme.Palette.surfaceMuted,
                                    in: .capsule)
                        .foregroundStyle(aspect == option ? Color.white : Theme.Palette.ink)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Output

    private func finish() {
        // Render at a size that suits a widget rather than the source photo's
        // full resolution — this data ends up in the App Group with everything
        // else the widget has to hold in memory.
        let targetWidth: CGFloat = 600
        let width: CGFloat = 320
        let height = width / frameRatio

        let renderer = ImageRenderer(content: croppedContent(width: width, height: height))
        renderer.scale = targetWidth / width
        renderer.isOpaque = true

        guard let image = renderer.uiImage,
              let data = image.jpegData(compressionQuality: 0.85) else {
            dismiss()
            return
        }
        onDone(data)
        dismiss()
    }
}

#Preview {
    PhotoCropView(imageData: Data()) { _ in }
}
