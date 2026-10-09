package com.example.kare.core.localization

import androidx.annotation.DrawableRes
import androidx.annotation.StringRes
import com.example.kare.R

/** Bundled marketing copy/art only; stored templates and user content remain untouched. */
data class CatalogCopy(@param:StringRes val name: Int, @param:StringRes val summary: Int)
fun catalogCopy(id: String): CatalogCopy? = when (id) {
    "t-aurora" -> CatalogCopy(R.string.catalog_t_aurora_name, R.string.catalog_t_aurora_summary)
    "t-focus" -> CatalogCopy(R.string.catalog_t_focus_name, R.string.catalog_t_focus_summary)
    "t-frame" -> CatalogCopy(R.string.catalog_t_frame_name, R.string.catalog_t_frame_summary)
    "t-hush" -> CatalogCopy(R.string.catalog_t_hush_name, R.string.catalog_t_hush_summary)
    "t-daily" -> CatalogCopy(R.string.catalog_t_daily_name, R.string.catalog_t_daily_summary)
    "t-proverb" -> CatalogCopy(R.string.catalog_t_proverb_name, R.string.catalog_t_proverb_summary)
    "t-exhale" -> CatalogCopy(R.string.catalog_t_exhale_name, R.string.catalog_t_exhale_summary)
    "t-countdown" -> CatalogCopy(R.string.catalog_t_countdown_name, R.string.catalog_t_countdown_summary)
    "t-progress" -> CatalogCopy(R.string.catalog_t_progress_name, R.string.catalog_t_progress_summary)
    "t-custom" -> CatalogCopy(R.string.catalog_t_custom_name, R.string.catalog_t_custom_summary)
    "p-sunset" -> CatalogCopy(R.string.catalog_p_sunset_name, R.string.catalog_p_sunset_summary)
    "p-hydrate" -> CatalogCopy(R.string.catalog_p_hydrate_name, R.string.catalog_p_hydrate_summary)
    "p-deepwork" -> CatalogCopy(R.string.catalog_p_deepwork_name, R.string.catalog_p_deepwork_summary)
    "p-pastel" -> CatalogCopy(R.string.catalog_p_pastel_name, R.string.catalog_p_pastel_summary)
    "p-mood" -> CatalogCopy(R.string.catalog_p_mood_name, R.string.catalog_p_mood_summary)
    "p-us" -> CatalogCopy(R.string.catalog_p_us_name, R.string.catalog_p_us_summary)
    "p-momentum" -> CatalogCopy(R.string.catalog_p_momentum_name, R.string.catalog_p_momentum_summary)
    "p-neon" -> CatalogCopy(R.string.catalog_p_neon_name, R.string.catalog_p_neon_summary)
    "p-gratitude" -> CatalogCopy(R.string.catalog_p_gratitude_name, R.string.catalog_p_gratitude_summary)
    "p-mono" -> CatalogCopy(R.string.catalog_p_mono_name, R.string.catalog_p_mono_summary)
    else -> null
}
@DrawableRes
fun catalogArtwork(id: String): Int? = when (id) {
    "t-aurora" -> R.drawable.catalog_t_aurora
    "t-focus" -> R.drawable.catalog_t_focus
    "t-frame" -> R.drawable.catalog_t_frame
    "t-hush" -> R.drawable.catalog_t_hush
    "t-daily" -> R.drawable.catalog_t_daily
    "t-proverb" -> R.drawable.catalog_t_proverb
    "t-exhale" -> R.drawable.catalog_t_exhale
    "t-countdown" -> R.drawable.catalog_t_countdown
    "t-progress" -> R.drawable.catalog_t_progress
    "t-custom" -> R.drawable.catalog_t_custom
    "p-sunset" -> R.drawable.catalog_p_sunset
    "p-hydrate" -> R.drawable.catalog_p_hydrate
    "p-deepwork" -> R.drawable.catalog_p_deepwork
    "p-pastel" -> R.drawable.catalog_p_pastel
    "p-mood" -> R.drawable.catalog_p_mood
    "p-us" -> R.drawable.catalog_p_us
    "p-neon" -> R.drawable.catalog_p_neon
    "p-gratitude" -> R.drawable.catalog_p_gratitude
    "p-mono" -> R.drawable.catalog_p_mono
    else -> null
}
