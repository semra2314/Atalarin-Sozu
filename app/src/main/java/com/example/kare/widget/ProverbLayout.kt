package com.example.kare.widget

/** Presentation only: launcher dimensions never become persistent configuration. */
internal data class ProverbLayout(val padding: Int, val showKind: Boolean, val showExample: Boolean) {
    companion object {
        fun forSize(width: Float, height: Float, fontScale: Float): ProverbLayout {
            val scale = fontScale.coerceAtLeast(1f)
            return ProverbLayout(
                padding = if (width < 250) 12 else 16,
                showKind = height / scale >= 220,
                showExample = width / scale >= 220 && height / scale >= 300,
            )
        }
    }
}
