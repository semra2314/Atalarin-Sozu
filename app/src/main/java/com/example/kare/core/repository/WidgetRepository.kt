package com.example.kare.core.repository

import com.example.kare.core.model.CatalogSection
import com.example.kare.core.model.Review
import com.example.kare.core.model.WidgetCategory
import com.example.kare.core.model.WidgetTemplate

/**
 * Catalog contract matching the iOS WidgetRepository. All methods must be main-safe.
 * Implementations map infrastructure failures to [RepositoryException] and propagate
 * coroutine cancellation unchanged. No SDK types cross this boundary.
 */
interface WidgetRepository {
    /** Preserve curated section and template order; omit empty shelves. */
    suspend fun discoverSections(): List<CatalogSection>

    /** Throws [RepositoryException.NotFound] when the template does not exist. */
    suspend fun template(id: String): WidgetTemplate

    /**
     * Trim the query, match name/summary/tags/author without case sensitivity, and intersect
     * with the optional category. An empty query returns all templates in catalog order.
     */
    suspend fun search(query: String, category: WidgetCategory? = null): List<WidgetTemplate>

    suspend fun templates(category: WidgetCategory): List<WidgetTemplate>

    /** Visible reviews for a template, newest first. */
    suspend fun reviews(templateId: String): List<Review>

    /**
     * Post or replace the signed-in user's review of this template. Do not trust the supplied
     * authorId or createdAt for authorization or the server's creation timestamp.
     */
    suspend fun submitReview(review: Review)
}
