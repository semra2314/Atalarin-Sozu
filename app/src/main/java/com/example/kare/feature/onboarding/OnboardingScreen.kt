package com.example.kare.feature.onboarding

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Home
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.*
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
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
fun OnboardingContent(
    page: Int,
    preferences: AppPreferences,
    saving: Boolean,
    error: PreferenceError?,
    onNext: () -> Unit,
    onPrevious: () -> Unit,
    onComplete: () -> Unit,
    onLanguage: (com.example.kare.core.model.AppLanguage) -> Unit,
    onContinueForSession: () -> Unit,
) {
    val title = when (page) {
        0 -> R.string.onboarding_language
        1 -> R.string.onboarding_curated_title
        2 -> R.string.onboarding_yours_title
        else -> R.string.onboarding_home_title
    }

    Column(
        Modifier
            .fillMaxSize()
            .safeDrawingPadding()
            .widthIn(max = KareLayout.readableWidth)
            .verticalScroll(rememberScrollState())
            .padding(KareSpacing.xl)
            .testTag("onboarding-page-$page"),
        verticalArrangement = Arrangement.spacedBy(KareSpacing.lg),
    ) {
        // Brand header & live region page counter
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(stringResource(R.string.app_name), style = MaterialTheme.typography.displayMedium)
            Text(
                stringResource(R.string.onboarding_page, page + 1, 4),
                Modifier.semantics { liveRegion = LiveRegionMode.Polite },
                style = KareTextStyles.label,
                color = KareDesign.colors.textSecondary,
            )
        }

        // Animated page indicators
        Row(
            modifier = Modifier.padding(vertical = KareSpacing.xs),
            horizontalArrangement = Arrangement.spacedBy(6.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            repeat(4) { index ->
                val isSelected = index == page
                val width by animateDpAsState(
                    targetValue = if (isSelected) 24.dp else 8.dp,
                    label = "IndicatorWidth",
                )
                Box(
                    modifier = Modifier
                        .height(8.dp)
                        .width(width)
                        .clip(CircleShape)
                        .background(
                            if (isSelected) KareDesign.colors.accent else KareDesign.colors.border
                        ),
                )
            }
        }

        PreferenceHeading(stringResource(title))

        // Hero visuals depending on the current onboarding step
        when (page) {
            0 -> {
                LanguageChoices(preferences.language, !saving, onLanguage)
            }
            1 -> {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = KareSpacing.md),
                    contentAlignment = Alignment.Center,
                ) {
                    Slide1HeroVisual()
                }
                Text(
                    stringResource(R.string.onboarding_curated_body),
                    style = MaterialTheme.typography.bodyLarge,
                )
            }
            2 -> {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = KareSpacing.md),
                    contentAlignment = Alignment.Center,
                ) {
                    Slide2HeroVisual()
                }
                Text(
                    stringResource(R.string.onboarding_yours_body),
                    style = MaterialTheme.typography.bodyLarge,
                )
            }
            else -> {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = KareSpacing.md),
                    contentAlignment = Alignment.Center,
                ) {
                    Slide3HeroVisual()
                }
                Text(
                    stringResource(R.string.onboarding_home_body),
                    style = MaterialTheme.typography.bodyLarge,
                )
            }
        }

        error?.let { PreferenceErrorText(it) }

        // Action buttons
        Button(
            onClick = if (page == 3) onComplete else onNext,
            enabled = !saving,
            modifier = Modifier
                .fillMaxWidth()
                .testTag("onboarding-next"),
        ) {
            Text(stringResource(if (page == 3) R.string.onboarding_finish else R.string.action_continue))
        }

        if (page > 0) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                TextButton(onClick = onPrevious, enabled = !saving) {
                    Text(stringResource(R.string.onboarding_previous))
                }
                if (page < 3) {
                    TextButton(
                        onClick = onComplete,
                        enabled = !saving,
                        modifier = Modifier.testTag("onboarding-skip"),
                    ) {
                        Text(stringResource(R.string.onboarding_skip))
                    }
                }
            }
        }

        if (error != null) {
            TextButton(onClick = onContinueForSession, enabled = !saving) {
                Text(stringResource(R.string.preferences_session))
            }
        }

        Text(
            stringResource(R.string.onboarding_account_later),
            style = MaterialTheme.typography.bodySmall,
            color = KareDesign.colors.textSecondary,
        )
    }
}

// -------------------------------------------------------------------------
// HERO VISUALS
// -------------------------------------------------------------------------
@Composable
private fun Slide1HeroVisual() {
    Box(
        modifier = Modifier.size(240.dp),
        contentAlignment = Alignment.Center,
    ) {
        // Gradient coral card
        Surface(
            modifier = Modifier
                .size(150.dp)
                .offset(x = (-30).dp, y = (-20).dp)
                .shadow(16.dp, KareShapes.hero),
            shape = KareShapes.hero,
            color = Color.Transparent,
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.linearGradient(
                            listOf(Color(0xFFEA580C), Color(0xFFD44A33))
                        )
                    )
                    .padding(KareSpacing.md),
                contentAlignment = Alignment.BottomStart,
            ) {
                Text(
                    text = "Günün\nSözü",
                    style = KareTextStyles.headlineSmall,
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                )
            }
        }

        // Dark card
        Surface(
            modifier = Modifier
                .size(150.dp)
                .offset(x = 35.dp, y = 25.dp)
                .shadow(18.dp, KareShapes.hero),
            shape = KareShapes.hero,
            color = Color(0xFF1D1D1F),
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(KareSpacing.md),
                verticalArrangement = Arrangement.SpaceBetween,
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Box(
                        modifier = Modifier
                            .size(8.dp)
                            .clip(CircleShape)
                            .background(KareDesign.colors.accent)
                    )
                    Text(
                        text = "Hush",
                        style = KareTextStyles.title,
                        color = Color.White,
                    )
                }

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(6.dp)
                        .clip(CircleShape)
                        .background(Color.White.copy(alpha = 0.2f))
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth(0.6f)
                            .fillMaxHeight()
                            .clip(CircleShape)
                            .background(Color.White.copy(alpha = 0.8f))
                    )
                }
            }
        }
    }
}

@Composable
private fun Slide2HeroVisual() {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(KareSpacing.md),
    ) {
        Surface(
            modifier = Modifier
                .size(160.dp)
                .shadow(12.dp, KareShapes.hero),
            shape = KareShapes.hero,
            color = MaterialTheme.colorScheme.surface,
        ) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = "🎨",
                    fontSize = 52.sp,
                )
            }
        }

        Row(
            modifier = Modifier
                .clip(CircleShape)
                .background(MaterialTheme.colorScheme.surface)
                .border(1.dp, KareDesign.colors.border, CircleShape)
                .padding(horizontal = KareSpacing.md, vertical = KareSpacing.sm),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            listOf(
                Color(0xFFD44A33),
                Color(0xFF7C3AED),
                Color(0xFF2A6F97),
                Color(0xFF1D1D1F),
            ).forEach { c ->
                Box(
                    modifier = Modifier
                        .size(20.dp)
                        .clip(CircleShape)
                        .background(c)
                )
            }

            Text(
                text = "Aa",
                style = KareTextStyles.title,
                color = MaterialTheme.colorScheme.onSurface,
                modifier = Modifier.padding(start = 4.dp),
            )
        }
    }
}

@Composable
private fun Slide3HeroVisual() {
    Surface(
        modifier = Modifier
            .size(170.dp)
            .shadow(14.dp, KareShapes.hero),
        shape = KareShapes.hero,
        color = MaterialTheme.colorScheme.surface,
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(KareSpacing.lg),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Icon(
                imageVector = Icons.Default.Home,
                contentDescription = null,
                tint = KareDesign.colors.accent,
                modifier = Modifier.size(54.dp),
            )
            Spacer(modifier = Modifier.height(KareSpacing.sm))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = null,
                    tint = KareDesign.colors.accent,
                    modifier = Modifier.size(16.dp),
                )
                Text(
                    text = "Glance Widget",
                    style = KareTextStyles.label,
                    color = KareDesign.colors.textSecondary,
                )
            }
        }
    }
}
