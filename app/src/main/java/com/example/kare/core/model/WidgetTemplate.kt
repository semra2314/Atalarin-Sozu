package com.example.kare.core.model

import java.math.BigDecimal
import java.time.Instant

/** A bundled catalog item. Display formatting and purchase entitlements live elsewhere. */
data class WidgetTemplate(
    val id: String,
    val name: String,
    val summary: String,
    val author: Author,
    val category: WidgetCategory,
    val supportedSizes: List<WidgetSize>,
    val theme: WidgetTheme,
    val tags: List<String>,
    val installCount: Int,
    val rating: Double,
    val ratingCount: Int,
    val price: Price,
    val publishedAt: Instant,
    val content: WidgetContent? = null,
    val previewImageName: String? = null,
    val sizePreviewBaseName: String? = null,
    /** Source gallery label; Android widget setup must supply its own platform guidance. */
    val galleryName: String? = null,
    val isEditable: Boolean = false,
) {
    val primarySize: WidgetSize get() = supportedSizes.firstOrNull() ?: WidgetSize.SMALL

    sealed interface Price {
        data object Free : Price

        /** Catalog price metadata, never the authoritative checkout price. */
        data class Paid(val amount: BigDecimal, val currencyCode: String) : Price

        val isFree: Boolean get() = this is Free
    }
}
