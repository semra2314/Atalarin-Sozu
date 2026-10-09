package com.example.kare.feature.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import com.example.kare.R
import com.example.kare.core.design.KareDesign
import com.example.kare.core.design.KareSpacing
import com.example.kare.core.design.KareTextStyles

/**
 * Modal dialog for requesting a password reset email.
 */
@Composable
fun ForgotPasswordDialog(
    onDismissRequest: () -> Unit,
    onSubmit: (email: String) -> Unit,
    isLoading: Boolean,
    error: AuthError?,
    isSuccess: Boolean,
    modifier: Modifier = Modifier,
) {
    var email by remember { mutableStateOf("") }

    Dialog(onDismissRequest = onDismissRequest) {
        Surface(
            shape = RoundedCornerShape(24.dp),
            color = KareDesign.colors.surface,
            tonalElevation = 6.dp,
            modifier = modifier
                .fillMaxWidth()
                .padding(KareSpacing.md)
                .testTag("forgot-password-dialog")
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(KareSpacing.lg),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(KareSpacing.md)
            ) {
                Text(
                    text = stringResource(R.string.auth_reset_password_title),
                    style = KareTextStyles.headlineSmall,
                    color = KareDesign.colors.textPrimary
                )

                Text(
                    text = stringResource(R.string.auth_reset_password_desc),
                    style = KareTextStyles.body,
                    color = KareDesign.colors.textSecondary
                )

                if (isSuccess) {
                    Text(
                        text = stringResource(R.string.auth_reset_link_sent),
                        style = KareTextStyles.body.copy(fontWeight = FontWeight.Medium),
                        color = KareDesign.colors.accent,
                        modifier = Modifier
                            .padding(vertical = KareSpacing.sm)
                            .testTag("reset-password-success-text")
                    )

                    AuthButton(
                        text = "OK",
                        onClick = onDismissRequest,
                        testTag = "forgot-password-dismiss-button"
                    )
                } else {
                    AuthErrorBanner(error = error)

                    AuthTextField(
                        value = email,
                        onValueChange = { email = it },
                        label = stringResource(R.string.auth_email_label),
                        keyboardType = KeyboardType.Email,
                        imeAction = ImeAction.Done,
                        onImeAction = { if (email.isNotBlank()) onSubmit(email) },
                        testTag = "forgot-password-email-input"
                    )

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(KareSpacing.sm)
                    ) {
                        TextButton(
                            onClick = onDismissRequest,
                            modifier = Modifier.weight(1f)
                        ) {
                            Text(
                                text = "Cancel",
                                color = KareDesign.colors.textSecondary,
                                style = KareTextStyles.body
                            )
                        }

                        AuthButton(
                            text = stringResource(R.string.auth_send_reset_link),
                            onClick = { onSubmit(email) },
                            loading = isLoading,
                            enabled = email.isNotBlank(),
                            modifier = Modifier.weight(2f),
                            testTag = "forgot-password-submit-button"
                        )
                    }
                }
            }
        }
    }
}
