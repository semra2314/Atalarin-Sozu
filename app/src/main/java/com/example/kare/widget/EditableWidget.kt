package com.example.kare.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Shader
import android.os.Bundle
import androidx.compose.runtime.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.actionStartActivity
import androidx.glance.appwidget.*
import androidx.glance.appwidget.action.*
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.unit.ColorProvider
import com.example.kare.KareApplication
import com.example.kare.MainActivity
import com.example.kare.R
import com.example.kare.core.data.widget.EditableSnapshot
import com.example.kare.core.model.WidgetContent
import com.example.kare.core.model.EditableRendering
import com.example.kare.core.preferences.*
import kotlinx.coroutines.flow.first

class EditableWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val appId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        val repository = (context.applicationContext as KareApplication).container.editableInstances
        val snapshots = repository.observe(appId)
        val initial = repository.snapshot(appId)
        val preferences = widgetPreferences(context)
        val initialPreferences = preferences.first()
        provideContent {
            val preference by preferences.collectAsState(initialPreferences)
            val languageContext = remember(preference.language) { widgetLanguageContext(context, preference.language) }
            val snapshot by snapshots.collectAsState(initial)
            EditableContent(languageContext, appId, snapshot)
        }
    }
    override suspend fun onDelete(context: Context, glanceId: GlanceId) {
        (context.applicationContext as KareApplication).container.editableInstances.delete(GlanceAppWidgetManager(context).getAppWidgetId(glanceId))
    }
    companion object {
        suspend fun refresh(context: Context, id: Int) {
            (context.applicationContext as KareApplication).container.editableInstances.invalidate(id)
            EditableWidget().update(context, GlanceAppWidgetManager(context).getGlanceIdBy(id))
        }
    }
}

class EditableReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget = EditableWidget()
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        appWidgetIds.forEach { (context.applicationContext as KareApplication).container.editableInstances.invalidate(it) }
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }
    override fun onAppWidgetOptionsChanged(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int, newOptions: Bundle) {
        (context.applicationContext as KareApplication).container.editableInstances.invalidate(appWidgetId)
        super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    }
}
class RefreshEditable : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: androidx.glance.action.ActionParameters) {
        EditableWidget.refresh(context, GlanceAppWidgetManager(context).getAppWidgetId(glanceId))
    }
}

internal fun editableArgb(hex: String): Int = EditableRendering.argb(hex)
internal fun editableFont(font: WidgetContent.FontStyle): FontFamily = when(font) {
    WidgetContent.FontStyle.SERIF -> FontFamily.Serif
    WidgetContent.FontStyle.MONOSPACED -> FontFamily.Monospace
    else -> FontFamily.SansSerif
}
internal fun editableAlignment(alignment: WidgetContent.TextAlign): TextAlign = when(alignment) {
    WidgetContent.TextAlign.LEADING -> TextAlign.Start
    WidgetContent.TextAlign.CENTER -> TextAlign.Center
    WidgetContent.TextAlign.TRAILING -> TextAlign.End
}

/** Only a bounded background bitmap; text remains native, accessible Glance text. */
private fun background(content: WidgetContent, width: Float, height: Float): Bitmap {
    val colors = (content.background as WidgetContent.Background.Color).hexes.map(::editableArgb).toIntArray()
    val w = width.toInt().coerceIn(1, 600); val h = height.toInt().coerceIn(1, 600)
    return Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).also { bitmap ->
        val paint = Paint()
        if (colors.size == 1) paint.color = colors[0] else {
            val startX = if(content.gradientDirection == WidgetContent.GradientDirection.TOP_TRAILING) w.toFloat() else 0f
            val endX = if(content.gradientDirection == WidgetContent.GradientDirection.TOP || content.gradientDirection == WidgetContent.GradientDirection.TOP_TRAILING) 0f else w.toFloat()
            val endY = if(content.gradientDirection == WidgetContent.GradientDirection.LEADING) 0f else h.toFloat()
            paint.shader = LinearGradient(startX, 0f, endX, endY, colors, null, Shader.TileMode.CLAMP)
        }
        Canvas(bitmap).drawRect(0f, 0f, w.toFloat(), h.toFloat(), paint)
    }
}

@Composable
private fun EditableContent(context: Context, id: Int, snapshot: EditableSnapshot) {
    val size = LocalSize.current
    val widget = (snapshot as? EditableSnapshot.Ready)?.widget
    val content = widget?.content
    val text = content?.texts?.single()
    val bitmap = remember(content?.background, content?.gradientDirection, size) { content?.let { background(it, size.width.value, size.height.value) } }
    val modifier = GlanceModifier.fillMaxSize().appWidgetBackground().cornerRadius(EditableRendering.radius(widget?.theme?.cornerRadius).dp)
    Column(if(bitmap != null) modifier.background(ImageProvider(bitmap)) else modifier.background(Color(0xFF1D1D1F))) {
        val message = text?.text ?: context.getString(when(snapshot) {
            EditableSnapshot.MissingBinding -> R.string.editable_missing_binding
            EditableSnapshot.MissingLibrary -> R.string.editable_missing_library
            else -> R.string.editable_unavailable
        })
        val style = TextStyle(
            color = ColorProvider(text?.let { Color(editableArgb(it.colorHex)) } ?: Color.White),
            fontFamily = text?.let { editableFont(it.fontStyle) } ?: FontFamily.SansSerif,
            fontSize = (text?.let { EditableRendering.textSize(it.fontSize, size.width.value, size.height.value) } ?: 16f).sp,
            fontWeight = if(text?.fontWeight == WidgetContent.Weight.REGULAR) FontWeight.Normal else FontWeight.Bold,
            textAlign = text?.let { editableAlignment(it.alignment) } ?: TextAlign.Center)
        val insets = text?.let { EditableRendering.horizontalInsets(it, size.width.value) } ?: (12f to 12f)
        val rtl = context.resources.configuration.layoutDirection == android.view.View.LAYOUT_DIRECTION_RTL
        val textArea = GlanceModifier.fillMaxWidth().defaultWeight()
            .padding(start = (if (rtl) insets.second else insets.first).dp, end = (if (rtl) insets.first else insets.second).dp, top = 12.dp, bottom = 12.dp)
        // Native RemoteViews cannot place a measured text layer at arbitrary normalized y.
        // Preserve its nearest vertical anchor; scrolling always starts at the first line.
        val anchor = when {
            text != null && text.y <= 1.0 / 3 -> Alignment.TopStart
            text != null && text.y >= 2.0 / 3 -> Alignment.BottomStart
            else -> Alignment.CenterStart
        }
        // Long/large text scrolls; actions have their own high-contrast, fixed-height row.
        if (size.height.value < 240 || context.resources.configuration.fontScale > 1.3f || message.length > 100 || text == null) {
            LazyColumn(textArea) {
                item { Text(message, GlanceModifier.fillMaxWidth(), style, maxLines = 100) }
            }
        } else {
            Box(textArea, contentAlignment = anchor) {
                Text(message, GlanceModifier.fillMaxWidth(), style, maxLines = 100)
            }
        }
        Row(GlanceModifier.fillMaxWidth().background(Color(0xFF1D1D1F))) {
            val ink = ColorProvider(Color.White)
            WidgetAction(R.drawable.widget_refresh, context.getString(R.string.action_refresh), actionRunCallback<RefreshEditable>(), ink)
            WidgetAction(R.drawable.widget_configure, context.getString(R.string.editable_configure),
                actionStartActivity(Intent(context, EditableConfigurationActivity::class.java).putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)), ink)
            WidgetAction(R.drawable.widget_open, context.getString(R.string.proverb_open_app), actionStartActivity<MainActivity>(), ink)
        }
    }
}
