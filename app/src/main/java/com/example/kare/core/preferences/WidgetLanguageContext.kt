package com.example.kare.core.preferences

import android.content.Context
import android.content.res.Configuration
import android.util.Log
import com.example.kare.KareApplication
import com.example.kare.core.model.AppLanguage
import com.example.kare.core.model.AppPreferences
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.Flow
import java.util.Locale

/** Keeps active Glance sessions reactive too; no Activity or preference-writing dependency. */
fun widgetPreferences(context: Context): Flow<AppPreferences> =
    (context.applicationContext as KareApplication).container.preferences.preferences.catch { error ->
        if (error is CancellationException) throw error
        Log.e("Kare", "Widget app language unavailable", error)
        emit(AppPreferences())
    }

/** App-following rendering only. Never writes a widget instance or changes explicit Hush languages. */
fun widgetLanguageContext(context: Context, language: AppLanguage): Context {
    val locale = if (language.tag.isEmpty()) android.content.res.Resources.getSystem().configuration.locales[0]
        else Locale.forLanguageTag(language.tag)
    return context.createConfigurationContext(Configuration(context.resources.configuration).apply { setLocale(locale) })
}
