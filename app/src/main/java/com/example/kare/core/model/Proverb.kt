package com.example.kare.core.model

/** Source-language content; Turkish sayings are not translated as interface strings. */
data class Proverb(val id: Int, val isProverb: Boolean, val title: String, val meaning: String, val example: String)
enum class ProverbSelection { ALL, PROVERBS, IDIOMS }
data class WidgetInstance(val templateId: String = "t-proverb", val selection: ProverbSelection = ProverbSelection.ALL)

sealed interface ProverbSnapshot {
    data object Loading : ProverbSnapshot
    data object NeedsConfiguration : ProverbSnapshot
    data object LibraryMissing : ProverbSnapshot
    data object Unavailable : ProverbSnapshot
    data class Ready(val proverb: Proverb) : ProverbSnapshot
}
