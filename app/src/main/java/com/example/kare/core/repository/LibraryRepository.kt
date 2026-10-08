package com.example.kare.core.repository

import com.example.kare.core.model.InstalledWidget
import com.example.kare.core.model.WidgetContent
import com.example.kare.core.model.WidgetSize
import com.example.kare.core.model.WidgetTemplate
import kotlinx.coroutines.flow.Flow

/**
 * Local library boundary replacing direct SwiftData queries and LibraryStore writes.
 * Methods are main-safe, persistence failures must be surfaced, and cancellation propagated.
 * Emits committed snapshots ordered by sortIndex; an empty library is a valid snapshot.
 */
interface LibraryRepository {
    fun observeWidgets(): Flow<List<InstalledWidget>>

    suspend fun widget(templateId: String): InstalledWidget?

    /**
     * Add at most one entry per template, seeding its theme/content and editability from
     * the catalog. If already present, return it without overwriting the user's changes.
     * Library membership does not place a widget on the launcher or grant paid access.
     */
    suspend fun install(template: WidgetTemplate, size: WidgetSize): InstalledWidget

    /** Return the removed snapshot for optional feedback; return null when already absent. */
    suspend fun remove(templateId: String): InstalledWidget?

    /** Idempotent desired state, avoiding a retry accidentally toggling twice. */
    suspend fun setFavorite(templateId: String, isFavorite: Boolean)

    /** Save only editable designs; fixed-design setup uses separate future feature contracts. */
    suspend fun updateContent(templateId: String, content: WidgetContent)

    /**
     * Atomically reorder the entire library. Reject duplicates, unknown IDs, or missing IDs;
     * the caller must refresh and retry if membership changed concurrently.
     */
    suspend fun reorder(templateIds: List<String>)
}
