package com.example.kare.core.model

/** Portable interpretation shared by the preview and native launcher renderer. */
object EditableRendering {
    fun argb(hex: String): Int = if (EditableContentValidation.validHex(hex))
        (0xFF000000L or hex.toLong(16)).toInt() else 0xFF1D1D1F.toInt()

    fun radius(value: Double?): Float = value?.takeIf { it.isFinite() && it >= 0 }
        ?.coerceAtMost(60.0)?.toFloat() ?: 22f

    fun textSize(size: Double, width: Float, height: Float): Float =
        (size * minOf(width, height) / 329f).toFloat().coerceAtLeast(8f)

    /** Physical canvas edges, unlike text alignment which follows layout direction. */
    fun horizontalInsets(text: WidgetContent.TextElement, width: Float): Pair<Float, Float> {
        val left = (text.x - text.widthFraction / 2).coerceIn(0.0, 1.0)
        val right = (text.x + text.widthFraction / 2).coerceIn(left, 1.0)
        return (left * width).toFloat() to ((1 - right) * width).toFloat()
    }
}
