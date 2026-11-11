package com.example.kare.core.model

/**
 * Passage source per launcher instance. Only sources with a rights-cleared corpus are listed:
 * the iOS Quran and Stoic sources are deferred until translation licensing is verified.
 */
enum class DailySource { BIBLE, POETRY }
data class DailyConfiguration(val source: DailySource = DailySource.BIBLE)
data class DailyPassage(val text: String, val attribution: String, val source: DailySource)
sealed interface DailySnapshot {
    data object Loading : DailySnapshot
    data object NeedsConfiguration : DailySnapshot
    data object LibraryMissing : DailySnapshot
    data object Unavailable : DailySnapshot
    data class Ready(val passage: DailyPassage) : DailySnapshot
}
