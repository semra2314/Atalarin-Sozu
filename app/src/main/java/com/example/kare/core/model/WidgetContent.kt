package com.example.kare.core.model

import java.util.UUID

/**
 * Editor payload values, independent of a renderer or persistence format.
 * Positions are normalized canvas coordinates; rotations are degrees.
 * Legacy JSON decoding must lift missing `texts` from `text`; see the migration document.
 */
data class WidgetContent(
    val text: String = "Your text",
    val fontStyle: FontStyle = FontStyle.SERIF,
    val fontSize: Double = 22.0,
    val textColorHex: String = "FFFFFF",
    val alignment: TextAlign = TextAlign.LEADING,
    val background: Background = Background.Color(listOf("1D1D1F", "3A3A3C")),
    val stickers: List<Sticker> = emptyList(),
    val photos: List<PhotoElement> = emptyList(),
    val texts: List<TextElement> = emptyList(),
    val verticalAlign: VerticalAlign = VerticalAlign.TOP,
    val fontWeight: Weight = Weight.BOLD,
    val gradientDirection: GradientDirection = GradientDirection.TOP_LEADING,
    val textScrim: Boolean = false,
    val lineSpacing: Double = 0.0,
) {
    enum class VerticalAlign(val rawValue: String) {
        TOP("top"), MIDDLE("middle"), BOTTOM("bottom"),
    }

    enum class Weight(val rawValue: String) {
        REGULAR("regular"), SEMIBOLD("semibold"), BOLD("bold"), HEAVY("heavy"),
    }

    enum class GradientDirection(val rawValue: String) {
        TOP_LEADING("topLeading"), TOP("top"), TOP_TRAILING("topTrailing"), LEADING("leading"),
    }

    enum class FontStyle(val rawValue: String) {
        SERIF("serif"), ROUNDED("rounded"), MONOSPACED("monospaced"), STANDARD("standard"),
    }

    enum class TextAlign(val rawValue: String) {
        LEADING("leading"), CENTER("center"), TRAILING("trailing"),
    }

    sealed interface Background {
        data class Color(val hexes: List<String>) : Background
        data class Photo(val imageData: ImageData) : Background
    }

    data class TextElement(
        val text: String,
        val id: UUID = UUID.randomUUID(),
        val fontStyle: FontStyle = FontStyle.SERIF,
        val fontWeight: Weight = Weight.BOLD,
        val fontSize: Double = 22.0,
        val colorHex: String = "FFFFFF",
        val alignment: TextAlign = TextAlign.CENTER,
        val lineSpacing: Double = 0.0,
        val x: Double = 0.5,
        val y: Double = 0.5,
        val rotation: Double = 0.0,
        val widthFraction: Double = 0.8,
        val hasBackground: Boolean = false,
        val backgroundHex: String = "1D1D1F",
        val backgroundOpacity: Double = 0.5,
        val backgroundCornerRadius: Double = 10.0,
        val backgroundPadding: Double = 8.0,
    )

    data class PhotoElement(
        val imageData: ImageData,
        val id: UUID = UUID.randomUUID(),
        val x: Double = 0.5,
        val y: Double = 0.5,
        val scale: Double = 0.45,
        val rotation: Double = 0.0,
        val cornerRadius: Double = 12.0,
        val opacity: Double = 1.0,
    )

    data class Sticker(
        val id: UUID = UUID.randomUUID(),
        /** Retained source identifier. Android must map it to an available drawable. */
        val symbolName: String = "star.fill",
        val emoji: String? = null,
        val imageData: ImageData? = null,
        val x: Double = 0.5,
        val y: Double = 0.5,
        val scale: Double = 1.0,
        val colorHex: String = "FFFFFF",
        val rotation: Double = 0.0,
        val opacity: Double = 1.0,
    ) {
        val isEmoji: Boolean get() = emoji != null
        val isImage: Boolean get() = imageData != null
        val isTintable: Boolean get() = emoji == null && imageData == null
    }
}
