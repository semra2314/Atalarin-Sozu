package com.example.kare.core.data.serialization

import com.example.kare.core.model.*
import kotlinx.serialization.json.*

object AuthorSerializer : JsonModelSerializer<Author>("Author") {
    override fun fromJson(value: JsonElement): Author = value.objectValue().let {
        Author(it.string("id"), it.string("displayName"), it.string("handle"),
            it.optional("avatarURL")?.stringValue(), it.required("isVerified").booleanValue())
    }

    override fun toJson(value: Author): JsonElement = buildJsonObject {
        put("id", value.id)
        put("displayName", value.displayName)
        put("handle", value.handle)
        optional("avatarURL", value.avatarUrl)
        put("isVerified", value.isVerified)
    }
}

object WidgetThemeSerializer : JsonModelSerializer<WidgetTheme>("WidgetTheme") {
    override fun fromJson(value: JsonElement): WidgetTheme = value.objectValue().let {
        WidgetTheme(
            backgroundHexes = it.required("backgroundHexes").arrayValues { hex -> hex.stringValue() },
            foregroundHex = it.string("foregroundHex"),
            accentHex = it.string("accentHex"),
            cornerRadius = it.required("cornerRadius").doubleValue(),
            usesGlassEffect = it.required("usesGlassEffect").booleanValue(),
        )
    }

    override fun toJson(value: WidgetTheme): JsonElement = buildJsonObject {
        put("backgroundHexes", strings(value.backgroundHexes))
        put("foregroundHex", value.foregroundHex)
        put("accentHex", value.accentHex)
        put("cornerRadius", number(value.cornerRadius))
        put("usesGlassEffect", value.usesGlassEffect)
    }
}

object WidgetTemplateSerializer : JsonModelSerializer<WidgetTemplate>("WidgetTemplate") {
    override fun fromJson(value: JsonElement): WidgetTemplate {
        val o = value.objectValue()
        return WidgetTemplate(
            id = o.string("id"),
            name = o.string("name"),
            summary = o.string("summary"),
            author = AuthorSerializer.fromJson(o.required("author")),
            category = rawEnum(o.string("category"), WidgetCategory.entries) { it.rawValue },
            supportedSizes = o.required("supportedSizes").arrayValues {
                rawEnum(it.stringValue(), WidgetSize.entries) { size -> size.rawValue }
            },
            theme = WidgetThemeSerializer.fromJson(o.required("theme")),
            tags = o.required("tags").arrayValues { it.stringValue() },
            installCount = o.required("installCount").intValue(),
            rating = o.required("rating").doubleValue(),
            ratingCount = o.required("ratingCount").intValue(),
            price = WidgetPriceSerializer.fromJson(o.required("price")),
            publishedAt = instantFromJson(o.required("publishedAt")),
            content = o.optional("content")?.let(WidgetContentSerializer::fromJson),
            previewImageName = o.optional("previewImageName")?.stringValue(),
            sizePreviewBaseName = o.optional("sizePreviewBaseName")?.stringValue(),
            galleryName = o.optional("galleryName")?.stringValue(),
            isEditable = o.required("isEditable").booleanValue(),
        )
    }

    override fun toJson(value: WidgetTemplate): JsonElement = buildJsonObject {
        put("id", value.id)
        put("name", value.name)
        put("summary", value.summary)
        put("author", AuthorSerializer.toJson(value.author))
        put("category", value.category.rawValue)
        put("supportedSizes", strings(value.supportedSizes.map { it.rawValue }))
        put("theme", WidgetThemeSerializer.toJson(value.theme))
        put("tags", strings(value.tags))
        put("installCount", value.installCount)
        put("rating", number(value.rating))
        put("ratingCount", value.ratingCount)
        put("price", WidgetPriceSerializer.toJson(value.price))
        put("publishedAt", instantToJson(value.publishedAt))
        value.content?.let { put("content", WidgetContentSerializer.toJson(it)) }
        optional("previewImageName", value.previewImageName)
        optional("sizePreviewBaseName", value.sizePreviewBaseName)
        optional("galleryName", value.galleryName)
        put("isEditable", value.isEditable)
    }
}

/** Swift Codable review shape, not the Firestore document shape (which uses uid/Timestamp). */
object ReviewSerializer : JsonModelSerializer<Review>("Review") {
    override fun fromJson(value: JsonElement): Review = value.objectValue().let {
        val stars = it.required("stars").intValue()
        if (stars !in 1..5) invalid("stars")
        Review(
            id = it.string("id"),
            templateId = it.string("templateID"),
            authorName = it.string("authorName"),
            authorId = it.optional("authorID")?.stringValue(),
            stars = stars,
            text = it.string("text"),
            createdAt = instantFromJson(it.required("createdAt")),
        )
    }

    override fun toJson(value: Review): JsonElement = buildJsonObject {
        put("id", value.id)
        put("templateID", value.templateId)
        put("authorName", value.authorName)
        optional("authorID", value.authorId)
        put("stars", value.stars)
        put("text", value.text)
        put("createdAt", instantToJson(value.createdAt))
    }
}

/** Android resolved-section representation; iOS CatalogSection itself is not Codable. */
object CatalogSectionSerializer : JsonModelSerializer<CatalogSection>("CatalogSection") {
    override fun fromJson(value: JsonElement): CatalogSection = value.objectValue().let {
        CatalogSection(
            id = it.string("id"),
            title = it.string("title"),
            subtitle = it.optional("subtitle")?.stringValue(),
            style = rawEnum(it.string("style"), CatalogSection.Style.entries) { style -> style.rawValue },
            templates = it.required("templates").arrayValues(WidgetTemplateSerializer::fromJson),
        )
    }

    override fun toJson(value: CatalogSection): JsonElement = buildJsonObject {
        put("id", value.id)
        put("title", value.title)
        optional("subtitle", value.subtitle)
        put("style", value.style.rawValue)
        put("templates", JsonArray(value.templates.map(WidgetTemplateSerializer::toJson)))
    }
}
