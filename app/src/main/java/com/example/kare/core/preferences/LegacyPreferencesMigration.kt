package com.example.kare.core.preferences

import android.content.Context
import androidx.datastore.core.DataMigration
import androidx.datastore.preferences.core.*
import com.example.kare.core.model.*

/** One-time import only. Existing DataStore choices always win; no ongoing SharedPreferences writer. */
internal class LegacyPreferencesMigration(context: Context) : DataMigration<Preferences> {
    private val legacy = context.getSharedPreferences("kare_user_preferences", Context.MODE_PRIVATE)
    override suspend fun shouldMigrate(currentData: Preferences) =
        legacy.contains("pref_theme") || legacy.contains("pref_language")
    override suspend fun migrate(currentData: Preferences): Preferences = currentData.toMutablePreferences().apply {
        val theme = stringPreferencesKey("appearance")
        val language = stringPreferencesKey("language")
        if (this[theme] == null) this[theme] = AppAppearance.entries.firstOrNull {
            it.name.equals(legacy.getString("pref_theme", null), ignoreCase = true)
        }?.name ?: AppAppearance.SYSTEM.name
        if (this[language] == null) this[language] = when (legacy.getString("pref_language", null)?.lowercase()) {
            "en", "english" -> AppLanguage.ENGLISH.name
            "tr", "turkish" -> AppLanguage.TURKISH.name
            else -> AppLanguage.SYSTEM.name
        }
    }
    override suspend fun cleanUp() {
        check(legacy.edit().remove("pref_theme").remove("pref_language").commit()) { "Legacy preference cleanup failed" }
    }
}
