package com.example.kare.core.data.preferences

import android.content.Context
import android.content.SharedPreferences
import com.example.kare.core.model.AppLanguage
import com.example.kare.core.model.AppTheme
import com.example.kare.core.repository.UserPreferencesRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * SharedPreferences-backed implementation of [UserPreferencesRepository].
 */
class SharedPreferencesUserPreferencesRepository(
    context: Context,
) : UserPreferencesRepository {

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private val _theme = MutableStateFlow(
        AppTheme.fromString(prefs.getString(KEY_THEME, AppTheme.SYSTEM.name))
    )
    override val theme: StateFlow<AppTheme> = _theme.asStateFlow()

    private val _language = MutableStateFlow(
        AppLanguage.fromString(prefs.getString(KEY_LANGUAGE, AppLanguage.SYSTEM.code))
    )
    override val language: StateFlow<AppLanguage> = _language.asStateFlow()

    override suspend fun setTheme(theme: AppTheme) {
        prefs.edit().putString(KEY_THEME, theme.name).apply()
        _theme.value = theme
    }

    override suspend fun setLanguage(language: AppLanguage) {
        prefs.edit().putString(KEY_LANGUAGE, language.code).apply()
        _language.value = language
    }

    companion object {
        private const val PREFS_NAME = "kare_user_preferences"
        private const val KEY_THEME = "pref_theme"
        private const val KEY_LANGUAGE = "pref_language"
    }
}
