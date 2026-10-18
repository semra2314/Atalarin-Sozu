package com.example.kare.feature.settings

import android.content.Intent
import androidx.core.net.toUri
import android.provider.Settings
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.semantics.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.R
import com.example.kare.core.design.*
import com.example.kare.core.model.*
import androidx.core.content.pm.PackageInfoCompat

@Composable
fun SettingsRoute(viewModel: SettingsViewModel, preferences: PreferencesViewModel, onKarePlus: () -> Unit = {}, onSignIn: () -> Unit) {
    val state by preferences.state.collectAsStateWithLifecycle()
    val identity by viewModel.identity.collectAsStateWithLifecycle()
    val account by viewModel.account.collectAsStateWithLifecycle()
    val signOutFailed by viewModel.signOutFailed.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val version = remember(context) {
        val info = context.packageManager.getPackageInfo(context.packageName, 0)
        "${info.versionName.orEmpty()} (${PackageInfoCompat.getLongVersionCode(info)})"
    }
    var actionFailed by rememberSaveable { mutableStateOf(false) }
    SettingsContent(state, account, signOutFailed || actionFailed, version,
        preferences::language, preferences::appearance, onSignIn, viewModel::signOut, preferences::retry, onNotifications = preferences::notifications, identity = identity, onKarePlus = onKarePlus, onAction = { action ->
        val intent = when(action) {
            SettingsAction.NOTIFICATIONS -> Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            SettingsAction.PRIVACY -> Intent(Intent.ACTION_VIEW, "https://kare.erdendereli.com/privacy".toUri())
            SettingsAction.SUPPORT -> Intent(Intent.ACTION_VIEW, "https://kare.erdendereli.com/support".toUri())
        }
        try { context.startActivity(intent); actionFailed = false }
        catch (_: android.content.ActivityNotFoundException) { actionFailed = true }
    })
}

enum class SettingsAction { NOTIFICATIONS, PRIVACY, SUPPORT }

@Composable
fun SettingsContent(state: PreferencesUiState, account: AuthState, actionFailed: Boolean, version: String,
    onLanguage: (AppLanguage) -> Unit, onAppearance: (AppAppearance) -> Unit,
    onSignIn: () -> Unit, onSignOut: () -> Unit, onRetry: () -> Unit, onAction: (SettingsAction) -> Unit,
    onNotifications: (Boolean) -> Unit = {}, identity: UserProfile = UserProfile(), onKarePlus: () -> Unit = {}) {
    val prefs = (state.startup as? StartupState.Loaded)?.preferences ?: return
    val notificationLabel = stringResource(R.string.settings_notification_preference)
    var guide by rememberSaveable { mutableStateOf(false) }
    Column(Modifier.fillMaxSize().widthIn(max = KareLayout.readableWidth).verticalScroll(rememberScrollState())
        .padding(KareSpacing.lg).testTag("settings-content"), verticalArrangement = Arrangement.spacedBy(KareSpacing.md)) {
        PreferenceHeading(stringResource(R.string.settings_title))
        state.error?.let {
            PreferenceErrorText(it)
            if(it == PreferenceError.READ) TextButton(onClick = onRetry) { Text(stringResource(R.string.action_retry)) }
        }
        PreferenceHeading(stringResource(R.string.settings_appearance))
        Column(Modifier.selectableGroup()) {
            AppAppearance.entries.forEach { option -> PreferenceChoice(stringResource(when(option) {
                AppAppearance.SYSTEM -> R.string.appearance_system
                AppAppearance.LIGHT -> R.string.appearance_light
                AppAppearance.DARK -> R.string.appearance_dark
            }), prefs.appearance == option, !state.saving && !state.sessionOnly, "appearance-${option.name}", { onAppearance(option) }) }
        }
        HorizontalDivider()
        PreferenceHeading(stringResource(R.string.settings_language))
        LanguageChoices(prefs.language, !state.saving && !state.sessionOnly, onLanguage)
        Text(stringResource(R.string.preferences_widget_language), style = MaterialTheme.typography.bodySmall)
        HorizontalDivider()
        PreferenceHeading(stringResource(R.string.settings_account))
        if (account is AuthState.Authenticated) {
            Text(identity.displayName.ifBlank { account.user.displayName ?: account.user.email })
            if (identity.username.isNotBlank()) Text("@${identity.username}")
            Text(stringResource(R.string.settings_delete_unavailable))
            TextButton(onClick = onSignOut, modifier = Modifier.testTag("settings-sign-out")) { Text(stringResource(R.string.auth_sign_out_action)) }
        } else {
            Text(stringResource(R.string.settings_guest))
            Button(onClick = onSignIn, modifier = Modifier.testTag("settings-sign-in")) { Text(stringResource(R.string.auth_sign_in_action)) }
        }
        if (actionFailed) Text(stringResource(R.string.settings_action_failed), color = MaterialTheme.colorScheme.error,
            modifier = Modifier.semantics { liveRegion = androidx.compose.ui.semantics.LiveRegionMode.Polite })
        HorizontalDivider()
        PreferenceHeading(stringResource(R.string.section_plus_title))
        Button(onClick = onKarePlus, modifier = Modifier.testTag("settings-kare-plus")) { Text(stringResource(R.string.plus_open)) }
        HorizontalDivider()
        PreferenceHeading(stringResource(R.string.settings_notification_preference))
        Row(Modifier.fillMaxWidth(), verticalAlignment = androidx.compose.ui.Alignment.CenterVertically) {
            Text(stringResource(R.string.settings_notification_preference), Modifier.weight(1f))
            Switch(checked = prefs.notificationsEnabled, onCheckedChange = onNotifications,
                enabled = !state.saving && !state.sessionOnly,
                modifier = Modifier.testTag("settings-notification-preference").semantics {
                    contentDescription = notificationLabel
                })
        }
        Text(stringResource(R.string.settings_notification_note), style = MaterialTheme.typography.bodySmall)
        PreferenceHeading(stringResource(R.string.settings_about))
        TextButton(onClick = { guide = !guide }, modifier = Modifier.testTag("settings-widget-guide")) { Text(stringResource(R.string.settings_widget_guide)) }
        if (guide) Text(stringResource(R.string.settings_widget_guide_body))
        SettingsAction.entries.forEach { action -> TextButton(onClick = { onAction(action) }) { Text(stringResource(when(action) {
            SettingsAction.NOTIFICATIONS -> R.string.settings_notifications
            SettingsAction.PRIVACY -> R.string.settings_privacy
            SettingsAction.SUPPORT -> R.string.settings_help
        })) } }
        Text(stringResource(R.string.settings_version, version), style = MaterialTheme.typography.bodySmall)
    }
}
