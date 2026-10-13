package com.example.kare.core.repository

import com.example.kare.core.model.*
import kotlinx.coroutines.flow.Flow

interface PreferencesRepository {
    val preferences: Flow<AppPreferences>
    suspend fun completeOnboarding()
    suspend fun setLanguage(language: AppLanguage)
    suspend fun setAppearance(appearance: AppAppearance)
}
