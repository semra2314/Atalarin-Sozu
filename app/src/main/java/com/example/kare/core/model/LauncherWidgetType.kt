package com.example.kare.core.model

/** Single domain capability list; catalog/Library installation does not imply launcher support. */
enum class LauncherWidgetType(val templateId: String) {
    PROVERB("t-proverb"), HUSH("t-hush");
    companion object { fun forTemplate(id: String) = entries.find { it.templateId == id } }
}
