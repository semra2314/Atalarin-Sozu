package com.example.kare.core.design

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.unit.dp

object KareSpacing {
    val xs = 4.dp
    val sm = 8.dp
    val md = 12.dp
    val lg = 20.dp
    val xl = 24.dp
    val xxl = 40.dp
}
object KareShapes {
    val card = RoundedCornerShape(20.dp)
    val hero = RoundedCornerShape(28.dp)
    val sheet = RoundedCornerShape(28.dp)
    val chip = RoundedCornerShape(50)
    // Smaller control corners follow Material defaults; cards and sheets use Kare radii.
    val material = Shapes(medium = card, large = card, extraLarge = sheet)
}
object KareLayout {
    val readableWidth = 680.dp
    val wideWidth = 1040.dp
}
private val LocalKareColors = staticCompositionLocalOf { KareLightColors }
object KareDesign {
    val colors: KareColors @Composable get() = LocalKareColors.current
}

@Composable
fun KareTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    CompositionLocalProvider(LocalKareColors provides if (darkTheme) KareDarkColors else KareLightColors) {
        MaterialTheme(colorScheme = kareColorScheme(darkTheme), typography = KareTypography,
            shapes = KareShapes.material, content = content)
    }
}
