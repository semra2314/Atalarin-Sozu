//
//  WidgetContent.swift
//  Widgy
//
//  The editable payload a user builds in the widget editor: some text with a
//  chosen font/size/colour/alignment, a background (a colour gradient OR a
//  photo), and any number of SF Symbol stickers positioned on the canvas.
//
//  Stored as plain, Codable data so it round-trips through SwiftData today and
//  Firestore later, exactly like `WidgetTheme`.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

nonisolated struct WidgetContent: Codable, Hashable, Sendable {
    var text: String
    var fontStyle: FontStyle
    var fontSize: Double
    var textColorHex: String
    var alignment: TextAlign
    var background: Background
    var stickers: [Sticker]
    /// Photos placed *on* the canvas, each positioned and sized by the user.
    /// Distinct from `background: .photo`, which fills the whole widget.
    var photos: [PhotoElement]
    /// Text placed on the canvas, each block dragged and sized by the user.
    ///
    /// The original single `text` field above is still read for designs saved
    /// before this existed — see the decoder, which lifts it into the first
    /// element. New designs put everything here.
    var texts: [TextElement]

    // Everything below was added after the first designs shipped. Each has a
    // default and is decoded with `decodeIfPresent`, so widgets saved by an
    // earlier build still load and simply keep the original look.
    var verticalAlign: VerticalAlign
    var fontWeight: Weight
    var gradientDirection: GradientDirection
    /// A soft dark scrim behind the text. Cheap insurance for legibility when
    /// someone drops bright artwork behind light type.
    var textScrim: Bool
    var lineSpacing: Double

    init(
        text: String = "Your text",
        fontStyle: FontStyle = .serif,
        fontSize: Double = 22,
        textColorHex: String = "FFFFFF",
        alignment: TextAlign = .leading,
        background: Background = .color(["1D1D1F", "3A3A3C"]),
        stickers: [Sticker] = [],
        photos: [PhotoElement] = [],
        texts: [TextElement] = [],
        verticalAlign: VerticalAlign = .top,
        fontWeight: Weight = .bold,
        gradientDirection: GradientDirection = .topLeading,
        textScrim: Bool = false,
        lineSpacing: Double = 0
    ) {
        self.text = text
        self.fontStyle = fontStyle
        self.fontSize = fontSize
        self.textColorHex = textColorHex
        self.alignment = alignment
        self.background = background
        self.stickers = stickers
        self.photos = photos
        self.texts = texts
        self.verticalAlign = verticalAlign
        self.fontWeight = fontWeight
        self.gradientDirection = gradientDirection
        self.textScrim = textScrim
        self.lineSpacing = lineSpacing
    }

    // Custom decoding so older saved payloads (which lack the newer keys)
    // still open in the editor instead of failing to decode.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = try c.decode(String.self, forKey: .text)
        fontStyle = try c.decode(FontStyle.self, forKey: .fontStyle)
        fontSize = try c.decode(Double.self, forKey: .fontSize)
        textColorHex = try c.decode(String.self, forKey: .textColorHex)
        alignment = try c.decode(TextAlign.self, forKey: .alignment)
        background = try c.decode(Background.self, forKey: .background)
        stickers = try c.decodeIfPresent([Sticker].self, forKey: .stickers) ?? []
        photos = try c.decodeIfPresent([PhotoElement].self, forKey: .photos) ?? []

        verticalAlign = try c.decodeIfPresent(VerticalAlign.self, forKey: .verticalAlign) ?? .top
        fontWeight = try c.decodeIfPresent(Weight.self, forKey: .fontWeight) ?? .bold
        gradientDirection = try c.decodeIfPresent(GradientDirection.self, forKey: .gradientDirection) ?? .topLeading
        textScrim = try c.decodeIfPresent(Bool.self, forKey: .textScrim) ?? false
        lineSpacing = try c.decodeIfPresent(Double.self, forKey: .lineSpacing) ?? 0

        // Designs saved before text became placeable have a single `text` and
        // no `texts`. Lift it into an element so nobody's widget loses its
        // words, keeping roughly the position it had. Runs last because it
        // reads the fields decoded above.
        if let stored = try c.decodeIfPresent([TextElement].self, forKey: .texts) {
            texts = stored
        } else if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let verticalPosition: Double = switch verticalAlign {
            case .top: 0.24
            case .middle: 0.5
            case .bottom: 0.76
            }
            let horizontalPosition: Double = switch alignment {
            case .leading: 0.34
            case .center: 0.5
            case .trailing: 0.66
            }
            texts = [TextElement(
                text: text,
                fontStyle: fontStyle,
                fontWeight: fontWeight,
                fontSize: fontSize,
                colorHex: textColorHex,
                alignment: alignment,
                lineSpacing: lineSpacing,
                x: horizontalPosition,
                y: verticalPosition
            )]
        } else {
            texts = []
        }
    }

    enum VerticalAlign: String, Codable, CaseIterable, Sendable, Identifiable {
        case top, middle, bottom
        var id: String { rawValue }
        var symbolName: String {
            switch self {
            case .top: "arrow.up.to.line"
            case .middle: "arrow.up.and.down"
            case .bottom: "arrow.down.to.line"
            }
        }
    }

    enum Weight: String, Codable, CaseIterable, Sendable, Identifiable {
        case regular, semibold, bold, heavy
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .regular: "Light"
            case .semibold: "Medium"
            case .bold: "Bold"
            case .heavy: "Heavy"
            }
        }
        var swiftUI: Font.Weight {
            switch self {
            case .regular: .regular
            case .semibold: .semibold
            case .bold: .bold
            case .heavy: .heavy
            }
        }
    }

    enum GradientDirection: String, Codable, CaseIterable, Sendable, Identifiable {
        case topLeading, top, topTrailing, leading
        var id: String { rawValue }
        var symbolName: String {
            switch self {
            case .topLeading: "arrow.down.right"
            case .top: "arrow.down"
            case .topTrailing: "arrow.down.left"
            case .leading: "arrow.right"
            }
        }
        var points: (start: UnitPoint, end: UnitPoint) {
            switch self {
            case .topLeading: (.topLeading, .bottomTrailing)
            case .top: (.top, .bottom)
            case .topTrailing: (.topTrailing, .bottomLeading)
            case .leading: (.leading, .trailing)
            }
        }
    }

    enum FontStyle: String, Codable, CaseIterable, Sendable, Identifiable {
        case serif, rounded, monospaced, standard
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .serif: "Serif"
            case .rounded: "Rounded"
            case .monospaced: "Mono"
            case .standard: "Sans"
            }
        }
    }

    enum TextAlign: String, Codable, CaseIterable, Sendable, Identifiable {
        case leading, center, trailing
        var id: String { rawValue }
        var symbolName: String {
            switch self {
            case .leading: "text.alignleft"
            case .center: "text.aligncenter"
            case .trailing: "text.alignright"
            }
        }
    }

    /// A background is either a colour gradient or a user photo.
    enum Background: Codable, Hashable, Sendable {
        case color([String])
        case photo(Data)

        var isPhoto: Bool { if case .photo = self { return true }; return false }
    }

    /// A block of text the user has placed on the canvas: moved, sized, and
    /// optionally sitting on its own tinted plate.
    struct TextElement: Codable, Hashable, Sendable, Identifiable {
        var id: UUID = UUID()
        var text: String
        var fontStyle: FontStyle = .serif
        var fontWeight: Weight = .bold
        /// Point size at the reference canvas width; scales with the widget.
        var fontSize: Double = 22
        var colorHex: String = "FFFFFF"
        var alignment: TextAlign = .center
        var lineSpacing: Double = 0
        var x: Double = 0.5          // normalized centre within the canvas
        var y: Double = 0.5
        var rotation: Double = 0     // degrees
        /// Max width as a fraction of the canvas, so long text wraps instead of
        /// running off the edge.
        var widthFraction: Double = 0.8

        // The plate behind the text. Off by default — most designs don't want
        // it, but it's the difference between readable and lost on busy art.
        var hasBackground: Bool = false
        var backgroundHex: String = "1D1D1F"
        var backgroundOpacity: Double = 0.5
        var backgroundCornerRadius: Double = 10
        var backgroundPadding: Double = 8

        init(
            id: UUID = UUID(),
            text: String,
            fontStyle: FontStyle = .serif,
            fontWeight: Weight = .bold,
            fontSize: Double = 22,
            colorHex: String = "FFFFFF",
            alignment: TextAlign = .center,
            lineSpacing: Double = 0,
            x: Double = 0.5,
            y: Double = 0.5,
            rotation: Double = 0,
            widthFraction: Double = 0.8,
            hasBackground: Bool = false,
            backgroundHex: String = "1D1D1F",
            backgroundOpacity: Double = 0.5,
            backgroundCornerRadius: Double = 10,
            backgroundPadding: Double = 8
        ) {
            self.id = id
            self.text = text
            self.fontStyle = fontStyle
            self.fontWeight = fontWeight
            self.fontSize = fontSize
            self.colorHex = colorHex
            self.alignment = alignment
            self.lineSpacing = lineSpacing
            self.x = x
            self.y = y
            self.rotation = rotation
            self.widthFraction = widthFraction
            self.hasBackground = hasBackground
            self.backgroundHex = backgroundHex
            self.backgroundOpacity = backgroundOpacity
            self.backgroundCornerRadius = backgroundCornerRadius
            self.backgroundPadding = backgroundPadding
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
            text = try c.decode(String.self, forKey: .text)
            fontStyle = try c.decodeIfPresent(FontStyle.self, forKey: .fontStyle) ?? .serif
            fontWeight = try c.decodeIfPresent(Weight.self, forKey: .fontWeight) ?? .bold
            fontSize = try c.decodeIfPresent(Double.self, forKey: .fontSize) ?? 22
            colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex) ?? "FFFFFF"
            alignment = try c.decodeIfPresent(TextAlign.self, forKey: .alignment) ?? .center
            lineSpacing = try c.decodeIfPresent(Double.self, forKey: .lineSpacing) ?? 0
            x = try c.decodeIfPresent(Double.self, forKey: .x) ?? 0.5
            y = try c.decodeIfPresent(Double.self, forKey: .y) ?? 0.5
            rotation = try c.decodeIfPresent(Double.self, forKey: .rotation) ?? 0
            widthFraction = try c.decodeIfPresent(Double.self, forKey: .widthFraction) ?? 0.8
            hasBackground = try c.decodeIfPresent(Bool.self, forKey: .hasBackground) ?? false
            backgroundHex = try c.decodeIfPresent(String.self, forKey: .backgroundHex) ?? "1D1D1F"
            backgroundOpacity = try c.decodeIfPresent(Double.self, forKey: .backgroundOpacity) ?? 0.5
            backgroundCornerRadius = try c.decodeIfPresent(Double.self, forKey: .backgroundCornerRadius) ?? 10
            backgroundPadding = try c.decodeIfPresent(Double.self, forKey: .backgroundPadding) ?? 8
        }
    }

    /// A photo the user has placed on the canvas and can move, resize and
    /// rotate — as opposed to `background: .photo`, which fills the widget.
    ///
    /// Note on size: several photos can live in one design, and the whole
    /// payload has to fit in the widget extension's ~30MB budget, so each one
    /// is downscaled hard on the way in (see `PhotoElement.maxPixelSize`).
    struct PhotoElement: Codable, Hashable, Sendable, Identifiable {
        /// The longest edge we keep for a placed photo. Small on purpose:
        /// these are rendered at a fraction of the widget's width.
        static let maxPixelSize: CGFloat = 500

        var id: UUID = UUID()
        var imageData: Data
        var x: Double = 0.5          // normalized centre within the canvas
        var y: Double = 0.5
        /// Width as a fraction of the canvas width, before aspect fitting.
        var scale: Double = 0.45
        var rotation: Double = 0     // degrees
        var cornerRadius: Double = 12
        var opacity: Double = 1.0

        init(
            id: UUID = UUID(),
            imageData: Data,
            x: Double = 0.5,
            y: Double = 0.5,
            scale: Double = 0.45,
            rotation: Double = 0,
            cornerRadius: Double = 12,
            opacity: Double = 1.0
        ) {
            self.id = id
            self.imageData = imageData
            self.x = x
            self.y = y
            self.scale = scale
            self.rotation = rotation
            self.cornerRadius = cornerRadius
            self.opacity = opacity
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
            imageData = try c.decode(Data.self, forKey: .imageData)
            x = try c.decodeIfPresent(Double.self, forKey: .x) ?? 0.5
            y = try c.decodeIfPresent(Double.self, forKey: .y) ?? 0.5
            scale = try c.decodeIfPresent(Double.self, forKey: .scale) ?? 0.45
            rotation = try c.decodeIfPresent(Double.self, forKey: .rotation) ?? 0
            cornerRadius = try c.decodeIfPresent(Double.self, forKey: .cornerRadius) ?? 12
            opacity = try c.decodeIfPresent(Double.self, forKey: .opacity) ?? 1
        }
    }

    struct Sticker: Codable, Hashable, Sendable, Identifiable {
        var id: UUID = UUID()
        /// The SF Symbol drawn when `emoji` is nil.
        var symbolName: String
        /// An emoji character, when the sticker is one.
        ///
        /// Emoji and symbols are genuinely different things here: symbols are
        /// monochrome glyphs we tint with `colorHex`, emoji are Apple's own
        /// multicolour artwork and can't be recoloured — so the editor hides
        /// the colour picker for them rather than offering a control that
        /// silently does nothing.
        var emoji: String?
        /// A cut-out image sticker: made from the user's own photo, pasted
        /// from the clipboard, or dropped onto the canvas. Transparent PNG.
        var imageData: Data?
        var x: Double = 0.5          // normalized 0...1 within the canvas
        var y: Double = 0.5
        var scale: Double = 1.0
        var colorHex: String = "FFFFFF"
        var rotation: Double = 0     // degrees
        var opacity: Double = 1.0

        var isEmoji: Bool { emoji != nil }
        var isImage: Bool { imageData != nil }
        /// Only monochrome symbols can be tinted; emoji and photo cut-outs
        /// carry their own colours.
        var isTintable: Bool { emoji == nil && imageData == nil }

        init(
            id: UUID = UUID(),
            symbolName: String = "star.fill",
            emoji: String? = nil,
            imageData: Data? = nil,
            x: Double = 0.5,
            y: Double = 0.5,
            scale: Double = 1.0,
            colorHex: String = "FFFFFF",
            rotation: Double = 0,
            opacity: Double = 1.0
        ) {
            self.id = id
            self.symbolName = symbolName
            self.emoji = emoji
            self.imageData = imageData
            self.x = x
            self.y = y
            self.scale = scale
            self.colorHex = colorHex
            self.rotation = rotation
            self.opacity = opacity
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
            symbolName = try c.decodeIfPresent(String.self, forKey: .symbolName) ?? "star.fill"
            emoji = try c.decodeIfPresent(String.self, forKey: .emoji)
            imageData = try c.decodeIfPresent(Data.self, forKey: .imageData)
            x = try c.decodeIfPresent(Double.self, forKey: .x) ?? 0.5
            y = try c.decodeIfPresent(Double.self, forKey: .y) ?? 0.5
            scale = try c.decodeIfPresent(Double.self, forKey: .scale) ?? 1
            colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex) ?? "FFFFFF"
            rotation = try c.decodeIfPresent(Double.self, forKey: .rotation) ?? 0
            opacity = try c.decodeIfPresent(Double.self, forKey: .opacity) ?? 1
        }
    }
}

// MARK: - SwiftUI helpers

extension WidgetContent.FontStyle {
    func font(size: CGFloat, weight: WidgetContent.Weight = .bold) -> Font {
        let w = weight.swiftUI
        switch self {
        case .serif:      return AppFont.serif(size: size, weight: w)
        case .rounded:    return .system(size: size, weight: w, design: .rounded)
        case .monospaced: return .system(size: size, weight: w, design: .monospaced)
        case .standard:   return .system(size: size, weight: w, design: .default)
        }
    }
}

extension WidgetContent {
    /// Combined horizontal + vertical placement for the text block.
    var textAlignment2D: Alignment {
        switch (verticalAlign, alignment) {
        case (.top, .leading): .topLeading
        case (.top, .center): .top
        case (.top, .trailing): .topTrailing
        case (.middle, .leading): .leading
        case (.middle, .center): .center
        case (.middle, .trailing): .trailing
        case (.bottom, .leading): .bottomLeading
        case (.bottom, .center): .bottom
        case (.bottom, .trailing): .bottomTrailing
        }
    }
}

extension WidgetContent.TextAlign {
    var frameAlignment: Alignment {
        switch self {
        case .leading: .topLeading
        case .center: .top
        case .trailing: .topTrailing
        }
    }
    var textAlignment: TextAlignment {
        switch self {
        case .leading: .leading
        case .center: .center
        case .trailing: .trailing
        }
    }
}

extension WidgetContent.Background {
    @ViewBuilder
    func view(direction: WidgetContent.GradientDirection = .topLeading) -> some View {
        switch self {
        case let .color(hexes):
            LinearGradient(
                colors: (hexes.isEmpty ? ["1D1D1F"] : hexes).map(Color.init(hex:)),
                startPoint: direction.points.start,
                endPoint: direction.points.end
            )
        case let .photo(data):
            #if canImport(UIKit)
            if let image = UIImage(data: data) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Color(hex: "1D1D1F")
            }
            #else
            Color(hex: "1D1D1F")
            #endif
        }
    }
}
