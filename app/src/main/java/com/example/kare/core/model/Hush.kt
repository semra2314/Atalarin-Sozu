package com.example.kare.core.model

/** Content language is per launcher instance; APP follows Kare's current resources. */
enum class HushLanguage { APP, ENGLISH, TURKISH }
data class HushConfiguration(val language: HushLanguage = HushLanguage.APP)
enum class HushPrompt { BREATHE, PAUSE, NOTICE, SOFTEN, ARRIVE, RELEASE, SETTLE, LISTEN, SLOW_DOWN, BE_HERE }
enum class HushPalette { DAWN, STILL, NIGHT }
data class HushEntry(val prompt: HushPrompt, val palette: HushPalette, val language: HushLanguage)
sealed interface HushSnapshot {
    data object Loading : HushSnapshot
    data object NeedsConfiguration : HushSnapshot
    data object LibraryMissing : HushSnapshot
    data object Unavailable : HushSnapshot
    data class Ready(val entry: HushEntry) : HushSnapshot
}
