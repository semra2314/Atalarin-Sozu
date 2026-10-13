package com.example.kare.feature.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.R
import com.example.kare.core.design.KareDesign
import com.example.kare.core.design.KareSerif
import com.example.kare.core.model.AppLanguage
import com.example.kare.core.model.AppTheme

@Composable
fun SettingsRoute(
    viewModel: SettingsViewModel,
    modifier: Modifier = Modifier,
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showLanguageSheet by remember { mutableStateOf(false) }
    var showAppearanceSheet by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }

    SettingsScreen(
        uiState = uiState,
        onAppearanceClick = { showAppearanceSheet = true },
        onLanguageClick = { showLanguageSheet = true },
        onSignOutClick = { viewModel.signOut() },
        onDeleteAccountClick = { showDeleteDialog = true },
        modifier = modifier,
    )

    if (showLanguageSheet) {
        LanguagePickerSheet(
            currentLanguage = uiState.currentLanguage,
            onDismiss = { showLanguageSheet = false },
            onSelectLanguage = { viewModel.setLanguage(it) },
        )
    }

    if (showAppearanceSheet) {
        AppearancePickerSheet(
            currentTheme = uiState.currentTheme,
            onDismiss = { showAppearanceSheet = false },
            onSelectTheme = { viewModel.setTheme(it) },
        )
    }

    if (showDeleteDialog) {
        DeleteAccountDialog(
            onDismiss = { showDeleteDialog = false },
            onConfirmDelete = { password ->
                showDeleteDialog = false
                viewModel.deleteAccount(password)
            },
        )
    }
}

@Composable
fun SettingsScreen(
    uiState: SettingsUiState,
    onAppearanceClick: () -> Unit,
    onLanguageClick: () -> Unit,
    onSignOutClick: () -> Unit,
    onDeleteAccountClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = KareDesign.colors
    var notificationsEnabled by remember { mutableStateOf(true) }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .background(colors.background)
            .padding(horizontal = 20.dp),
    ) {
        item {
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = stringResource(R.string.settings_title),
                style = MaterialTheme.typography.headlineMedium,
                fontFamily = KareSerif,
                color = colors.textPrimary,
            )
            Spacer(modifier = Modifier.height(24.dp))

            // General Section
            SettingsSectionHeader(stringResource(R.string.settings_section_general))
            Spacer(modifier = Modifier.height(8.dp))
            SettingsGroupCard {
                SettingsRow(
                    title = stringResource(R.string.settings_appearance),
                    subtitle = when (uiState.currentTheme) {
                        AppTheme.SYSTEM -> stringResource(R.string.settings_theme_system)
                        AppTheme.LIGHT -> stringResource(R.string.settings_theme_light)
                        AppTheme.DARK -> stringResource(R.string.settings_theme_dark)
                    },
                    onClick = onAppearanceClick,
                )
                SettingsDivider()
                SettingsRow(
                    title = stringResource(R.string.settings_language),
                    subtitle = when (uiState.currentLanguage) {
                        AppLanguage.SYSTEM -> stringResource(R.string.settings_lang_system)
                        AppLanguage.EN -> stringResource(R.string.settings_lang_en)
                        AppLanguage.TR -> stringResource(R.string.settings_lang_tr)
                    },
                    onClick = onLanguageClick,
                )
                SettingsDivider()
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text(
                        text = stringResource(R.string.settings_notifications),
                        style = MaterialTheme.typography.bodyLarge,
                        color = colors.textPrimary,
                    )
                    Switch(
                        checked = notificationsEnabled,
                        onCheckedChange = { notificationsEnabled = it },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = colors.onInk,
                            checkedTrackColor = colors.accent,
                        ),
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Account Section
            SettingsSectionHeader(stringResource(R.string.settings_section_account))
            Spacer(modifier = Modifier.height(8.dp))
            SettingsGroupCard {
                if (uiState.hasAccount) {
                    SettingsRow(
                        title = stringResource(R.string.settings_sign_out),
                        onClick = onSignOutClick,
                        showChevron = false,
                    )
                    SettingsDivider()
                    SettingsRow(
                        title = stringResource(R.string.settings_delete_account),
                        onClick = onDeleteAccountClick,
                        titleColor = MaterialTheme.colorScheme.error,
                        showChevron = false,
                    )
                } else {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                    ) {
                        Text(
                            text = stringResource(R.string.profile_guest_claim_title),
                            style = MaterialTheme.typography.bodyMedium,
                            color = colors.textSecondary,
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Support & Legal Section
            SettingsSectionHeader(stringResource(R.string.settings_section_support))
            Spacer(modifier = Modifier.height(8.dp))
            SettingsGroupCard {
                SettingsRow(
                    title = stringResource(R.string.settings_privacy_policy),
                    onClick = {},
                )
                SettingsDivider()
                SettingsRow(
                    title = stringResource(R.string.settings_help_support),
                    onClick = {},
                )
            }

            Spacer(modifier = Modifier.height(36.dp))

            // Footer
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                Text(
                    text = "KARE",
                    fontFamily = KareSerif,
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp,
                    color = colors.textPrimary.copy(alpha = 0.4f),
                    letterSpacing = 4.sp,
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = "VERSION ${uiState.appVersion}",
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.textSecondary.copy(alpha = 0.5f),
                    letterSpacing = 1.sp,
                )
            }

            Spacer(modifier = Modifier.height(48.dp))
        }
    }
}

@Composable
private fun SettingsSectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.labelLarge,
        color = KareDesign.colors.accent,
        fontWeight = FontWeight.Bold,
        modifier = Modifier.padding(start = 4.dp),
    )
}

@Composable
private fun SettingsGroupCard(content: @Composable () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(KareDesign.colors.surfaceMuted.copy(alpha = 0.8f)),
    ) {
        content()
    }
}

@Composable
private fun SettingsRow(
    title: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    subtitle: String? = null,
    titleColor: androidx.compose.ui.graphics.Color = KareDesign.colors.textPrimary,
    showChevron: Boolean = true,
) {
    val colors = KareDesign.colors
    Row(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.bodyLarge,
            color = titleColor,
        )
        Row(verticalAlignment = Alignment.CenterVertically) {
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium,
                    color = colors.textSecondary,
                    modifier = Modifier.padding(end = 6.dp),
                )
            }
            if (showChevron) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.KeyboardArrowRight,
                    contentDescription = null,
                    tint = colors.textSecondary.copy(alpha = 0.6f),
                )
            }
        }
    }
}

@Composable
private fun SettingsDivider() {
    HorizontalDivider(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp),
        color = KareDesign.colors.border.copy(alpha = 0.5f),
    )
}
