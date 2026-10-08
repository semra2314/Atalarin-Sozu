package com.example.kare.core.data.catalog

import com.example.kare.core.data.serialization.frozen
import com.example.kare.core.model.CatalogSection
import com.example.kare.core.model.Review
import com.example.kare.core.model.WidgetCategory
import com.example.kare.core.model.WidgetTemplate
import com.example.kare.core.repository.RepositoryException
import com.example.kare.core.repository.WidgetRepository
import java.io.IOException
import java.util.Locale
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerializationException

/** Shipping local-catalog behavior, without the iOS mock's artificial delay or review write fallback. */
class BundledWidgetRepository(
    private val source: LocalCatalogDataSource = LocalCatalogDataSource(),
    /** Catalog merchandising only; this is not a purchase entitlement. */
    private val includePaidSection: Boolean = true,
    private val computationDispatcher: CoroutineDispatcher = Dispatchers.Default,
) : WidgetRepository {
    override suspend fun discoverSections(): List<CatalogSection> = read { catalog ->
        frozen(catalog.sections.filter {
            it.templates.isNotEmpty() && (it.id != "plus" || (includePaidSection && catalog.subscriptionsAreLive))
        })
    }

    override suspend fun template(id: String): WidgetTemplate = read { catalog ->
        catalog.templates.firstOrNull { it.id == id } ?: throw RepositoryException.NotFound(id)
    }

    override suspend fun search(query: String, category: WidgetCategory?): List<WidgetTemplate> = read { catalog ->
        val term = query.trim().lowercase(Locale.ROOT)
        frozen(catalog.templates.filter { template ->
            (category == null || template.category == category) && (
                term.isEmpty() || template.name.matches(term) || template.summary.matches(term) ||
                    template.author.displayName.matches(term) || template.tags.any { it.matches(term) }
                )
        })
    }

    override suspend fun templates(category: WidgetCategory): List<WidgetTemplate> = read { catalog ->
        frozen(catalog.templates.filter { it.category == category })
    }

    override suspend fun reviews(templateId: String): List<Review> {
        currentCoroutineContext().ensureActive()
        throw RepositoryException.Unavailable("reviews")
    }

    override suspend fun submitReview(review: Review) {
        currentCoroutineContext().ensureActive()
        throw RepositoryException.Unavailable("submitReview")
    }

    private suspend fun <T> read(operation: (LocalCatalog) -> T): T = withContext(computationDispatcher) {
        val catalog = try {
            source.load()
        } catch (error: SerializationException) {
            throw RepositoryException.InvalidData("bundled catalog").also { it.addSuppressed(error) }
        } catch (error: IOException) {
            throw RepositoryException.Persistence(error)
        }
        currentCoroutineContext().ensureActive()
        operation(catalog)
    }

    private fun String.matches(term: String): Boolean = lowercase(Locale.ROOT).contains(term)
}
