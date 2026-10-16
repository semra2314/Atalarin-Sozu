package com.example.kare.feature.editor

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.*
import com.example.kare.core.design.KareSerif
import com.example.kare.core.model.WidgetContent

object EditorTypography {
    val selectable = listOf(WidgetContent.FontStyle.SERIF, WidgetContent.FontStyle.STANDARD, WidgetContent.FontStyle.MONOSPACED)
    fun family(style: WidgetContent.FontStyle): FontFamily = when (style) {
        WidgetContent.FontStyle.SERIF -> KareSerif
        WidgetContent.FontStyle.MONOSPACED -> FontFamily.Monospace
        else -> FontFamily.SansSerif // iOS rounded has no bundled Android equivalent; preserve its ID on load.
    }
}
internal fun editorColor(hex: String) = Color(0xFF000000L or hex.toLong(16))

/** In-app preview only; never writes state or participates in Glance rendering. */
@Composable
fun EditorPreview(draft: EditorDraft, cornerRadius: Double, modifier: Modifier = Modifier) {
    val c = draft.content; val t = draft.primary
    val colors = (c.background as WidgetContent.Background.Color).hexes.map(::editorColor)
    val start = when(c.gradientDirection) {
        WidgetContent.GradientDirection.TOP_TRAILING -> Offset(Float.POSITIVE_INFINITY, 0f)
        else -> Offset.Zero
    }
    val end = when(c.gradientDirection) {
        WidgetContent.GradientDirection.TOP -> Offset(0f, Float.POSITIVE_INFINITY)
        WidgetContent.GradientDirection.LEADING -> Offset(Float.POSITIVE_INFINITY, 0f)
        WidgetContent.GradientDirection.TOP_TRAILING -> Offset(0f, Float.POSITIVE_INFINITY)
        else -> Offset.Infinite
    }
    BoxWithConstraints(modifier.fillMaxWidth().height(260.dp).testTag("editor-preview")
        .clip(RoundedCornerShape(cornerRadius.takeIf { it.isFinite() && it >= 0 }?.coerceAtMost(60.0)?.dp ?: 22.dp))
        .background(Brush.linearGradient(if(colors.size == 1) colors + colors else colors, start, end))) {
        val scale = minOf(maxWidth.value, maxHeight.value) / 329f
        Layout(content = {
            Text(t.text, color = editorColor(t.colorHex), fontSize = (t.fontSize * scale).sp,
                fontFamily = EditorTypography.family(t.fontStyle), fontWeight = when(t.fontWeight) {
                    WidgetContent.Weight.REGULAR -> FontWeight.Normal
                    WidgetContent.Weight.SEMIBOLD -> FontWeight.SemiBold
                    WidgetContent.Weight.BOLD -> FontWeight.Bold
                    WidgetContent.Weight.HEAVY -> FontWeight.Black
                }, textAlign = when(t.alignment) {
                    WidgetContent.TextAlign.LEADING -> TextAlign.Start
                    WidgetContent.TextAlign.CENTER -> TextAlign.Center
                    WidgetContent.TextAlign.TRAILING -> TextAlign.End
                }, lineHeight = ((t.fontSize * 1.2 + t.lineSpacing) * scale).sp,
                modifier = Modifier.testTag("editor-preview-text"))
        }, modifier = Modifier.fillMaxSize()) { measurables, constraints ->
            val width = (constraints.maxWidth * t.widthFraction).toInt().coerceAtLeast(1)
            val child = measurables.single().measure(Constraints(minWidth = width, maxWidth = width))
            layout(constraints.maxWidth, constraints.maxHeight) {
                child.place((constraints.maxWidth * t.x - child.width / 2).toInt(),
                    (constraints.maxHeight * t.y - child.height / 2).toInt())
            }
        }
    }
}
