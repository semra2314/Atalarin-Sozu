package com.example.kare.core.model

/** Visual recipe only. Color parsing, gradients, and glass rendering belong to the UI. */
data class WidgetTheme(
    val backgroundHexes: List<String>,
    val foregroundHex: String = "FFFFFF",
    val accentHex: String = "5E5CE6",
    val cornerRadius: Double = 22.0,
    val usesGlassEffect: Boolean = false,
)
