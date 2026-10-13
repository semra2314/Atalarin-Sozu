package com.example.kare.app

import android.content.Context
import android.util.Log
import androidx.appcompat.app.AppCompatDelegate
import androidx.core.os.LocaleListCompat
import com.example.kare.core.model.AppLanguage
import com.example.kare.widget.HushWidget
import com.example.kare.widget.ProverbWidget
import kotlinx.coroutines.CancellationException

/** Native presentation effects; preferences remain in DataStore, launcher state remains independent. */
class AppPreferenceEffects(private val context: Context) {
    fun applyLanguage(language: AppLanguage) {
        val locales = LocaleListCompat.forLanguageTags(language.tag)
        if (AppCompatDelegate.getApplicationLocales() != locales) AppCompatDelegate.setApplicationLocales(locales)
    }
    suspend fun refreshWidgetLanguage() {
        // Refresh rendering only. Never rewrites categories, explicit language choices or instance IDs.
        try {
            ProverbWidget.refreshAll(context)
            HushWidget.refreshAll(context)
        } catch (error: Exception) {
            if (error is CancellationException) throw error
            Log.e("Kare", "Refresh widget language", error)
        }
    }
}
