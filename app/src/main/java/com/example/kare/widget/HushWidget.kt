package com.example.kare.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import androidx.glance.appwidget.lazy.LazyColumn
import android.os.Bundle
import androidx.compose.runtime.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.appwidget.*
import androidx.glance.appwidget.action.*
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.unit.ColorProvider
import com.example.kare.KareApplication
import com.example.kare.MainActivity
import com.example.kare.R
import com.example.kare.core.model.*

/** Glance renders persisted repository state; no Activity/ViewModel dependency. */
class HushWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val repository = (context.applicationContext as KareApplication).container.hushInstances
        val flow = repository.observe(GlanceAppWidgetManager(context).getAppWidgetId(id))
        provideContent {
            val snapshot by flow.collectAsState(HushSnapshot.Loading)
            HushContent(context, snapshot, GlanceAppWidgetManager(context).getAppWidgetId(id))
        }
    }
    override suspend fun onDelete(context: Context, glanceId: GlanceId) {
        (context.applicationContext as KareApplication).container.hushInstances.delete(GlanceAppWidgetManager(context).getAppWidgetId(glanceId))
    }
    companion object {
        suspend fun refreshAll(context: Context) {
            (context.applicationContext as KareApplication).container.hushInstances.invalidate()
            HushWidget().updateAll(context)
        }
    }
}

class HushReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = HushWidget()
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        (context.applicationContext as KareApplication).container.hushInstances.invalidate()
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }
    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        (context.applicationContext as KareApplication).container.hushInstances.invalidate()
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }
}

class RefreshHush : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: androidx.glance.action.ActionParameters) {
        (context.applicationContext as KareApplication).container.hushInstances.invalidate()
        HushWidget().update(context, glanceId)
    }
}

// iOS fallback palette and ink; system serif avoids unsupported custom widget fonts.
private val hushInk = ColorProvider(Color(0xFFC9C6C1))

internal fun hushPromptResource(prompt: HushPrompt): Int = when (prompt) {
    HushPrompt.BREATHE -> R.string.hush_breathe
    HushPrompt.PAUSE -> R.string.hush_pause
    HushPrompt.NOTICE -> R.string.hush_notice
    HushPrompt.SOFTEN -> R.string.hush_soften
    HushPrompt.ARRIVE -> R.string.hush_arrive
    HushPrompt.RELEASE -> R.string.hush_release
    HushPrompt.SETTLE -> R.string.hush_settle
    HushPrompt.LISTEN -> R.string.hush_listen
    HushPrompt.SLOW_DOWN -> R.string.hush_slow_down
    HushPrompt.BE_HERE -> R.string.hush_be_here
}

internal fun hushText(context: Context, entry: HushEntry): String {
    val localized = when (entry.language) {
        HushLanguage.APP -> context
        else -> context.createConfigurationContext(android.content.res.Configuration(context.resources.configuration).apply {
            setLocale(java.util.Locale.forLanguageTag(if (entry.language == HushLanguage.TURKISH) "tr" else "en"))
        })
    }
    return localized.getString(hushPromptResource(entry.prompt))
}

@Composable
private fun HushContent(context: Context, snapshot: HushSnapshot, appWidgetId: Int) {
    val size = LocalSize.current
    val entry = (snapshot as? HushSnapshot.Ready)?.entry
    val background = when (entry?.palette) {
        HushPalette.DAWN -> R.drawable.hush_dawn
        HushPalette.NIGHT -> R.drawable.hush_night
        else -> R.drawable.hush_still
    }
    val word = entry?.let { hushText(context, it) } ?: context.getString(when(snapshot) {
        HushSnapshot.Loading -> R.string.loading_widgets
        HushSnapshot.NeedsConfiguration -> R.string.proverb_needs_configuration
        HushSnapshot.LibraryMissing -> R.string.hush_library_missing
        else -> R.string.proverb_unavailable
    })
    Column(GlanceModifier.fillMaxSize().background(ImageProvider(background)).appWidgetBackground()
        .cornerRadius(20.dp).padding(12.dp)) {
        val textStyle = TextStyle(color = hushInk, fontFamily = FontFamily.Serif,
            textAlign = TextAlign.Center,
            fontSize = (if (entry == null) 16 else if (size.width.value >= 300) 34 else 25).sp)
        // Preserve Hush's centered word at normal sizes; scroll rather than shrink accessible text.
        if (size.height.value < 200 || context.resources.configuration.fontScale > 1.3f || entry == null) {
            LazyColumn(GlanceModifier.fillMaxWidth().defaultWeight()) {
                item { Text(word, modifier = GlanceModifier.fillMaxWidth().padding(vertical = 12.dp), style = textStyle) }
            }
        } else {
            Box(GlanceModifier.fillMaxWidth().defaultWeight(), contentAlignment = Alignment.Center) {
                Text(word, modifier = GlanceModifier.fillMaxWidth(), style = textStyle)
            }
        }
        Row {
            WidgetAction(R.drawable.widget_refresh, context.getString(R.string.action_refresh), actionRunCallback<RefreshHush>(), hushInk)
            WidgetAction(R.drawable.widget_configure, context.getString(R.string.hush_configure),
                actionStartActivity(Intent(context, HushConfigurationActivity::class.java)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)), hushInk)
            WidgetAction(R.drawable.widget_open, context.getString(R.string.proverb_open_app), actionStartActivity<MainActivity>(), hushInk)
        }
    }
}
