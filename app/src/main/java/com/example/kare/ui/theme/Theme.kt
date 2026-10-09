package com.example.kare.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable

/** Keeps the starter entry point compatible; new UI should import core.design.KareTheme. */
@Composable
fun KareTheme(darkTheme: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    com.example.kare.core.design.KareTheme(darkTheme, content)
}
