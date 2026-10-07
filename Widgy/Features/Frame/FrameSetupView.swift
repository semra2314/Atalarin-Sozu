//
//  FrameSetupView.swift
//  Kare
//
//  Where the Frame widget gets its photo, its words and its colour. Saving
//  here writes into the App Group and reloads the widget timeline, so the home
//  screen updates without the user having to do anything else.
//
//  The preview at the top is the medium widget's real layout rather than a
//  plain photo. Frame is the one widget whose home-screen look is nothing like
//  the picture you feed it, so showing the photo alone taught people the wrong
//  thing about what they were building.
//

import SwiftUI
import PhotosUI
import UIKit

struct FrameSetupView: View {
    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var caption: String = ""
    @State private var subtitle: String = ""
    @State private var backgroundHex: String = FramePhoto.defaultBackgroundHex
    @State private var isSaving = false
    @State private var justSaved = false
    @State private var showAddToHome = false
    /// Set when a picked photo could not be read. Before this the picker just
    /// closed and nothing happened, which on a photo whose original lives in
    /// iCloud looked exactly like the app ignoring the tap.
    @State private var photoError: LocalizedStringKey?

    private var draft: FramePhoto {
        FramePhoto(
            caption: caption.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitle: subtitle.trimmingCharacters(in: .whitespacesAndNewlines),
            backgroundHex: backgroundHex
        )
    }

    private var ink: Color { draft.ink }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                preview
                picker
                if let photoError {
                    Text(photoError)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Palette.accent)
                }
                captionField
                subtitleField
                colourPicker
                saveButton
                hint
            }
            .kareReadableWidth()
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.xl)
        }
        .background(Theme.Palette.background)
        .navigationTitle("Frame")
        .navigationBarTitleDisplayMode(.inline)
        .task { load() }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task { await ingest(newItem) }
        }
        // Otherwise the button keeps saying "Saved to your widget" while the
        // user types something the widget has not been told about.
        .onChange(of: caption) { justSaved = false }
        .onChange(of: subtitle) { justSaved = false }
        .sheet(isPresented: $showAddToHome) {
            AddToHomeGuide(galleryName: "Frame").presentationDetents([.large])
        }
    }

    // MARK: - Preview

    /// The medium widget, at its real 2.13 proportion, drawn from the same
    /// pieces the extension draws. Every control below moves it live.
    private var preview: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Group {
                    if caption.isEmpty { Text("make it yours") }
                    else { Text(verbatim: caption) }
                }
                    .font(AppFont.serif(size: 23, weight: .bold))
                    .foregroundStyle(ink)
                    .lineLimit(3)
                    .minimumScaleFactor(0.4)
                    .truncationMode(.tail)

                Group {
                    if imageData == nil { Text("Pick a photo\nin Kare.") }
                    else if subtitle.isEmpty { Text("Your moment,\nyour frame.") }
                    else { Text(verbatim: subtitle) }
                }
                        .font(AppFont.sans(size: 11, weight: .regular))
                        .foregroundStyle(ink.opacity(0.7))
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                        .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Group {
                if let imageData, let uiImage = UIImage(data: imageData) {
                    Color.clear
                        .overlay { Image(uiImage: uiImage).resizable().scaledToFill() }
                        .clipShape(.rect(cornerRadius: 14, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ink.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(ink.opacity(0.22),
                                              style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        )
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 18, weight: .light))
                                .foregroundStyle(ink.opacity(0.5))
                        )
                }
            }
            .frame(width: 112)
            .frame(maxHeight: .infinity)
        }
        .padding(16)
        .background {
            LinearGradient(
                colors: [Color(hex: backgroundHex), Color.shaded(hex: backgroundHex, by: 0.28)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        // A fixed height rather than an aspect ratio. `aspectRatio(.fit)` on a
        // stack that already has an intrinsic height fights it and settles
        // somewhere unpredictable; 158 is the real medium widget's height in
        // points, so on any phone this preview is within a few points of the
        // thing it is previewing.
        .frame(maxWidth: .infinity)
        .frame(height: 158)
        .clipShape(.rect(cornerRadius: Theme.Radius.hero, style: .continuous))
        .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
        .animation(.snappy, value: backgroundHex)
    }

    // MARK: - Controls

    private var picker: some View {
        PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: "photo")
                Text(imageData == nil ? "Choose a photo" : "Choose a different photo")
            }
            .font(Theme.Typography.title)
            .foregroundStyle(Theme.Palette.ink)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Theme.Palette.surface, in: .capsule)
            .overlay(Capsule().stroke(Theme.Palette.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var captionField: some View {
        field("Caption", placeholder: "Optional, a word or two", text: $caption)
    }

    /// The second line used to be hard-coded into the widget, which meant the
    /// smaller text on someone's own photo was written by us.
    private var subtitleField: some View {
        field("Second line", placeholder: "Your moment, your frame.", text: $subtitle, axis: .vertical)
    }

    private func field(
        _ title: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        text: Binding<String>,
        axis: Axis = .horizontal
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title).kareCapsLabel().foregroundStyle(Theme.Palette.subtleText)
            TextField(placeholder, text: text, axis: axis)
                .lineLimit(axis == .vertical ? 2 : 1)
                .font(Theme.Typography.body)
                .padding(Theme.Spacing.md)
                .background(Theme.Palette.surfaceMuted, in: .rect(cornerRadius: Theme.Radius.card))
                .submitLabel(.done)
        }
    }

    /// A fixed palette rather than a colour wheel. Every swatch here carries
    /// either cream or ink type at a readable contrast; a free picker would
    /// happily let someone choose a yellow that hides their own caption.
    private var colourPicker: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Card colour").kareCapsLabel().foregroundStyle(Theme.Palette.subtleText)
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(FramePhoto.backgroundPalette, id: \.self) { hex in
                    let selected = hex == backgroundHex
                    Button {
                        withAnimation(.snappy) { backgroundHex = hex }
                        justSaved = false
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 34, height: 34)
                            .overlay {
                                Circle().stroke(Theme.Palette.hairline, lineWidth: 0.5)
                            }
                            .overlay {
                                if selected {
                                    Circle()
                                        .stroke(Theme.Palette.accent, lineWidth: 2)
                                        .padding(-4)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: hex))
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
    }

    private var saveButton: some View {
        Button {
            save()
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: justSaved ? "checkmark" : "square.and.arrow.down")
                }
                Text(justSaved ? "Saved to your widget" : "Save to widget")
            }
            .font(Theme.Typography.title)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(imageData == nil ? Color(hex: "8C8382") : Theme.Palette.accent, in: .capsule)
        }
        .buttonStyle(.plain)
        .disabled(imageData == nil || isSaving)
    }

    private var hint: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Frame reads this photo straight from your device. It never leaves your phone.")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Palette.subtleText)

            Button {
                showAddToHome = true
            } label: {
                Text("How do I add it to my home screen?")
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.accent)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Data

    private func load() {
        imageData = FramePhotoStore.loadImageData()
        let meta = FramePhotoStore.loadMeta() ?? FramePhoto()
        caption = meta.caption
        subtitle = meta.subtitle
        backgroundHex = meta.backgroundHex
    }

    private func ingest(_ item: PhotosPickerItem) async {
        photoError = nil
        guard let raw = try? await item.loadTransferable(type: Data.self),
              UIImage(data: raw) != nil else {
            photoError = "That photo couldn't be loaded. If it's in iCloud, check your connection and try again."
            return
        }
        // Downscale before it ever reaches the App Group: the widget extension
        // has a tight memory budget and a full-size photo will blank it out.
        let downscaled = ImageDownscaler.downscaledJPEG(raw, maxDimension: FramePhotoStore.maxPixelSize)
        imageData = downscaled ?? raw
        justSaved = false
    }

    private func save() {
        guard let imageData else { return }
        isSaving = true
        FramePhotoStore.save(imageData: imageData, meta: draft)
        isSaving = false
        withAnimation(.snappy) { justSaved = true }
    }
}

#Preview {
    NavigationStack {
        FrameSetupView()
    }
    .environment(\.appEnvironment, .preview)
}
