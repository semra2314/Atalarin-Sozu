package com.example.kare.core.data.serialization

import com.example.kare.core.model.WidgetContent
import java.util.Locale
import kotlinx.serialization.json.*

/** Preserves the complete editor payload and the legacy missing-texts migration. */
object WidgetContentSerializer : JsonModelSerializer<WidgetContent>("WidgetContent") {
    override fun fromJson(value: JsonElement): WidgetContent {
        val o = value.objectValue()
        val content = WidgetContent(
            text = o.string("text"),
            fontStyle = rawEnum(o.string("fontStyle"), WidgetContent.FontStyle.entries) { it.rawValue },
            fontSize = o.required("fontSize").doubleValue(),
            textColorHex = o.string("textColorHex"),
            alignment = rawEnum(o.string("alignment"), WidgetContent.TextAlign.entries) { it.rawValue },
            background = WidgetBackgroundSerializer.fromJson(o.required("background")),
            stickers = o.arrayOrEmpty("stickers", StickerSerializer::fromJson),
            photos = o.arrayOrEmpty("photos", PhotoElementSerializer::fromJson),
            texts = o.arrayOrEmpty("texts", TextElementSerializer::fromJson),
            verticalAlign = rawEnum(o.string("verticalAlign", "top"), WidgetContent.VerticalAlign.entries) { it.rawValue },
            fontWeight = rawEnum(o.string("fontWeight", "bold"), WidgetContent.Weight.entries) { it.rawValue },
            gradientDirection = rawEnum(o.string("gradientDirection", "topLeading"), WidgetContent.GradientDirection.entries) { it.rawValue },
            textScrim = o.boolean("textScrim", false),
            lineSpacing = o.double("lineSpacing", 0.0),
        )
        // An explicit empty array is intentional and must not resurrect deleted text.
        if (o.optional("texts") != null || content.text.isBlank()) return content
        val legacy = WidgetContent.TextElement(
            text = content.text,
            fontStyle = content.fontStyle,
            fontWeight = content.fontWeight,
            fontSize = content.fontSize,
            colorHex = content.textColorHex,
            alignment = content.alignment,
            lineSpacing = content.lineSpacing,
            x = when (content.alignment) {
                WidgetContent.TextAlign.LEADING -> 0.34
                WidgetContent.TextAlign.CENTER -> 0.5
                WidgetContent.TextAlign.TRAILING -> 0.66
            },
            y = when (content.verticalAlign) {
                WidgetContent.VerticalAlign.TOP -> 0.24
                WidgetContent.VerticalAlign.MIDDLE -> 0.5
                WidgetContent.VerticalAlign.BOTTOM -> 0.76
            },
        )
        return content.copy(texts = listOf(legacy))
    }

    override fun toJson(value: WidgetContent): JsonElement = buildJsonObject {
        put("text", value.text)
        put("fontStyle", value.fontStyle.rawValue)
        put("fontSize", number(value.fontSize))
        put("textColorHex", value.textColorHex)
        put("alignment", value.alignment.rawValue)
        put("background", WidgetBackgroundSerializer.toJson(value.background))
        put("stickers", JsonArray(value.stickers.map(StickerSerializer::toJson)))
        put("photos", JsonArray(value.photos.map(PhotoElementSerializer::toJson)))
        put("texts", JsonArray(value.texts.map(TextElementSerializer::toJson)))
        put("verticalAlign", value.verticalAlign.rawValue)
        put("fontWeight", value.fontWeight.rawValue)
        put("gradientDirection", value.gradientDirection.rawValue)
        put("textScrim", value.textScrim)
        put("lineSpacing", number(value.lineSpacing))
    }
}

internal object TextElementSerializer : JsonModelSerializer<WidgetContent.TextElement>("WidgetContent.TextElement") {
    override fun fromJson(value: JsonElement): WidgetContent.TextElement {
        val o = value.objectValue()
        return WidgetContent.TextElement(
            id = o.uuid("id"),
            text = o.string("text"),
            fontStyle = rawEnum(o.string("fontStyle", "serif"), WidgetContent.FontStyle.entries) { it.rawValue },
            fontWeight = rawEnum(o.string("fontWeight", "bold"), WidgetContent.Weight.entries) { it.rawValue },
            fontSize = o.double("fontSize", 22.0),
            colorHex = o.string("colorHex", "FFFFFF"),
            alignment = rawEnum(o.string("alignment", "center"), WidgetContent.TextAlign.entries) { it.rawValue },
            lineSpacing = o.double("lineSpacing", 0.0),
            x = o.double("x", 0.5),
            y = o.double("y", 0.5),
            rotation = o.double("rotation", 0.0),
            widthFraction = o.double("widthFraction", 0.8),
            hasBackground = o.boolean("hasBackground", false),
            backgroundHex = o.string("backgroundHex", "1D1D1F"),
            backgroundOpacity = o.double("backgroundOpacity", 0.5),
            backgroundCornerRadius = o.double("backgroundCornerRadius", 10.0),
            backgroundPadding = o.double("backgroundPadding", 8.0),
        )
    }

    override fun toJson(value: WidgetContent.TextElement): JsonElement = buildJsonObject {
        put("id", value.id.toString().uppercase(Locale.ROOT))
        put("text", value.text)
        put("fontStyle", value.fontStyle.rawValue)
        put("fontWeight", value.fontWeight.rawValue)
        put("fontSize", number(value.fontSize))
        put("colorHex", value.colorHex)
        put("alignment", value.alignment.rawValue)
        put("lineSpacing", number(value.lineSpacing))
        put("x", number(value.x))
        put("y", number(value.y))
        put("rotation", number(value.rotation))
        put("widthFraction", number(value.widthFraction))
        put("hasBackground", value.hasBackground)
        put("backgroundHex", value.backgroundHex)
        put("backgroundOpacity", number(value.backgroundOpacity))
        put("backgroundCornerRadius", number(value.backgroundCornerRadius))
        put("backgroundPadding", number(value.backgroundPadding))
    }
}

internal object PhotoElementSerializer : JsonModelSerializer<WidgetContent.PhotoElement>("WidgetContent.PhotoElement") {
    override fun fromJson(value: JsonElement): WidgetContent.PhotoElement {
        val o = value.objectValue()
        return WidgetContent.PhotoElement(
            id = o.uuid("id"),
            imageData = imageFromJson(o.required("imageData")),
            x = o.double("x", 0.5),
            y = o.double("y", 0.5),
            scale = o.double("scale", 0.45),
            rotation = o.double("rotation", 0.0),
            cornerRadius = o.double("cornerRadius", 12.0),
            opacity = o.double("opacity", 1.0),
        )
    }

    override fun toJson(value: WidgetContent.PhotoElement): JsonElement = buildJsonObject {
        put("id", value.id.toString().uppercase(Locale.ROOT))
        put("imageData", imageToJson(value.imageData))
        put("x", number(value.x))
        put("y", number(value.y))
        put("scale", number(value.scale))
        put("rotation", number(value.rotation))
        put("cornerRadius", number(value.cornerRadius))
        put("opacity", number(value.opacity))
    }
}

internal object StickerSerializer : JsonModelSerializer<WidgetContent.Sticker>("WidgetContent.Sticker") {
    override fun fromJson(value: JsonElement): WidgetContent.Sticker {
        val o = value.objectValue()
        return WidgetContent.Sticker(
            id = o.uuid("id"),
            symbolName = o.string("symbolName", "star.fill"),
            emoji = o.optional("emoji")?.stringValue(),
            imageData = o.optional("imageData")?.let(::imageFromJson),
            x = o.double("x", 0.5),
            y = o.double("y", 0.5),
            scale = o.double("scale", 1.0),
            colorHex = o.string("colorHex", "FFFFFF"),
            rotation = o.double("rotation", 0.0),
            opacity = o.double("opacity", 1.0),
        )
    }

    override fun toJson(value: WidgetContent.Sticker): JsonElement = buildJsonObject {
        put("id", value.id.toString().uppercase(Locale.ROOT))
        put("symbolName", value.symbolName)
        optional("emoji", value.emoji)
        value.imageData?.let { put("imageData", imageToJson(it)) }
        put("x", number(value.x))
        put("y", number(value.y))
        put("scale", number(value.scale))
        put("colorHex", value.colorHex)
        put("rotation", number(value.rotation))
        put("opacity", number(value.opacity))
    }
}
