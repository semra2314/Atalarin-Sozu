package com.example.kare.widget

import android.appwidget.AppWidgetManager
import android.content.Context
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
import com.example.kare.core.model.ProverbSnapshot

/** Glance renders persisted repository state; no Activity/ViewModel dependency. */
class ProverbWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val repository = (context.applicationContext as KareApplication).container.widgetInstances
        val flow = repository.observe(GlanceAppWidgetManager(context).getAppWidgetId(id))
        provideContent {
            val snapshot by flow.collectAsState(ProverbSnapshot.Loading)
            ProverbContent(context, snapshot)
        }
    }
    override suspend fun onDelete(context: Context, glanceId: GlanceId) {
        (context.applicationContext as KareApplication).container.widgetInstances.delete(GlanceAppWidgetManager(context).getAppWidgetId(glanceId))
    }
    companion object {
        suspend fun refreshAll(context: Context) {
            (context.applicationContext as KareApplication).container.widgetInstances.invalidate()
            ProverbWidget().updateAll(context)
        }
    }
}

class ProverbReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = ProverbWidget()
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        (context.applicationContext as KareApplication).container.widgetInstances.invalidate()
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }
    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        (context.applicationContext as KareApplication).container.widgetInstances.invalidate()
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }
}

class RefreshProverb : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: androidx.glance.action.ActionParameters) {
        (context.applicationContext as KareApplication).container.widgetInstances.invalidate()
        ProverbWidget().update(context, glanceId)
    }
}

// Source paper/ink; accent darkened for small-label contrast. Native system serif replaces Fraunces.
private val paper = ColorProvider(Color(0xFFFBF4EA))
private val ink = ColorProvider(Color(0xFF2A211C))
private val accent = ColorProvider(Color(0xFFAA4C32))

@Composable
private fun ProverbContent(context: Context, snapshot: ProverbSnapshot) {
    Column(GlanceModifier.fillMaxSize().background(paper).appWidgetBackground().cornerRadius(20.dp).padding(16.dp)) {
        Text(context.getString(R.string.proverb_widget_name), style = TextStyle(color = accent, fontSize = 14.sp, fontWeight = FontWeight.Bold))
        Spacer(GlanceModifier.height(8.dp))
        when (snapshot) {
            is ProverbSnapshot.Ready -> {
                Text(context.getString(if (snapshot.proverb.isProverb) R.string.proverb_kind else R.string.proverb_idiom),
                    style = TextStyle(color = ink, fontSize = 12.sp))
                Text(snapshot.proverb.title, style = TextStyle(color = ink, fontSize = 18.sp,
                    fontWeight = FontWeight.Bold, fontFamily = FontFamily.Serif), maxLines = 2)
                Spacer(GlanceModifier.height(8.dp))
                Text(snapshot.proverb.meaning, style = TextStyle(color = ink, fontSize = 13.sp), maxLines = 3)
                if (LocalSize.current.height >= 280.dp) {
                    Spacer(GlanceModifier.height(8.dp))
                    Text(snapshot.proverb.example, style = TextStyle(color = ink, fontSize = 13.sp), maxLines = 3)
                }
            }
            else -> Text(context.getString(when (snapshot) {
                ProverbSnapshot.Loading -> R.string.loading_widgets
                ProverbSnapshot.NeedsConfiguration -> R.string.proverb_needs_configuration
                ProverbSnapshot.LibraryMissing -> R.string.proverb_library_missing
                else -> R.string.proverb_unavailable
            }), style = TextStyle(color = ink, fontSize = 14.sp))
        }
        Spacer(GlanceModifier.defaultWeight())
        Row {
            Button(context.getString(R.string.action_refresh), actionRunCallback<RefreshProverb>(),
                colors = ButtonDefaults.buttonColors(backgroundColor = ink, contentColor = paper))
            Spacer(GlanceModifier.width(8.dp))
            Button(context.getString(R.string.proverb_open_app), actionStartActivity<MainActivity>(),
                colors = ButtonDefaults.buttonColors(backgroundColor = ink, contentColor = paper))
        }
    }
}
