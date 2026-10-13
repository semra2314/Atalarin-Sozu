package com.example.kare.feature.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.R
import com.example.kare.core.design.KareDesign
import com.example.kare.core.design.KareSerif
import com.example.kare.core.model.InstalledWidget

@Composable
fun ProfileRoute(
    viewModel: ProfileViewModel,
    onNavigateToSignIn: () -> Unit,
    onNavigateToTemplate: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    var showEditSheet by remember { mutableStateOf(false) }

    ProfileScreen(
        uiState = uiState,
        onEditClick = { showEditSheet = true },
        onSignInClick = onNavigateToSignIn,
        onToggleFavorite = { viewModel.toggleFavorite(it) },
        onTemplateClick = onNavigateToTemplate,
        modifier = modifier,
    )

    if (showEditSheet) {
        EditProfileSheet(
            userProfile = uiState.userProfile,
            onDismiss = { showEditSheet = false },
            onSave = { name, username, avatarPath ->
                viewModel.updateProfile(name, username, avatarPath)
            },
        )
    }
}

@Composable
fun ProfileScreen(
    uiState: ProfileUiState,
    onEditClick: () -> Unit,
    onSignInClick: () -> Unit,
    onToggleFavorite: (InstalledWidget) -> Unit,
    onTemplateClick: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = KareDesign.colors

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .background(colors.background)
            .padding(horizontal = 20.dp),
    ) {
        item {
            Spacer(modifier = Modifier.height(16.dp))
            // Top Bar
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(
                    text = stringResource(R.string.profile_title),
                    style = MaterialTheme.typography.headlineMedium,
                    fontFamily = KareSerif,
                    color = colors.textPrimary,
                )
                Button(
                    onClick = onEditClick,
                    colors = ButtonDefaults.buttonColors(
                        containerColor = colors.accent.copy(alpha = 0.12f),
                        contentColor = colors.accent,
                    ),
                    shape = RoundedCornerShape(10.dp),
                ) {
                    Text(
                        text = stringResource(R.string.profile_edit_action),
                        style = MaterialTheme.typography.labelMedium,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Avatar & Name Card
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                ProfileAvatar(
                    name = uiState.userProfile.displayName,
                    avatarPath = uiState.userProfile.avatarPath,
                    size = 84.dp,
                )

                Spacer(modifier = Modifier.height(12.dp))

                Text(
                    text = uiState.userProfile.displayName.ifBlank { "Kare User" },
                    style = MaterialTheme.typography.titleLarge,
                    fontFamily = KareSerif,
                    color = colors.textPrimary,
                )

                if (uiState.userProfile.username.isNotBlank()) {
                    Text(
                        text = "@${uiState.userProfile.username}",
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textSecondary,
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Guest Claim Banner
            if (uiState.isGuest) {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = colors.accent.copy(alpha = 0.1f),
                    ),
                ) {
                    Column(modifier = Modifier.padding(18.dp)) {
                        Text(
                            text = stringResource(R.string.profile_guest_claim_title),
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = colors.accent,
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = stringResource(R.string.profile_guest_claim_subtitle),
                            style = MaterialTheme.typography.bodySmall,
                            color = colors.textSecondary,
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        Button(
                            onClick = onSignInClick,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = colors.accent,
                                contentColor = colors.onInk,
                            ),
                            shape = RoundedCornerShape(10.dp),
                        ) {
                            Text(stringResource(R.string.profile_guest_sign_in_button))
                        }
                    }
                }
                Spacer(modifier = Modifier.height(24.dp))
            }

            // Stats Row
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(colors.surfaceMuted.copy(alpha = 0.8f))
                    .padding(vertical = 16.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                StatItem(label = stringResource(R.string.profile_stat_widgets), count = uiState.widgetCount)
                VerticalDivider(
                    modifier = Modifier
                        .height(30.dp)
                        .width(1.dp),
                    color = colors.border.copy(alpha = 0.6f),
                )
                StatItem(label = stringResource(R.string.profile_stat_made), count = 0)
                VerticalDivider(
                    modifier = Modifier
                        .height(30.dp)
                        .width(1.dp),
                    color = colors.border.copy(alpha = 0.6f),
                )
                StatItem(label = stringResource(R.string.profile_stat_favorites), count = uiState.favoritesCount)
            }

            Spacer(modifier = Modifier.height(32.dp))

            Text(
                text = stringResource(R.string.profile_section_favorites),
                style = MaterialTheme.typography.titleMedium,
                fontFamily = KareSerif,
                color = colors.textPrimary,
            )

            Spacer(modifier = Modifier.height(12.dp))
        }

        if (uiState.favoriteWidgets.isEmpty()) {
            item {
                Text(
                    text = stringResource(R.string.profile_empty_favorites),
                    style = MaterialTheme.typography.bodyMedium,
                    color = KareDesign.colors.textSecondary,
                    modifier = Modifier.padding(vertical = 12.dp),
                )
            }
        } else {
            items(uiState.favoriteWidgets, key = { it.templateId }) { widget ->
                FavoriteWidgetRow(
                    widget = widget,
                    onClick = { onTemplateClick(widget.templateId) },
                    onToggleFavorite = { onToggleFavorite(widget) },
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
        }

        item {
            Spacer(modifier = Modifier.height(24.dp))
            Text(
                text = stringResource(R.string.profile_section_my_widgets),
                style = MaterialTheme.typography.titleMedium,
                fontFamily = KareSerif,
                color = KareDesign.colors.textPrimary,
            )
            Spacer(modifier = Modifier.height(12.dp))
        }

        if (uiState.myWidgets.isEmpty()) {
            item {
                Text(
                    text = stringResource(R.string.profile_empty_my_widgets),
                    style = MaterialTheme.typography.bodyMedium,
                    color = KareDesign.colors.textSecondary,
                    modifier = Modifier.padding(vertical = 12.dp),
                )
            }
        } else {
            items(uiState.myWidgets, key = { "my_${it.templateId}" }) { widget ->
                FavoriteWidgetRow(
                    widget = widget,
                    onClick = { onTemplateClick(widget.templateId) },
                    onToggleFavorite = { onToggleFavorite(widget) },
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
        }

        item {
            Spacer(modifier = Modifier.height(40.dp))
        }
    }
}

@Composable
private fun StatItem(label: String, count: Int) {
    val colors = KareDesign.colors
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            text = count.toString(),
            style = MaterialTheme.typography.titleLarge,
            fontFamily = KareSerif,
            fontWeight = FontWeight.Bold,
            color = colors.textPrimary,
        )
        Spacer(modifier = Modifier.height(2.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = colors.textSecondary,
        )
    }
}

@Composable
private fun FavoriteWidgetRow(
    widget: InstalledWidget,
    onClick: () -> Unit,
    onToggleFavorite: () -> Unit,
) {
    val colors = KareDesign.colors
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(colors.surfaceMuted.copy(alpha = 0.6f))
            .clickable(onClick = onClick)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = widget.name,
                style = MaterialTheme.typography.bodyLarge,
                fontWeight = FontWeight.SemiBold,
                color = colors.textPrimary,
            )
            Text(
                text = "${widget.authorName} • ${widget.size.name}",
                style = MaterialTheme.typography.bodySmall,
                color = colors.textSecondary,
            )
        }
        IconButton(onClick = onToggleFavorite) {
            Icon(
                imageVector = if (widget.isFavorite) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                contentDescription = "Favorite",
                tint = if (widget.isFavorite) Color(0xFFE53935) else colors.textSecondary,
            )
        }
    }
}
