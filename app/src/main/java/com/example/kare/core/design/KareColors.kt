package com.example.kare.core.design

import androidx.compose.material3.ColorScheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Immutable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.compositeOver

/** Exact Theme.Palette values; Swift RRGGBBAA tint tokens are converted to Android AARRGGBB. */
@Immutable
data class KareColors(
    val background: Color, val surface: Color, val surfaceMuted: Color,
    val textPrimary: Color, val textSecondary: Color, val border: Color,
    val accent: Color, val accentTint: Color, val onInk: Color,
    val stageTop: Color, val stageBottom: Color,
)

val KareLightColors = KareColors(
    Color(0xFFFDF8F8), Color(0xFFFFFFFF), Color(0xFFF1EDEC),
    Color(0xFF1D1D1F), Color(0xFF5E5E63), Color(0xFFE5E2E1),
    Color(0xFFD44A33), Color(0x1FD44A33), Color(0xFFFFFFFF),
    Color(0xFFEFE9E7), Color(0xFFE2DAD8),
)
val KareDarkColors = KareColors(
    Color(0xFF141111), Color(0xFF1F1B1B), Color(0xFF2B2626),
    Color(0xFFF5F1F0), Color(0xFFA8A2A1), Color(0xFF3A3434),
    Color(0xFFE25A42), Color(0x2EE25A42), Color(0xFF1D1D1F),
    Color(0xFF2A2525), Color(0xFF1F1B1B),
)

fun kareColorScheme(dark: Boolean): ColorScheme {
    val c = if (dark) KareDarkColors else KareLightColors
    val native = if (dark) darkColorScheme() else lightColorScheme()
    return native.copy(
        // Slightly deeper light-mode coral gives white button labels at least 4.5:1 contrast.
        primary = if (dark) c.accent else Color(0xFFCC442E), onPrimary = if (dark) c.background else Color.White,
        primaryContainer = c.accentTint.compositeOver(c.surface), onPrimaryContainer = c.textPrimary,
        inversePrimary = if (dark) KareLightColors.accent else KareDarkColors.accent,
        secondary = c.textPrimary, onSecondary = c.onInk,
        secondaryContainer = c.surfaceMuted, onSecondaryContainer = c.textPrimary,
        tertiary = c.textSecondary, onTertiary = c.background,
        tertiaryContainer = c.surfaceMuted, onTertiaryContainer = c.textPrimary,
        background = c.background, onBackground = c.textPrimary,
        surface = c.surface, onSurface = c.textPrimary,
        surfaceVariant = c.surfaceMuted, onSurfaceVariant = c.textSecondary,
        surfaceTint = c.accent, outline = c.textSecondary, outlineVariant = c.border,
        inverseSurface = c.textPrimary, inverseOnSurface = c.onInk,
        surfaceDim = c.background, surfaceBright = c.surface,
        surfaceContainerLowest = c.background, surfaceContainerLow = c.surface,
        surfaceContainer = c.surface, surfaceContainerHigh = c.surfaceMuted,
        surfaceContainerHighest = c.surfaceMuted,
        // Native Material error roles remain distinct from the brand accent.
    )
}
