package com.example.kare.core.repository

import com.example.kare.core.model.AppLanguage
import com.example.kare.core.model.AppTheme
import kotlinx.coroutines.flow.StateFlow

/**
 * Repository managing user application preferences such as visual theme and UI language.
 */
interface UserPreferencesRepository {
    val theme: StateFlow<AppTheme>
    val language: StateFlow<AppLanguage>

    suspend fun setTheme(theme: AppTheme)
    suspend fun setLanguage(language: AppLanguage)
}
