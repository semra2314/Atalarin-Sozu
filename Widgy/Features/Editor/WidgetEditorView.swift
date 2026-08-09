//
//  WidgetEditorView.swift
//  Widgy
//
//  The "make your own" widget editor. Two fixed zones: a canvas that stays put,
//  and a tabbed control panel — Text, Style, Background, Photos, Stickers.
//
//  Text (font, weight, size, spacing, alignment, colour), a gradient or photo
//  background, photos placed and sized on the canvas, and SF Symbol stickers.
//  Saves onto the InstalledWidget and mirrors into the App Group so a placed
//  home-screen widget configured for this design picks it up.
//

import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct WidgetEditorView: View {
    let templateID: String

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var matches: [InstalledWidget]
    @State private var content: WidgetContent?
    @State private var previewFamily: WidgetSize = .small
    @State private var selectedStickerID: UUID?
    @State private var selectedPhotoID: UUID?
    @State private var selectedTextID: UUID?
    @State private var photoItem: PhotosPickerItem?
    /// Separate picker binding: the background picker and the "add a photo to
    /// the canvas" picker would otherwise fight over the same selection.
    @State private var canvasPhotoItem: PhotosPickerItem?
    @State private var showAddToHome = false
    @State private var activeTab: EditorTab = .text
    @AppStorage(OnboardingKeys.seenAddToHome) private var seenAddToHome = false

    /// The control panel's sections. Scrolls horizontally, so it can grow as
    /// more element types are added without squeezing the labels.
    enum EditorTab: String, CaseIterable, Identifiable {
        case text, style, background, photos, stickers
        var id: String { rawValue }
        var title: String {
            switch self {
            case .text: "Text"
            case .style: "Style"
            case .background: "Background"
            case .photos: "Photos"
            case .stickers: "Stickers"
            }
        }
    }

    /// Home-screen families the preview offers (matches WidgetKit's systemSmall/Medium/Large).
    private let families: [WidgetSize] = [.small, .medium, .large]

    init(templateID: String) {
        self.templateID = templateID
        _matches = Query(filter: #Predicate { $0.templateID == templateID })
    }

    private let textColors = [
        "FFFFFF", "1D1D1F", "D44A33", "5E5E63", "F1EDEC",
        "FFD8A8", "4CC9F0", "4ADE80", "F4A261", "C8ACD6"
    ]

    /// Curated gradients, grouped so the picker reads as a palette rather than
    /// a wall of colour. Each row is a mood, not a random assortment.
    private let backgroundGroups: [(name: String, presets: [[String]])] = [
        ("Neutral", [
            ["1D1D1F", "3A3A3C"], ["0A0A0A", "2A2A2A"], ["FDF8F8", "E5E2E1"],
            ["2C2C2E", "5E5E63"], ["F1EDEC", "C7BFBB"]
        ]),
        ("Warm", [
            ["D44A33", "8C2E1E"], ["F4A261", "BC6C25"], ["FFB4A6", "D4634A"],
            ["5B4038", "241C1C"], ["FFD8A8", "E0904A"]
        ]),
        ("Cool", [
            ["2C1E5C", "E0639A"], ["10151F", "1E2B3C"], ["17153B", "433D8B"],
            ["06231C", "0E5C43"], ["7DB9E8", "C2E9FB"]
        ])
    ]

    /// Stickers by theme, so finding the right glyph doesn't mean scrolling
    /// past everything else.
    private let stickerGroups: [(name: String, symbols: [String])] = [
        ("Nature", ["sun.max.fill", "moon.fill", "cloud.fill", "snowflake",
                    "leaf.fill", "flame.fill", "drop.fill", "wind"]),
        ("Feeling", ["heart.fill", "star.fill", "sparkles", "face.smiling",
                     "hands.clap.fill", "party.popper.fill", "quote.opening", "peacesign"]),
        ("Daily", ["checkmark.seal.fill", "bolt.fill", "music.note", "book.fill",
                   "cup.and.saucer.fill", "figure.walk", "clock.fill", "calendar"])
    ]

    var body: some View {
        Group {
            if let widget = matches.first {
                if !widget.isCustomizable {
                    // Fixed-design widget (Aurora, Focus, ...). Its look is ours,
                    // not editable — and letting it through here would also mirror
                    // its design into the generic "Widgy" home-screen widget.
                    ContentUnavailableView(
                        "This design is fixed",
                        systemImage: "lock.fill",
                        description: Text("\(widget.name) ships with its own design. Add it from the home-screen widget gallery to use it.")
                    )
                } else if content != nil, let bound = Binding($content) {
                    editor(widget: widget, content: bound)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .task {
                            content = widget.content ?? widget.seededContent()
                            previewFamily = families.contains(widget.size) ? widget.size : .small
                        }
                }
            } else {
                ContentUnavailableView(
                    "Widget not found",
                    systemImage: "questionmark.square.dashed",
                    description: Text("Add it from Discover first, then edit it here.")
                )
            }
        }
        .background(Theme.Palette.background)
        .navigationTitle("Editor")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddToHome, onDismiss: {
            seenAddToHome = true
            dismiss()
        }) {
            AddToHomeGuide()
                .presentationDetents([.large])
        }
    }

    /// Two fixed zones: the canvas on top, a tabbed control panel below.
    ///
    /// The editor used to be one long scroll of stacked control groups, which
    /// meant the canvas — the only thing you actually need to watch while
    /// designing — slid off screen the moment you touched anything. Now only
    /// the panel scrolls.
    private func editor(widget: InstalledWidget, content: Binding<WidgetContent>) -> some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                canvasZone(content)
                    .frame(height: geo.size.height * 0.45)

                panel(content)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save(widget: widget, content: content.wrappedValue) }
                    .fontWeight(.semibold)
                    .tint(Theme.Palette.accent)
            }
        }
    }

    // MARK: - Canvas zone

    private func canvasZone(_ content: Binding<WidgetContent>) -> some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "EFE9E7"), Color(hex: "E2DAD8")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea(edges: .top)

            VStack(spacing: Theme.Spacing.lg) {
                Spacer(minLength: 0)
                HomeScreenCanvas(
                    content: content,
                    family: previewFamily,
                    selectedStickerID: $selectedStickerID,
                    selectedPhotoID: $selectedPhotoID,
                    selectedTextID: $selectedTextID
                )
                Spacer(minLength: 0)
                sizeSelector
            }
            .padding(.vertical, Theme.Spacing.lg)
        }
        .clipped()
    }

    // MARK: - Control panel

    private func panel(_ content: Binding<WidgetContent>) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Theme.Palette.hairline)
                .frame(width: 48, height: 5)
                .padding(.top, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.sm)

            tabBar

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    switch activeTab {
                    case .text: textPanel(content)
                    case .style: stylePanel(content)
                    case .background: backgroundPanel(content)
                    case .photos: photosPanel(content)
                    case .stickers: stickersPanel(content)
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xxl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            selectionActions(content)
        }
        .background(
            Theme.Palette.surface
                .clipShape(.rect(topLeadingRadius: 24, topTrailingRadius: 24))
                .ignoresSafeArea(edges: .bottom)
        )
        .shadow(color: .black.opacity(0.06), radius: 20, y: -6)
    }

    private var tabBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(EditorTab.allCases) { tab in
                    Button {
                        withAnimation(.snappy) { activeTab = tab }
                    } label: {
                        VStack(spacing: 6) {
                            Text(tab.title)
                                .font(Theme.Typography.label)
                                .fontWeight(activeTab == tab ? .bold : .medium)
                                .foregroundStyle(activeTab == tab ? Theme.Palette.accent : Theme.Palette.subtleText)
                            Rectangle()
                                .fill(activeTab == tab ? Theme.Palette.accent : .clear)
                                .frame(height: 2)
                                .clipShape(.rect(topLeadingRadius: 2, topTrailingRadius: 2))
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                        .padding(.top, Theme.Spacing.sm)
                        .fixedSize()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Theme.Spacing.sm)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.Palette.hairline).frame(height: 0.5)
        }
    }

    /// Duplicate / Delete for whatever is selected. Only shown when something
    /// actually is — an always-present bar with nothing to act on is noise.
    @ViewBuilder
    private func selectionActions(_ content: Binding<WidgetContent>) -> some View {
        if selectedPhotoID != nil || selectedStickerID != nil || selectedTextID != nil {
            HStack(spacing: Theme.Spacing.md) {
                Button {
                    duplicateSelection(content)
                } label: {
                    Label("Duplicate", systemImage: "plus.square.on.square")
                        .font(Theme.Typography.label)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.Palette.surfaceMuted, in: .capsule)
                        .foregroundStyle(Theme.Palette.ink)
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    deleteSelection(content)
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(Theme.Typography.label)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Theme.Palette.accentTint, in: .capsule)
                        .foregroundStyle(Theme.Palette.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.top, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.lg)
            .background(Theme.Palette.surface)
            .overlay(alignment: .top) {
                Rectangle().fill(Theme.Palette.hairline).frame(height: 0.5)
            }
        }
    }

    private func duplicateSelection(_ content: Binding<WidgetContent>) {
        if let id = selectedPhotoID,
           var copy = content.wrappedValue.photos.first(where: { $0.id == id }) {
            copy.id = UUID()
            copy.x = min(0.9, copy.x + 0.1)
            copy.y = min(0.9, copy.y + 0.1)
            content.wrappedValue.photos.append(copy)
            selectedPhotoID = copy.id
        } else if let id = selectedStickerID,
                  var copy = content.wrappedValue.stickers.first(where: { $0.id == id }) {
            copy.id = UUID()
            copy.x = min(0.9, copy.x + 0.12)
            copy.y = min(0.9, copy.y + 0.12)
            content.wrappedValue.stickers.append(copy)
            selectedStickerID = copy.id
        } else if let id = selectedTextID,
                  var copy = content.wrappedValue.texts.first(where: { $0.id == id }) {
            copy.id = UUID()
            copy.x = min(0.9, copy.x + 0.08)
            copy.y = min(0.9, copy.y + 0.1)
            content.wrappedValue.texts.append(copy)
            selectedTextID = copy.id
        }
    }

    private func deleteSelection(_ content: Binding<WidgetContent>) {
        if let id = selectedPhotoID {
            content.wrappedValue.photos.removeAll { $0.id == id }
            selectedPhotoID = nil
        } else if let id = selectedStickerID {
            content.wrappedValue.stickers.removeAll { $0.id == id }
            selectedStickerID = nil
        } else if let id = selectedTextID {
            content.wrappedValue.texts.removeAll { $0.id == id }
            selectedTextID = nil
        }
    }

    // MARK: - Size selector (iOS-style)

    private var sizeSelector: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(families) { family in
                Button {
                    withAnimation(.snappy) { previewFamily = family }
                } label: {
                    Text(family.displayName)
                        .font(Theme.Typography.label)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(
                            previewFamily == family ? Theme.Palette.accent : Theme.Palette.surface,
                            in: .capsule
                        )
                        .overlay(
                            Capsule().stroke(Theme.Palette.hairline,
                                             lineWidth: previewFamily == family ? 0 : 1)
                        )
                        .foregroundStyle(previewFamily == family ? Color.white : Theme.Palette.subtleText)
                        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Panels

    @ViewBuilder
    private func textPanel(_ content: Binding<WidgetContent>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            Button {
                addText(to: content)
            } label: {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "textformat")
                    Text("Add text")
                }
                .font(Theme.Typography.body)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .foregroundStyle(Theme.Palette.ink)
                .background(Theme.Palette.surfaceMuted, in: .rect(cornerRadius: Theme.Radius.card))
            }
            .buttonStyle(.plain)

            if content.wrappedValue.texts.isEmpty {
                Text("Text you add sits on the canvas — drag to move it, and long-press to duplicate or delete.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            } else {
                selectedTextControls(content: content)
            }
        }
    }

    @ViewBuilder
    private func selectedTextControls(content: Binding<WidgetContent>) -> some View {
        if let id = selectedTextID,
           let current = content.wrappedValue.texts.first(where: { $0.id == id }) {
            // Id-based binding, same reason as photos and stickers: a captured
            // index goes stale the moment an element is deleted.
            let text = Binding<WidgetContent.TextElement>(
                get: { content.wrappedValue.texts.first(where: { $0.id == id }) ?? current },
                set: { updated in
                    guard let index = content.wrappedValue.texts.firstIndex(where: { $0.id == id })
                    else { return }
                    content.wrappedValue.texts[index] = updated
                }
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                group("Your words") {
                    TextField("Your text", text: text.text, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(Theme.Typography.body)
                        .lineLimit(2...5)
                        .padding(Theme.Spacing.md)
                        .background(Theme.Palette.surfaceMuted, in: .rect(cornerRadius: Theme.Radius.card))
                }

                group("Colour") {
                    swatchRow(colors: textColors, selectedHex: text.wrappedValue.colorHex) { hex in
                        text.colorHex.wrappedValue = hex
                    }
                }

                labelledSlider("Size", value: text.fontSize, range: 10...48, step: 1,
                               minIcon: "textformat.size.smaller", maxIcon: "textformat.size.larger",
                               unit: .points)

                labelledSlider("Width", value: text.widthFraction, range: 0.3...1.0, step: nil,
                               minIcon: "arrow.right.and.line.vertical.and.arrow.left",
                               maxIcon: "arrow.left.and.line.vertical.and.arrow.right",
                               unit: .percent)

                labelledSlider("Rotation", value: text.rotation, range: -180...180, step: 1,
                               minIcon: "rotate.left", maxIcon: "rotate.right", unit: .degrees)

                Toggle(isOn: text.hasBackground) {
                    Label("Background plate", systemImage: "rectangle.fill")
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Palette.ink)
                }
                .tint(Theme.Palette.accent)

                if text.wrappedValue.hasBackground {
                    swatchRow(colors: textColors, selectedHex: text.wrappedValue.backgroundHex) { hex in
                        text.backgroundHex.wrappedValue = hex
                    }

                    labelledSlider("Opacity", value: text.backgroundOpacity, range: 0.05...1, step: nil,
                                   minIcon: "circle.dotted", maxIcon: "circle.fill", unit: .percent)

                    labelledSlider("Corners", value: text.backgroundCornerRadius, range: 0...30, step: 1,
                                   minIcon: "square", maxIcon: "circle", unit: .points)

                    labelledSlider("Padding", value: text.backgroundPadding, range: 0...24, step: 1,
                                   minIcon: "minus", maxIcon: "plus", unit: .points)
                }
            }
        } else {
            Text("Tap a text block on the canvas to edit it.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText)
        }
    }

    private func addText(to content: Binding<WidgetContent>) {
        let element = WidgetContent.TextElement(
            text: "Your text",
            colorHex: content.wrappedValue.textColorHex,
            y: content.wrappedValue.texts.isEmpty ? 0.35 : 0.5
        )
        content.wrappedValue.texts.append(element)
        selectedTextID = element.id
        selectedPhotoID = nil
        selectedStickerID = nil
    }

    @ViewBuilder
    private func stylePanel(_ content: Binding<WidgetContent>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            if let id = selectedTextID,
               let current = content.wrappedValue.texts.first(where: { $0.id == id }) {
                let text = Binding<WidgetContent.TextElement>(
                    get: { content.wrappedValue.texts.first(where: { $0.id == id }) ?? current },
                    set: { updated in
                        guard let index = content.wrappedValue.texts.firstIndex(where: { $0.id == id })
                        else { return }
                        content.wrappedValue.texts[index] = updated
                    }
                )

                group("Style") {
                    // Each font option is set in its own typeface, so the control
                    // shows what it does rather than just naming it.
                    pillSegmented(WidgetContent.FontStyle.allCases, selection: text.fontStyle) { style, isSelected in
                        Text(style.displayName)
                            .font(style.font(size: 13, weight: .semibold))
                            .foregroundStyle(isSelected ? Theme.Palette.ink : Theme.Palette.subtleText)
                    }

                    pillSegmented(WidgetContent.Weight.allCases, selection: text.fontWeight) { weight, isSelected in
                        Text(weight.displayName)
                            .font(.system(size: 13, weight: weight.swiftUI))
                            .foregroundStyle(isSelected ? Theme.Palette.ink : Theme.Palette.subtleText)
                    }

                    pillSegmented(WidgetContent.TextAlign.allCases, selection: text.alignment) { align, isSelected in
                        Image(systemName: align.symbolName)
                            .font(.system(size: 15))
                            .foregroundStyle(isSelected ? Theme.Palette.ink : Theme.Palette.subtleText)
                    }

                    labelledSlider("Line spacing", value: text.lineSpacing, range: 0...16, step: 1,
                                   minIcon: "minus", maxIcon: "arrow.up.and.down", unit: .points)
                }
            } else {
                Text("Tap a text block on the canvas to style it, or add one from the Text tab.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            }
        }
    }

    @ViewBuilder
    private func backgroundPanel(_ content: Binding<WidgetContent>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            group("Background") {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: content.background.wrappedValue.isPhoto ? "photo.fill" : "photo")
                        Text(content.background.wrappedValue.isPhoto ? "Change photo" : "Use a photo")
                    }
                    .font(Theme.Typography.body)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundStyle(content.background.wrappedValue.isPhoto ? Color.white : Theme.Palette.ink)
                    .background(
                        content.background.wrappedValue.isPhoto ? Theme.Palette.accent : Theme.Palette.surfaceMuted,
                        in: .rect(cornerRadius: Theme.Radius.card)
                    )
                }
                .onChange(of: photoItem) { _, item in
                    Task {
                        if let data = try? await item?.loadTransferable(type: Data.self),
                           let small = ImageDownscaler.downscaledJPEG(data) {
                            content.background.wrappedValue = .photo(small)
                        }
                    }
                }

                ForEach(backgroundGroups, id: \.name) { group in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(group.name)
                            .font(.caption2)
                            .foregroundStyle(Theme.Palette.subtleText)
                        ScrollView(.horizontal) {
                            HStack(spacing: Theme.Spacing.md) {
                                ForEach(group.presets, id: \.self) { preset in
                                    Button {
                                        content.background.wrappedValue = .color(preset)
                                    } label: {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(LinearGradient(
                                                colors: preset.map(Color.init(hex:)),
                                                startPoint: content.gradientDirection.wrappedValue.points.start,
                                                endPoint: content.gradientDirection.wrappedValue.points.end))
                                            .frame(width: 44, height: 44)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Theme.Palette.accent,
                                                            lineWidth: isSelectedBackground(content.background.wrappedValue, preset) ? 3 : 0)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .scrollIndicators(.hidden)
                    }
                }

                if !content.background.wrappedValue.isPhoto {
                    Text("Direction").widgyCapsLabel().foregroundStyle(Theme.Palette.subtleText)
                    pillSegmented(WidgetContent.GradientDirection.allCases,
                                  selection: content.gradientDirection) { direction, isSelected in
                        Image(systemName: direction.symbolName)
                            .font(.system(size: 15))
                            .foregroundStyle(isSelected ? Theme.Palette.ink : Theme.Palette.subtleText)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func photosPanel(_ content: Binding<WidgetContent>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            // Add button then a strip of what's already on the canvas — tapping
            // a thumbnail selects that photo, so you can reach one hidden
            // behind another without hunting on the canvas itself.
            ScrollView(.horizontal) {
                HStack(spacing: Theme.Spacing.md) {
                    PhotosPicker(selection: $canvasPhotoItem, matching: .images) {
                        VStack(spacing: 3) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 18, weight: .light))
                            Text("Add").font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(Theme.Palette.subtleText)
                        .frame(width: 64, height: 64)
                        .background(Theme.Palette.surfaceMuted, in: .rect(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Theme.Palette.hairline, lineWidth: 1)
                        )
                    }
                    .onChange(of: canvasPhotoItem) { _, item in
                        Task { await addCanvasPhoto(item, to: content) }
                    }

                    ForEach(content.wrappedValue.photos) { photo in
                        Button {
                            selectedPhotoID = photo.id
                            selectedStickerID = nil
                            selectedTextID = nil
                        } label: {
                            thumbnail(photo)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)

            if content.wrappedValue.photos.isEmpty {
                Text("Photos you add sit on the canvas — drag to move, and long-press to duplicate or delete.")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
            } else {
                selectedPhotoControls(content: content)
            }
        }
    }

    @ViewBuilder
    private func thumbnail(_ photo: WidgetContent.PhotoElement) -> some View {
        let isSelected = selectedPhotoID == photo.id
        Group {
            if let image = UIImage(data: photo.imageData) {
                Image(uiImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                Theme.Palette.surfaceMuted
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(.rect(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Theme.Palette.accent : Theme.Palette.hairline,
                        lineWidth: isSelected ? 2 : 1)
        )
        .opacity(isSelected ? 1 : 0.75)
    }

    @ViewBuilder
    private func stickersPanel(_ content: Binding<WidgetContent>) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
            // A four-column grid rather than a horizontal strip: with eight
            // glyphs per group, a scrolling row hides half of them behind a
            // gesture nobody knows to make.
            ForEach(stickerGroups, id: \.name) { stickerGroup in
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text(stickerGroup.name)
                        .widgyCapsLabel()
                        .foregroundStyle(Theme.Palette.subtleText)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.md), count: 4),
                        spacing: Theme.Spacing.md
                    ) {
                        ForEach(stickerGroup.symbols, id: \.self) { symbol in
                            Button {
                                addSticker(symbol, to: content)
                            } label: {
                                Image(systemName: symbol)
                                    .font(.system(size: 19, weight: .light))
                                    .foregroundStyle(Theme.Palette.ink)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Theme.Palette.surfaceMuted, in: .rect(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if !content.wrappedValue.stickers.isEmpty {
                Divider()
                selectedStickerControls(content: content)
            }
        }
    }

    @ViewBuilder
    private func selectedPhotoControls(content: Binding<WidgetContent>) -> some View {
        if let id = selectedPhotoID,
           let current = content.wrappedValue.photos.first(where: { $0.id == id }) {
            // Same id-based binding as stickers: capturing an index here would
            // crash the moment a photo is deleted from the canvas menu.
            let photoBinding = Binding<WidgetContent.PhotoElement>(
                get: { content.wrappedValue.photos.first(where: { $0.id == id }) ?? current },
                set: { updated in
                    guard let index = content.wrappedValue.photos.firstIndex(where: { $0.id == id })
                    else { return }
                    content.wrappedValue.photos[index] = updated
                }
            )

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Divider()
                Text("Selected photo")
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.subtleText)

                labelledSlider("Size", value: photoBinding.scale, range: 0.15...1.0, step: nil,
                               minIcon: "minus.magnifyingglass", maxIcon: "plus.magnifyingglass",
                               unit: .percent)

                labelledSlider("Rotation", value: photoBinding.rotation, range: -180...180, step: 1,
                               minIcon: "rotate.left", maxIcon: "rotate.right", unit: .degrees)

                labelledSlider("Corners", value: photoBinding.cornerRadius, range: 0...40, step: 1,
                               minIcon: "square", maxIcon: "circle", unit: .points)

                labelledSlider("Opacity", value: photoBinding.opacity, range: 0.15...1, step: nil,
                               minIcon: "circle.dotted", maxIcon: "circle.fill", unit: .percent)
                // Duplicate/Delete live in the panel's sticky action bar now,
                // so they're in the same place whatever is selected.
            }
        } else {
            Text("Tap a photo on the canvas to adjust it.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText)
        }
    }

    /// Adds a picked photo to the canvas, downscaled first. Several photos can
    /// share one design, and the whole payload has to fit the widget
    /// extension's memory budget — full-size images would blank the widget.
    private func addCanvasPhoto(_ item: PhotosPickerItem?, to content: Binding<WidgetContent>) async {
        guard let item,
              let raw = try? await item.loadTransferable(type: Data.self) else { return }
        let data = ImageDownscaler.downscaledJPEG(
            raw,
            maxDimension: WidgetContent.PhotoElement.maxPixelSize
        ) ?? raw
        let photo = WidgetContent.PhotoElement(imageData: data)
        content.wrappedValue.photos.append(photo)
        selectedPhotoID = photo.id
        selectedStickerID = nil
        selectedTextID = nil
        canvasPhotoItem = nil
    }

    @ViewBuilder
    private func selectedStickerControls(content: Binding<WidgetContent>) -> some View {
        if let id = selectedStickerID,
           let current = content.wrappedValue.stickers.first(where: { $0.id == id }) {
            // Look the sticker up by id on every access rather than capturing an
            // index. A captured index goes stale the moment a sticker is deleted
            // — including from the canvas's own long-press menu — and reading it
            // back crashed with an out-of-range access.
            let stickerBinding = Binding<WidgetContent.Sticker>(
                get: { content.wrappedValue.stickers.first(where: { $0.id == id }) ?? current },
                set: { updated in
                    guard let index = content.wrappedValue.stickers.firstIndex(where: { $0.id == id })
                    else { return }
                    content.wrappedValue.stickers[index] = updated
                }
            )
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Selected sticker")
                    .widgyCapsLabel()
                    .foregroundStyle(Theme.Palette.subtleText)

                swatchRow(colors: textColors, selectedHex: stickerBinding.wrappedValue.colorHex) { hex in
                    stickerBinding.colorHex.wrappedValue = hex
                }

                labelledSlider("Size", value: stickerBinding.scale, range: 0.5...2.5, step: nil,
                               minIcon: "minus.magnifyingglass", maxIcon: "plus.magnifyingglass",
                               unit: .multiplier)

                labelledSlider("Rotation", value: stickerBinding.rotation, range: -180...180, step: 1,
                               minIcon: "rotate.left", maxIcon: "rotate.right", unit: .degrees)

                labelledSlider("Opacity", value: stickerBinding.opacity, range: 0.15...1, step: nil,
                               minIcon: "circle.dotted", maxIcon: "circle.fill", unit: .percent)
                // Duplicate/Delete live in the panel's sticky action bar.
            }
        } else {
            Text("Tap a sticker on the canvas to adjust it.")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.subtleText)
        }
    }

    // MARK: - Pieces

    private func group<Content: View>(_ title: String, @ViewBuilder _ body: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title).widgyCapsLabel().foregroundStyle(Theme.Palette.subtleText)
            body()
        }
    }

    /// How a slider's current value should read. Sliders in the editor control
    /// very different quantities, and "0.45" tells nobody anything.
    enum ValueUnit {
        case percent      // 0...1        -> "45%"
        case degrees      // -180...180   -> "12°"
        case points       // any          -> "22px"
        case multiplier   // 0.5...2.5    -> "1.4x"

        func format(_ value: Double) -> String {
            switch self {
            case .percent: "\(Int((value * 100).rounded()))%"
            case .degrees: "\(Int(value.rounded()))°"
            case .points: "\(Int(value.rounded()))px"
            case .multiplier: String(format: "%.1fx", value)
            }
        }
    }

    /// Glyph + name on the left, value on the right, full-width track beneath —
    /// the slider anatomy the approved designs use throughout.
    private func labelledSlider(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double?,
        minIcon: String,
        maxIcon: String,
        unit: ValueUnit = .points
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: minIcon)
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.subtleText)
                Text(title)
                    .font(Theme.Typography.label)
                    .foregroundStyle(Theme.Palette.ink)
                Spacer()
                Text(unit.format(value.wrappedValue))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Theme.Palette.subtleText)
            }

            Group {
                if let step {
                    Slider(value: value, in: range, step: step)
                } else {
                    Slider(value: value, in: range)
                }
            }
            .tint(Theme.Palette.accent)
        }
        .accessibilityLabel(title)
    }

    /// The design's segmented control: a muted capsule track with the selected
    /// option riding on a white pill. SwiftUI's `.segmented` picker style can't
    /// be shaped like this, so it's built by hand.
    private func pillSegmented<Value: Hashable>(
        _ values: [Value],
        selection: Binding<Value>,
        @ViewBuilder label: @escaping (Value, Bool) -> some View
    ) -> some View {
        HStack(spacing: 4) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                let isSelected = selection.wrappedValue == value
                Button {
                    withAnimation(.snappy(duration: 0.2)) { selection.wrappedValue = value }
                } label: {
                    label(value, isSelected)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background {
                            if isSelected {
                                Capsule()
                                    .fill(Theme.Palette.surface)
                                    .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Theme.Palette.surfaceMuted, in: .capsule)
    }

    /// Scrolls horizontally. The palette grew past ten colours, and a fixed
    /// HStack that wide overflowed the screen — which dragged the whole editor
    /// layout sideways and made the outer scroll view snap back at the bottom.
    private func swatchRow(colors: [String], selectedHex: String, onPick: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: Theme.Spacing.md) {
                ForEach(colors, id: \.self) { hex in
                    Button { onPick(hex) } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 34, height: 34)
                            .overlay(Circle().stroke(Theme.Palette.hairline, lineWidth: 1))
                            .overlay(Circle().stroke(Theme.Palette.accent, lineWidth: selectedHex == hex ? 3 : 0))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 3)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Actions

    private func addSticker(_ symbol: String, to content: Binding<WidgetContent>) {
        let sticker = WidgetContent.Sticker(symbolName: symbol, x: 0.5, y: 0.5, scale: 1.0, colorHex: "FFFFFF")
        content.wrappedValue.stickers.append(sticker)
        selectedStickerID = sticker.id
        selectedPhotoID = nil
        selectedTextID = nil
    }

    private func isSelectedBackground(_ background: WidgetContent.Background, _ preset: [String]) -> Bool {
        if case let .color(hexes) = background { return hexes == preset }
        return false
    }

    private func save(widget: InstalledWidget, content: WidgetContent) {
        var content = content
        // Safety net: always shrink any embedded photo (even a pre-existing large
        // one) so the home-screen widget stays within its memory budget.
        if case let .photo(data) = content.background,
           let small = ImageDownscaler.downscaledJPEG(data) {
            content.background = .photo(small)
        }
        try? LibraryStore(context: modelContext).updateContent(widget, content: content)
        // Mirror it to the App Group under this widget's own id, so a placed
        // widget configured to show this design picks it up — and other placed
        // widgets keep showing theirs.
        SharedWidgetStore.save(id: widget.templateID,
                               content: content,
                               family: previewFamily,
                               name: widget.name)
        // First save: teach the user how to place it on the home screen.
        if seenAddToHome {
            dismiss()
        } else {
            showAddToHome = true
        }
    }
}

// MARK: - Home-screen canvas

/// Point sizes and corners tuned to read like real iOS home-screen widgets.
private enum WidgetMetrics {
    /// The width the design scales against, so a sticker keeps its size across families.
    static let referenceWidth: CGFloat = 329

    static func canvasSize(for family: WidgetSize) -> CGSize {
        switch family {
        case .medium: CGSize(width: 329, height: 155)
        case .large:  CGSize(width: 329, height: 345)
        default:      CGSize(width: 155, height: 155)   // small
        }
    }

    static func cornerRadius(for family: WidgetSize) -> CGFloat {
        family == .small ? 22 : 24
    }
}

/// The widget centered on a soft wallpaper, so it feels placed on a home screen.
/// Stickers stay draggable on top.
private struct HomeScreenCanvas: View {
    @Binding var content: WidgetContent
    var family: WidgetSize
    @Binding var selectedStickerID: UUID?
    @Binding var selectedPhotoID: UUID?
    @Binding var selectedTextID: UUID?

    /// Height-to-width ratio of the stored image, so the selection frame
    /// matches what's actually drawn.
    private func aspectRatio(of photo: WidgetContent.PhotoElement) -> CGFloat {
        guard let image = UIImage(data: photo.imageData), image.size.width > 0 else { return 1 }
        return image.size.height / image.size.width
    }

    /// The four corner dots on a selected element.
    private func handles(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            ForEach(0..<4, id: \.self) { corner in
                Circle()
                    .fill(Theme.Palette.surface)
                    .overlay(Circle().stroke(Theme.Palette.accent, lineWidth: 1.5))
                    .frame(width: 10, height: 10)
                    .offset(
                        x: (corner % 2 == 0 ? -1 : 1) * width / 2,
                        y: (corner < 2 ? -1 : 1) * height / 2
                    )
            }
        }
    }

    private func clearSelection(except keep: Element) {
        if keep != .photo { selectedPhotoID = nil }
        if keep != .sticker { selectedStickerID = nil }
        if keep != .text { selectedTextID = nil }
    }

    private enum Element { case photo, sticker, text }

    var body: some View {
        let canvas = WidgetMetrics.canvasSize(for: family)

        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(
                    colors: [Color(hex: "EFE9E7"), Color(hex: "E2DAD8")],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(height: 420)

            ZStack {
                CustomWidgetView(
                    content: content,
                    size: family,
                    referenceWidth: WidgetMetrics.referenceWidth,
                    cornerRadius: WidgetMetrics.cornerRadius(for: family)
                )
                .frame(width: canvas.width, height: canvas.height)
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)

                // Photo handles sit below sticker handles, matching the render
                // order — so tapping a sticker that overlaps a photo selects
                // the sticker, which is what you'd expect.
                ForEach($content.photos) { $photo in
                    // Hug the photo's real rendered bounds. The frame used to be
                    // square whatever the image's shape, so a wide or tall photo
                    // showed an outline that didn't match what was on screen.
                    let width = canvas.width * photo.scale
                    let height = width * aspectRatio(of: photo)
                    RoundedRectangle(cornerRadius: photo.cornerRadius * (canvas.width / WidgetMetrics.referenceWidth))
                        .stroke(Theme.Palette.accent,
                                lineWidth: selectedPhotoID == photo.id ? 2 : 0)
                        .frame(width: width, height: height)
                        .overlay {
                            if selectedPhotoID == photo.id {
                                handles(width: width, height: height)
                            }
                        }
                        .contentShape(Rectangle())
                        .position(x: canvas.width * photo.x, y: canvas.height * photo.y)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    selectedPhotoID = photo.id
                                    clearSelection(except: .photo)
                                    photo.x = min(max(value.location.x / canvas.width, 0), 1)
                                    photo.y = min(max(value.location.y / canvas.height, 0), 1)
                                }
                        )
                        .onTapGesture {
                            selectedPhotoID = photo.id
                            clearSelection(except: .photo)
                        }
                        .contextMenu {
                            Button {
                                duplicatePhoto(photo)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            Button(role: .destructive) {
                                deletePhoto(photo)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }

                ForEach($content.stickers) { $sticker in
                    let handle = canvas.width * 0.14 * sticker.scale + 18
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.Palette.accent, lineWidth: selectedStickerID == sticker.id ? 2 : 0)
                        .frame(width: handle, height: handle)
                        .contentShape(Rectangle())
                        .position(x: canvas.width * sticker.x, y: canvas.height * sticker.y)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    selectedStickerID = sticker.id
                                    clearSelection(except: .sticker)
                                    sticker.x = min(max(value.location.x / canvas.width, 0), 1)
                                    sticker.y = min(max(value.location.y / canvas.height, 0), 1)
                                }
                        )
                        .onTapGesture {
                            selectedStickerID = sticker.id
                            clearSelection(except: .sticker)
                        }
                        // Long-press acts on the sticker where it sits, instead
                        // of making the user find the controls further down.
                        .contextMenu {
                            Button {
                                duplicate(sticker)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            Button(role: .destructive) {
                                delete(sticker)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }

                // Text handles sit on top: text is usually the smallest target
                // and the thing you most often want to grab.
                ForEach($content.texts) { $element in
                    let width = canvas.width * element.widthFraction
                    let height = max(28, element.fontSize * (canvas.width / WidgetMetrics.referenceWidth) * 1.6)
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Theme.Palette.accent, lineWidth: selectedTextID == element.id ? 2 : 0)
                        .frame(width: width, height: height)
                        .overlay {
                            if selectedTextID == element.id {
                                handles(width: width, height: height)
                            }
                        }
                        .contentShape(Rectangle())
                        .position(x: canvas.width * element.x, y: canvas.height * element.y)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    selectedTextID = element.id
                                    clearSelection(except: .text)
                                    element.x = min(max(value.location.x / canvas.width, 0), 1)
                                    element.y = min(max(value.location.y / canvas.height, 0), 1)
                                }
                        )
                        .onTapGesture {
                            selectedTextID = element.id
                            clearSelection(except: .text)
                        }
                        .contextMenu {
                            Button {
                                duplicateText(element)
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                            Button(role: .destructive) {
                                deleteText(element)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .frame(width: canvas.width, height: canvas.height)
        }
        .frame(maxWidth: .infinity)
        .animation(.snappy, value: family)
    }

    /// Drops a copy slightly offset from the original, so it's visible rather
    /// than hidden exactly underneath.
    private func duplicate(_ sticker: WidgetContent.Sticker) {
        var copy = sticker
        copy.id = UUID()
        copy.x = min(0.9, sticker.x + 0.12)
        copy.y = min(0.9, sticker.y + 0.12)
        content.stickers.append(copy)
        selectedStickerID = copy.id
    }

    private func delete(_ sticker: WidgetContent.Sticker) {
        content.stickers.removeAll { $0.id == sticker.id }
        if selectedStickerID == sticker.id {
            selectedStickerID = nil
        }
    }

    private func duplicatePhoto(_ photo: WidgetContent.PhotoElement) {
        var copy = photo
        copy.id = UUID()
        copy.x = min(0.9, photo.x + 0.1)
        copy.y = min(0.9, photo.y + 0.1)
        content.photos.append(copy)
        selectedPhotoID = copy.id
    }

    private func deletePhoto(_ photo: WidgetContent.PhotoElement) {
        content.photos.removeAll { $0.id == photo.id }
        if selectedPhotoID == photo.id {
            selectedPhotoID = nil
        }
    }

    private func duplicateText(_ element: WidgetContent.TextElement) {
        var copy = element
        copy.id = UUID()
        copy.x = min(0.9, element.x + 0.08)
        copy.y = min(0.9, element.y + 0.1)
        content.texts.append(copy)
        selectedTextID = copy.id
    }

    private func deleteText(_ element: WidgetContent.TextElement) {
        content.texts.removeAll { $0.id == element.id }
        if selectedTextID == element.id {
            selectedTextID = nil
        }
    }
}

#Preview {
    NavigationStack {
        WidgetEditorView(templateID: "preview")
    }
    .modelContainer(for: InstalledWidget.self, inMemory: true)
}
