package com.example.kare.core.data.catalog

import com.example.kare.core.data.serialization.*
import com.example.kare.core.model.CatalogSection
import com.example.kare.core.model.WidgetTemplate
import java.io.IOException
import java.util.Collections
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json

/** Immutable, resolved snapshot; this data-layer type never replaces WidgetRepository in a ViewModel. */
data class LocalCatalog(
    val templates: List<WidgetTemplate>,
    val sections: List<CatalogSection>,
    val setupTemplateIds: Set<String>,
    val liveKarePlusIds: List<String>,
    val subscriptionsAreLive: Boolean,
)

/**
 * Loads the packaged Swift-exported resource without Android Context or network access.
 * I/O and decoding run off the caller thread. Only successfully validated data is cached.
 */
class LocalCatalogDataSource(
    private val readCatalog: () -> String = {
        val stream = LocalCatalogDataSource::class.java.getResourceAsStream("/catalog/kare-catalog-v1.json")
            ?: throw IOException("Bundled Kare catalog resource is missing")
        stream.bufferedReader(Charsets.UTF_8).use { it.readText() }
    },
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) {
    private val mutex = Mutex()
    private var cached: LocalCatalog? = null

    suspend fun load(): LocalCatalog = withContext(ioDispatcher) {
        mutex.withLock {
            cached ?: decodeCatalog(readCatalog()).also { cached = it }
        }
    }

    private fun decodeCatalog(source: String): LocalCatalog {
        val root = Json.parseToJsonElement(source).objectValue()
        if (root.required("schemaVersion").intValue() != 1) invalid("catalog schemaVersion")
        val templates = root.required("templates").arrayValues(WidgetTemplateSerializer::fromJson)
        unique(templates.map { it.id }, "template IDs")
        for (template in templates) {
            if (template.supportedSizes.isEmpty() || template.supportedSizes.distinct().size != template.supportedSizes.size) {
                invalid("supportedSizes for ${template.id}")
            }
            if (template.installCount < 0 || template.ratingCount < 0 || template.rating !in 0.0..5.0) {
                invalid("catalog statistics for ${template.id}")
            }
            val price = template.price
            if (price is WidgetTemplate.Price.Paid && (price.amount.signum() < 0 || price.currencyCode.isBlank())) {
                invalid("catalog price for ${template.id}")
            }
        }
        val byId = templates.associateBy { it.id }
        fun ids(field: String): List<String> = root.required(field).arrayValues { it.stringValue() }.also { values ->
            unique(values, field)
            if (values.any { it !in byId }) invalid(field)
        }
        val sections = root.required("sections").arrayValues { value ->
            val section = value.objectValue()
            val templateIds = section.required("templateIds").arrayValues { it.stringValue() }
            unique(templateIds, "section template IDs")
            CatalogSection(
                id = section.string("id"),
                title = section.string("title"),
                subtitle = section.optional("subtitle")?.stringValue(),
                style = rawEnum(section.string("style"), CatalogSection.Style.entries) { it.rawValue },
                templates = frozen(templateIds.map { byId[it] ?: invalid("section template ID: $it") }),
            )
        }
        unique(sections.map { it.id }, "section IDs")
        return LocalCatalog(
            templates = templates,
            sections = sections,
            setupTemplateIds = Collections.unmodifiableSet(LinkedHashSet(ids("setupTemplateIds"))),
            liveKarePlusIds = ids("liveKarePlusIds"),
            subscriptionsAreLive = root.required("subscriptionsAreLive").booleanValue(),
        )
    }

    private fun unique(values: List<String>, field: String) {
        if (values.any { it.isBlank() } || values.distinct().size != values.size) invalid(field)
    }
}
