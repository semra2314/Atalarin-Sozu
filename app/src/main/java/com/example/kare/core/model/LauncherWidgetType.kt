package com.example.kare.core.model

/** Single domain capability list; catalog/Library installation does not imply launcher support. */
enum class LauncherWidgetType(val templateId: String) {
    PROVERB("t-proverb"), HUSH("t-hush"), GENERIC_EDITABLE("");
    companion object {
        fun forWidget(widget: InstalledWidget): LauncherWidgetType? = forTemplate(widget.templateId)
            ?: GENERIC_EDITABLE.takeIf { InstalledEditorCapabilities.forWidget(widget) != InstalledEditorCapability.UNSUPPORTED }
 fun forTemplate(id: String) = entries.find { it != GENERIC_EDITABLE && it.templateId == id } }
}
