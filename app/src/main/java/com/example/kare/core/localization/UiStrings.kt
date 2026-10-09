package com.example.kare.core.localization

import androidx.annotation.StringRes
import com.example.kare.R
import com.example.kare.core.model.WidgetCategory
import com.example.kare.core.presentation.UiError

/** UI boundary: call stringResource(error.stringResource()) from Compose, never a ViewModel. */
@StringRes
fun UiError.stringResource(): Int = when (this) {
    UiError.NOT_FOUND -> R.string.error_not_found
    UiError.UNAVAILABLE -> R.string.error_unavailable
    UiError.SIGN_IN_REQUIRED -> R.string.error_sign_in_required
    UiError.INVALID_DATA -> R.string.error_invalid_data
    UiError.CONNECTION -> R.string.error_connection
    UiError.STORAGE -> R.string.error_storage
    UiError.UNEXPECTED -> R.string.error_unexpected
}

@StringRes
fun WidgetCategory.stringResource(): Int = when (this) {
    WidgetCategory.PRODUCTIVITY -> R.string.category_productivity
    WidgetCategory.HEALTH -> R.string.category_health
    WidgetCategory.FINANCE -> R.string.category_finance
    WidgetCategory.WEATHER -> R.string.category_weather
    WidgetCategory.PHOTOS -> R.string.category_photos
    WidgetCategory.MINIMAL -> R.string.category_minimal
    WidgetCategory.SOCIAL -> R.string.category_social
    WidgetCategory.FUN -> R.string.category_fun
}

/** Only known bundled shelves are localized; future/remote copy must keep its own fallback. */
data class CatalogSectionStrings(@param:StringRes val title: Int, @param:StringRes val subtitle: Int?)
fun catalogSectionStrings(id: String): CatalogSectionStrings? = when (id) {
    "spotlight" -> CatalogSectionStrings(R.string.section_spotlight_title, R.string.section_spotlight_subtitle)
    "count" -> CatalogSectionStrings(R.string.section_count_title, R.string.section_count_subtitle)
    "all" -> CatalogSectionStrings(R.string.section_all_title, R.string.section_all_subtitle)
    "minimal" -> CatalogSectionStrings(R.string.section_minimal_title, null)
    "plus" -> CatalogSectionStrings(R.string.section_plus_title, R.string.section_plus_subtitle)
    "free" -> CatalogSectionStrings(R.string.section_free_title, null)
    else -> null
}
