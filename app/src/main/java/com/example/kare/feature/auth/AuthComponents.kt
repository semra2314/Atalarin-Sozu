package com.example.kare.feature.auth

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import com.example.kare.R
import com.example.kare.core.design.KareDesign
import com.example.kare.core.design.KareSpacing
import com.example.kare.core.design.KareTextStyles

/**
 * Maps semantic domain [AuthError] to localized Android string resource ID.
 */
fun AuthError.toLocalizedStringRes(): Int = when (this) {
    AuthError.INVALID_CREDENTIALS -> R.string.auth_error_invalid_credentials
    AuthError.EMAIL_ALREADY_IN_USE -> R.string.auth_error_email_already_in_use
    AuthError.WEAK_PASSWORD -> R.string.auth_error_weak_password
    AuthError.USER_NOT_FOUND -> R.string.auth_error_user_not_found
    AuthError.USER_DISABLED -> R.string.auth_error_user_disabled
    AuthError.TOO_MANY_REQUESTS -> R.string.auth_error_too_many_requests
    AuthError.NETWORK -> R.string.auth_error_network
    AuthError.UNAVAILABLE -> R.string.auth_error_unavailable
    AuthError.INVALID_INPUT -> R.string.auth_error_invalid_input
    AuthError.UNAUTHENTICATED -> R.string.auth_error_unauthenticated
    AuthError.UNEXPECTED -> R.string.auth_error_unexpected
}

/**
 * Branded input field matching Kare's warm surface and soft geometry.
 */
@Composable
fun AuthTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    keyboardType: KeyboardType = KeyboardType.Text,
    imeAction: ImeAction = ImeAction.Next,
    onImeAction: () -> Unit = {},
    leadingIcon: (@Composable () -> Unit)? = null,
    testTag: String = "auth-text-field",
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label, style = KareTextStyles.body) },
        leadingIcon = leadingIcon,
        singleLine = true,
        shape = RoundedCornerShape(14.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = KareDesign.colors.surface,
            unfocusedContainerColor = KareDesign.colors.surfaceMuted,
            focusedBorderColor = KareDesign.colors.accent,
            unfocusedBorderColor = KareDesign.colors.border,
            focusedTextColor = KareDesign.colors.textPrimary,
            unfocusedTextColor = KareDesign.colors.textPrimary,
            focusedLabelColor = KareDesign.colors.accent,
            unfocusedLabelColor = KareDesign.colors.textSecondary,
        ),
        keyboardOptions = KeyboardOptions(keyboardType = keyboardType, imeAction = imeAction),
        keyboardActions = KeyboardActions(
            onNext = { onImeAction() },
            onDone = { onImeAction() },
            onGo = { onImeAction() }
        ),
        modifier = modifier
            .fillMaxWidth()
            .testTag(testTag)
    )
}

/**
 * Branded password field with visibility toggle.
 */
@Composable
fun PasswordTextField(
    value: String,
    onValueChange: (String) -> Unit,
    label: String,
    modifier: Modifier = Modifier,
    imeAction: ImeAction = ImeAction.Done,
    onImeAction: () -> Unit = {},
    testTag: String = "auth-password-field",
) {
    var passwordVisible by remember { mutableStateOf(false) }

    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        label = { Text(label, style = KareTextStyles.body) },
        leadingIcon = {
            Icon(
                imageVector = Icons.Default.Lock,
                contentDescription = null,
                tint = KareDesign.colors.textSecondary
            )
        },
        trailingIcon = {
            TextButton(
                onClick = { passwordVisible = !passwordVisible },
                modifier = Modifier.testTag("auth-password-toggle")
            ) {
                Text(
                    text = if (passwordVisible) "Hide" else "Show",
                    style = KareTextStyles.label,
                    color = KareDesign.colors.accent
                )
            }
        },
        singleLine = true,
        visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
        shape = RoundedCornerShape(14.dp),
        colors = OutlinedTextFieldDefaults.colors(
            focusedContainerColor = KareDesign.colors.surface,
            unfocusedContainerColor = KareDesign.colors.surfaceMuted,
            focusedBorderColor = KareDesign.colors.accent,
            unfocusedBorderColor = KareDesign.colors.border,
            focusedTextColor = KareDesign.colors.textPrimary,
            unfocusedTextColor = KareDesign.colors.textPrimary,
            focusedLabelColor = KareDesign.colors.accent,
            unfocusedLabelColor = KareDesign.colors.textSecondary,
        ),
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password, imeAction = imeAction),
        keyboardActions = KeyboardActions(
            onDone = { onImeAction() },
            onGo = { onImeAction() }
        ),
        modifier = modifier
            .fillMaxWidth()
            .testTag(testTag)
    )
}

/**
 * Prominent coral action button with integrated loading spinner.
 */
@Composable
fun AuthButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    loading: Boolean = false,
    testTag: String = "auth-action-button",
) {
    Button(
        onClick = onClick,
        enabled = enabled && !loading,
        shape = RoundedCornerShape(16.dp),
        colors = ButtonDefaults.buttonColors(
            containerColor = KareDesign.colors.accent,
            contentColor = Color.White,
            disabledContainerColor = KareDesign.colors.surfaceMuted,
            disabledContentColor = KareDesign.colors.textSecondary
        ),
        contentPadding = PaddingValues(vertical = KareSpacing.md),
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 52.dp)
            .testTag(testTag)
    ) {
        if (loading) {
            CircularProgressIndicator(
                color = Color.White,
                strokeWidth = 2.5.dp,
                modifier = Modifier
                    .size(22.dp)
                    .testTag("auth-loading-spinner")
            )
        } else {
            Text(
                text = text,
                style = KareTextStyles.body.copy(fontWeight = FontWeight.Bold)
            )
        }
    }
}

/**
 * Animated error banner notifying user of a recoverable semantic issue.
 */
@Composable
fun AuthErrorBanner(
    error: AuthError?,
    modifier: Modifier = Modifier,
    testTag: String = "auth-error-banner",
) {
    AnimatedVisibility(
        visible = error != null,
        enter = fadeIn(),
        exit = fadeOut(),
        modifier = modifier
    ) {
        if (error != null) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(KareSpacing.sm),
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        color = KareDesign.colors.accentTint,
                        shape = RoundedCornerShape(12.dp)
                    )
                    .border(
                        width = 1.dp,
                        color = KareDesign.colors.accent.copy(alpha = 0.5f),
                        shape = RoundedCornerShape(12.dp)
                    )
                    .padding(KareSpacing.md)
                    .testTag(testTag)
            ) {
                Icon(
                    imageVector = Icons.Default.Warning,
                    contentDescription = null,
                    tint = KareDesign.colors.accent,
                    modifier = Modifier.size(20.dp)
                )
                Text(
                    text = stringResource(error.toLocalizedStringRes()),
                    style = KareTextStyles.body.copy(color = KareDesign.colors.textPrimary),
                    modifier = Modifier.weight(1f)
                )
            }
        }
    }
}
