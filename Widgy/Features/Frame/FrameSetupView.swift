//
//  FrameSetupView.swift
//  Widgy
//
//  Where the Frame widget gets its photo. Picking here writes into the App
//  Group and reloads the widget timeline, so the home screen updates without
//  the user having to do anything else.
//

import SwiftUI
import PhotosUI
import UIKit

struct FrameSetupView: View {
    @State private var photoItem: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var caption: String = ""
    @State private var isSaving = false
    @State private var justSaved = false
    @State private var showAddToHome = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                preview
                picker
                captionField
                saveButton
                hint
            }
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
        .sheet(isPresented: $showAddToHome) {
            AddToHomeGuide(galleryName: "Frame").presentationDetents([.large])
        }
    }

    // MARK: - Preview

    private var preview: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: [Color(hex: "241C1C"), Color(hex: "5B4038")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 28, weight: .light))
                        Text("No photo yet")
                            .font(Theme.Typography.label)
                    }
                    .foregroundStyle(Color(hex: "E5D5C8"))
                }
            }

            if !caption.isEmpty && imageData != nil {
                Text(caption)
                    .font(AppFont.serif(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "F6EFE9"))
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 1)
                    .padding(Theme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(alignment: .bottom) {
                        LinearGradient(colors: [.clear, .black.opacity(0.55)],
                                       startPoint: .top, endPoint: .bottom)
                    }
            }
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerRadius: Theme.Radius.hero, style: .continuous))
        .shadow(color: Theme.Shadow.color, radius: Theme.Shadow.radius, y: Theme.Shadow.y)
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
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Caption").widgyCapsLabel().foregroundStyle(Theme.Palette.subtleText)
            TextField("Optional — a word or two", text: $caption)
                .font(Theme.Typography.body)
                .padding(Theme.Spacing.md)
                .background(Theme.Palette.surfaceMuted, in: .rect(cornerRadius: Theme.Radius.card))
                .submitLabel(.done)
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
            Text("Frame reads this photo straight from your device — it never leaves your phone.")
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
        caption = FramePhotoStore.loadMeta()?.caption ?? ""
    }

    private func ingest(_ item: PhotosPickerItem) async {
        guard let raw = try? await item.loadTransferable(type: Data.self) else { return }
        // Downscale before it ever reaches the App Group: the widget extension
        // has a tight memory budget and a full-size photo will blank it out.
        let downscaled = ImageDownscaler.downscaledJPEG(raw, maxDimension: FramePhotoStore.maxPixelSize)
        imageData = downscaled ?? raw
        justSaved = false
    }

    private func save() {
        guard let imageData else { return }
        isSaving = true
        FramePhotoStore.save(imageData: imageData, caption: caption.trimmingCharacters(in: .whitespacesAndNewlines))
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
