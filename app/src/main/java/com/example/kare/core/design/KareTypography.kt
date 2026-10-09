package com.example.kare.core.design

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.example.kare.R

val KareSerif = FontFamily(
    Font(R.font.fraunces_soft_semibold, FontWeight.SemiBold),
    Font(R.font.fraunces_soft_bold, FontWeight.Bold),
    Font(R.font.fraunces_soft_black, FontWeight.Black),
)

/** Source point sizes become scalable sp; line heights are explicit Android choices. */
object KareTextStyles {
    val display = TextStyle(fontFamily = KareSerif, fontWeight = FontWeight.Black, fontSize = 34.sp, lineHeight = 42.sp)
    val headline = TextStyle(fontFamily = KareSerif, fontWeight = FontWeight.Bold, fontSize = 24.sp, lineHeight = 32.sp)
    val headlineSmall = TextStyle(fontFamily = KareSerif, fontWeight = FontWeight.Bold, fontSize = 20.sp, lineHeight = 28.sp)
    val title = TextStyle(fontFamily = KareSerif, fontWeight = FontWeight.SemiBold, fontSize = 17.sp, lineHeight = 24.sp)
    val body = TextStyle(fontFamily = FontFamily.SansSerif, fontSize = 15.sp, lineHeight = 22.sp)
    val bodyLarge = TextStyle(fontFamily = FontFamily.SansSerif, fontSize = 17.sp, lineHeight = 24.sp)
    val label = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.Medium, fontSize = 13.sp, lineHeight = 18.sp)
    val labelCaps = TextStyle(fontFamily = FontFamily.SansSerif, fontWeight = FontWeight.Bold, fontSize = 12.sp, lineHeight = 16.sp, letterSpacing = 0.6.sp)
    val cardTitle = body.copy(fontWeight = FontWeight.SemiBold)
}

val KareTypography = Typography(
    displayLarge = KareTextStyles.display, displayMedium = KareTextStyles.display, displaySmall = KareTextStyles.headline,
    headlineLarge = KareTextStyles.headline, headlineMedium = KareTextStyles.headline, headlineSmall = KareTextStyles.headlineSmall,
    titleLarge = KareTextStyles.headlineSmall, titleMedium = KareTextStyles.title, titleSmall = KareTextStyles.cardTitle,
    bodyLarge = KareTextStyles.bodyLarge, bodyMedium = KareTextStyles.body, bodySmall = KareTextStyles.label,
    labelLarge = KareTextStyles.label, labelMedium = KareTextStyles.label, labelSmall = KareTextStyles.labelCaps,
)
