package com.example.kare.core.preferences

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import com.example.kare.core.model.*
import com.example.kare.core.repository.PreferencesRepository
import kotlinx.coroutines.flow.map

// One DataStore per file/process. Errors propagate to presentation for retry or session-only access.
private val Context.karePreferences by preferencesDataStore(name = "kare_preferences")

class DataStorePreferencesRepository(private val store: DataStore<Preferences>) : PreferencesRepository {
    constructor(context: Context) : this(context.applicationContext.karePreferences)
    override val preferences = store.data.map { value ->
        AppPreferences(value[completed] ?: false,
            AppLanguage.entries.firstOrNull { it.name == value[language] } ?: AppLanguage.SYSTEM,
            AppAppearance.entries.firstOrNull { it.name == value[appearance] } ?: AppAppearance.SYSTEM)
    }
    override suspend fun completeOnboarding() { store.edit { it[completed] = true } }
    override suspend fun setLanguage(language: AppLanguage) { store.edit { it[Companion.language] = language.name } }
    override suspend fun setAppearance(appearance: AppAppearance) { store.edit { it[Companion.appearance] = appearance.name } }
    private companion object {
        val completed = booleanPreferencesKey("onboarding_completed")
        val language = stringPreferencesKey("language")
        val appearance = stringPreferencesKey("appearance")
    }
}
