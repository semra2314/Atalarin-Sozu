package com.example.kare.core.data.library

import com.example.kare.core.database.InstalledWidgetEntity
import com.example.kare.core.data.serialization.CatalogJson
import com.example.kare.core.data.serialization.WidgetContentSerializer
import com.example.kare.core.data.serialization.WidgetThemeSerializer
import com.example.kare.core.model.InstalledWidget
import com.example.kare.core.model.WidgetCategory
import com.example.kare.core.model.WidgetSize
import com.example.kare.core.repository.RepositoryException
import java.time.Instant

/** Version 1 reuses the Swift-compatible theme/content codecs; SQL timestamps use Unix seconds/nanos. */
internal object InstalledWidgetMapper {
    fun toEntity(value: InstalledWidget): InstalledWidgetEntity {
        val theme = value.theme?.let { CatalogJson.encode(WidgetThemeSerializer, it) }
        val content = value.content?.let { CatalogJson.encode(WidgetContentSerializer, it) }
        val entity = InstalledWidgetEntity(
            value.templateId, value.name, value.authorName, value.category.rawValue, value.size.rawValue,
            theme, content, 1, value.addedAt.epochSecond, value.addedAt.nano,
            value.isFavorite, value.sortIndex, value.isCustomizable, value.previewImageName,
        )
        validate(entity)
        return entity
    }

    fun toDomain(value: InstalledWidgetEntity): InstalledWidget {
        validate(value)
        return InstalledWidget(
            templateId = value.templateId,
            name = value.name,
            authorName = value.authorName,
            category = WidgetCategory.entries.find { it.rawValue == value.categoryRaw } ?: invalid("category"),
            size = WidgetSize.entries.find { it.rawValue == value.sizeRaw } ?: invalid("size"),
            theme = value.themeJson?.let { CatalogJson.decode(WidgetThemeSerializer, it) },
            content = value.contentJson?.let { CatalogJson.decode(WidgetContentSerializer, it) },
            addedAt = Instant.ofEpochSecond(value.addedAtSeconds, value.addedAtNanos.toLong()),
            isFavorite = value.isFavorite,
            sortIndex = value.sortIndex,
            isCustomizable = value.isCustomizable,
            previewImageName = value.previewImageName,
        )
    }

    private fun validate(value: InstalledWidgetEntity) {
        if (value.templateId.isBlank()) invalid("templateId")
        if (value.payloadVersion != 1) invalid("payloadVersion")
        if (value.sortIndex < 0) invalid("sortIndex")
        if (value.addedAtNanos !in 0..999_999_999 ||
            value.addedAtSeconds !in Instant.MIN.epochSecond..Instant.MAX.epochSecond) invalid("addedAt")
        // Bound a row below Android cursor-window limits, including embedded base64 images.
        val bytes = listOfNotNull(value.templateId, value.name, value.authorName, value.categoryRaw,
            value.sizeRaw, value.themeJson, value.contentJson, value.previewImageName)
            .sumOf { it.toByteArray(Charsets.UTF_8).size.toLong() }
        if (bytes > 512 * 1024) invalid("library payload exceeds 512 KiB")
    }

    private fun invalid(field: String): Nothing = throw RepositoryException.InvalidData(field)
}
