package com.example.kare.core.model

/** An ordered, resolved catalog shelf; remote template IDs must be resolved by a data source. */
data class CatalogSection(
    val id: String,
    val title: String,
    val style: Style,
    val templates: List<WidgetTemplate>,
    val subtitle: String? = null,
) {
    enum class Style(val rawValue: String) {
        SPOTLIGHT("spotlight"), CAROUSEL("carousel"), COMPACT_LIST("compactList"),
    }
}
