package com.example.kare.presentation

import com.example.kare.core.model.*
import com.example.kare.core.repository.*
import java.time.Instant
import kotlinx.coroutines.flow.*

internal val template = WidgetTemplate("test", "Test", "Summary", Author("a", "Author", "author"),
    WidgetCategory.MINIMAL, listOf(WidgetSize.SMALL), WidgetTheme(listOf("000000")), emptyList(),
    0, 0.0, 0, WidgetTemplate.Price.Free, Instant.EPOCH, isEditable = true)
internal val section = CatalogSection("all", "All", CatalogSection.Style.CAROUSEL, listOf(template))
internal fun installed(id: String = template.id) = InstalledWidget(id, "Test", "Author", WidgetCategory.MINIMAL, WidgetSize.SMALL)

internal class CatalogFake : WidgetRepository {
    var discover: suspend () -> List<CatalogSection> = { listOf(section) }
    var searchBlock: suspend (String, WidgetCategory?) -> List<WidgetTemplate> = { _, _ -> listOf(template) }
    val searches = mutableListOf<Pair<String, WidgetCategory?>>()
    override suspend fun discoverSections() = discover()
    override suspend fun search(query: String, category: WidgetCategory?): List<WidgetTemplate> {
        searches += query to category
        return searchBlock(query, category)
    }
    override suspend fun template(id: String) = if (id == template.id) template else throw RepositoryException.NotFound(id)
    override suspend fun templates(category: WidgetCategory) = search("", category)
    override suspend fun reviews(templateId: String) = emptyList<Review>()
    override suspend fun submitReview(review: Review) { error("Not part of ViewModel scope") }
}
internal class LibraryFake : LibraryRepository {
    val rows = MutableStateFlow<List<InstalledWidget>>(emptyList())
    var observationFailure: Exception? = null
    var mutation: suspend () -> Unit = {}
    override fun observeWidgets(): Flow<List<InstalledWidget>> = flow {
        observationFailure?.let { throw it }
        emitAll(rows)
    }
    override suspend fun widget(templateId: String) = rows.value.find { it.templateId == templateId }
    override suspend fun install(template: WidgetTemplate, size: WidgetSize): InstalledWidget {
        mutation()
        val saved = widget(template.id) ?: installed(template.id).copy(size = size)
        if (widget(template.id) == null) rows.value += saved
        return saved
    }
    override suspend fun remove(templateId: String): InstalledWidget? {
        mutation()
        val saved = widget(templateId)
        rows.value = rows.value.filterNot { it.templateId == templateId }
        return saved
    }
    override suspend fun setFavorite(templateId: String, isFavorite: Boolean) {
        mutation()
        rows.value = rows.value.map { if (it.templateId == templateId) it.copy(isFavorite = isFavorite) else it }
    }
    override suspend fun updateContent(templateId: String, content: WidgetContent) {
        mutation()
        rows.value = rows.value.map { if (it.templateId == templateId) it.copy(content = content) else it }
    }
    override suspend fun reorder(templateIds: List<String>) {
        mutation()
        rows.value = templateIds.mapIndexed { index, id -> rows.value.first { it.templateId == id }.copy(sortIndex = index) }
    }
}
