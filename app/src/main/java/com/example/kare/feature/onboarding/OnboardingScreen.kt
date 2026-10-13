package com.example.kare.feature.onboarding

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.*
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.R
import com.example.kare.core.design.*
import com.example.kare.core.model.AppPreferences
import com.example.kare.feature.settings.*

@Composable
fun OnboardingRoute(viewModel: OnboardingViewModel, preferences: PreferencesViewModel, value: AppPreferences) {
    val page by viewModel.page.collectAsStateWithLifecycle()
    val state by preferences.state.collectAsStateWithLifecycle()
    BackHandler(page > 0 && !state.saving) { viewModel.previous() }
    OnboardingContent(page, value, state.saving, state.error, viewModel::next, viewModel::previous,
        preferences::completeOnboarding, preferences::language, preferences::continueForSession)
}

@Composable
fun OnboardingContent(page: Int, preferences: AppPreferences, saving: Boolean, error: PreferenceError?,
    onNext: () -> Unit, onPrevious: () -> Unit, onComplete: () -> Unit,
    onLanguage: (com.example.kare.core.model.AppLanguage) -> Unit, onContinueForSession: () -> Unit) {
    val title = when(page) {
        0 -> R.string.onboarding_language
        1 -> R.string.onboarding_curated_title
        2 -> R.string.onboarding_yours_title
        else -> R.string.onboarding_home_title
    }
    Column(Modifier.fillMaxSize().safeDrawingPadding().widthIn(max = KareLayout.readableWidth)
        .verticalScroll(rememberScrollState()).padding(KareSpacing.xl).testTag("onboarding-page-$page"),
        verticalArrangement = Arrangement.spacedBy(KareSpacing.lg)) {
        Text(stringResource(R.string.app_name), style = MaterialTheme.typography.displayMedium)
        Text(stringResource(R.string.onboarding_page, page + 1, 4), Modifier.semantics { liveRegion = LiveRegionMode.Polite })
        PreferenceHeading(stringResource(title))
        if (page == 0) LanguageChoices(preferences.language, !saving, onLanguage)
        else Text(stringResource(when(page) {
            1 -> R.string.onboarding_curated_body
            2 -> R.string.onboarding_yours_body
            else -> R.string.onboarding_home_body
        }), style = MaterialTheme.typography.bodyLarge)
        error?.let { PreferenceErrorText(it) }
        Button(onClick = if(page == 3) onComplete else onNext, enabled = !saving,
            modifier = Modifier.fillMaxWidth().testTag("onboarding-next")) {
            Text(stringResource(if(page == 3) R.string.onboarding_finish else R.string.action_continue))
        }
        if (page > 0) {
            TextButton(onClick = onPrevious, enabled = !saving) { Text(stringResource(R.string.onboarding_previous)) }
            if(page < 3) TextButton(onClick = onComplete, enabled = !saving, modifier = Modifier.testTag("onboarding-skip")) {
                Text(stringResource(R.string.onboarding_skip))
            }
        }
        if (error != null) TextButton(onClick = onContinueForSession, enabled = !saving) { Text(stringResource(R.string.preferences_session)) }
        Text(stringResource(R.string.onboarding_account_later), style = MaterialTheme.typography.bodySmall)
    }
}
