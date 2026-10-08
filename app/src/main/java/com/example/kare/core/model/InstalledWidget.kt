package com.example.kare.core.model

import java.time.Instant

/**
 * Offline library snapshot, not a Room entity or evidence of a home-screen widget placement.
 * A repository may refresh catalog metadata while preserving the user's content and ordering.
 */
data class InstalledWidget(
    val templateId: String,
    val name: String,
    val authorName: String,
    val category: WidgetCategory,
    val size: WidgetSize,
    val theme: WidgetTheme? = null,
    val content: WidgetContent? = null,
    val addedAt: Instant = Instant.now(),
    val isFavorite: Boolean = false,
    val sortIndex: Int = 0,
    val isCustomizable: Boolean = false,
    val previewImageName: String? = null,
)
