package com.example.kare.feature.settings

import com.example.kare.app.AppPreferenceEffects
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.R
import com.example.kare.core.design.*
import com.example.kare.core.model.*

/** Activity-level theme/locale integration. Persistence is exclusively owned by the ViewModel. */
@Composable
fun PreferencesHost(viewModel: PreferencesViewModel, content: @Composable (AppPreferences) -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val prefs = (state.startup as? StartupState.Loaded)?.preferences
    val dark = when (prefs?.appearance) {
        AppAppearance.LIGHT -> false
        AppAppearance.DARK -> true
        else -> isSystemInDarkTheme()
    }
    val context = androidx.compose.ui.platform.LocalContext.current
    val effects = remember(context) { AppPreferenceEffects(context.applicationContext) }
    SideEffect {
        val activity = context as? android.app.Activity
        activity?.window?.let { window ->
            androidx.core.view.WindowCompat.getInsetsController(window, window.decorView).apply {
                isAppearanceLightStatusBars = !dark
                isAppearanceLightNavigationBars = !dark
            }
        }
    }
    // Gate only the initial load. Removing the NavHost on every language change would discard its saved back stack.
    var localeApplied by remember { mutableStateOf(false) }
    LaunchedEffect(prefs?.language) {
        prefs?.let {
            effects.applyLanguage(it.language)
            localeApplied = true
            effects.refreshWidgetLanguage()
        }
    }
    KareTheme(darkTheme = dark) {
        Surface(Modifier.fillMaxSize()) {
            when {
                state.startup == StartupState.Unavailable -> Column(
                    Modifier.safeDrawingPadding().verticalScroll(rememberScrollState()).padding(KareSpacing.lg), verticalArrangement = Arrangement.spacedBy(KareSpacing.md)) {
                    PreferenceErrorText(PreferenceError.READ)
                    Button(onClick = viewModel::retry) { Text(stringResource(R.string.action_retry)) }
                    TextButton(onClick = viewModel::continueForSession) { Text(stringResource(R.string.preferences_session)) }
                }
                prefs != null && localeApplied -> content(prefs)
                else -> Box(Modifier.fillMaxSize(), contentAlignment = androidx.compose.ui.Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
        }
    }
}
