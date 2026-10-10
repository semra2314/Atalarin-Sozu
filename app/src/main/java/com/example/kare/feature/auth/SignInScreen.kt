package com.example.kare.feature.auth

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
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
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.R
import com.example.kare.core.design.KareDesign
import com.example.kare.core.design.KareLayout
import com.example.kare.core.design.KareSpacing
import com.example.kare.core.design.KareTextStyles

/**
 * Stateful entry route for the Sign In screen.
 */
@Composable
fun SignInRoute(
    viewModel: AuthViewModel,
    onNavigateToSignUp: () -> Unit,
    onSignInSuccess: () -> Unit,
    onBack: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    LaunchedEffect(uiState.isAuthenticated) {
        if (uiState.isAuthenticated) {
            onSignInSuccess()
        }
    }

    SignInContent(
        uiState = uiState,
        onSignIn = { email, pass -> viewModel.signIn(email, pass) },
        onResetPassword = { email -> viewModel.resetPassword(email) },
        onClearAction = { viewModel.clearActionState() },
        onNavigateToSignUp = onNavigateToSignUp,
        onBack = onBack,
        modifier = modifier
    )
}

/**
 * Pure presentation component for Sign In.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SignInContent(
    uiState: AuthUiState,
    onSignIn: (email: String, pass: String) -> Unit,
    onResetPassword: (email: String) -> Unit,
    onClearAction: () -> Unit,
    onNavigateToSignUp: () -> Unit,
    onBack: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }
    var showForgotDialog by remember { mutableStateOf(false) }

    val isResetSuccess = (uiState.actionState as? AuthActionState.Success)?.type == AuthSuccessType.PASSWORD_RESET

    if (showForgotDialog) {
        ForgotPasswordDialog(
            onDismissRequest = {
                showForgotDialog = false
                onClearAction()
            },
            onSubmit = onResetPassword,
            isLoading = uiState.isLoading,
            error = uiState.lastError,
            isSuccess = isResetSuccess
        )
    }

    Scaffold(
        topBar = {
            if (onBack != null) {
                TopAppBar(
                    title = {},
                    navigationIcon = {
                        IconButton(
                            onClick = onBack,
                            modifier = Modifier.testTag("auth-sign-in-back")
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = "Back",
                                tint = KareDesign.colors.textPrimary
                            )
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = KareDesign.colors.background)
                )
            }
        },
        containerColor = KareDesign.colors.background,
        modifier = modifier.testTag("sign-in-screen")
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentAlignment = Alignment.TopCenter
        ) {
            Column(
                modifier = Modifier
                    .widthIn(max = KareLayout.readableWidth)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = KareSpacing.lg, vertical = KareSpacing.md),
                horizontalAlignment = Alignment.Start,
                verticalArrangement = Arrangement.spacedBy(KareSpacing.lg)
            ) {
                // Header
                Column(verticalArrangement = Arrangement.spacedBy(KareSpacing.xs)) {
                    Text(
                        text = stringResource(R.string.auth_sign_in_title),
                        style = KareTextStyles.display,
                        color = KareDesign.colors.textPrimary,
                        modifier = Modifier.testTag("sign-in-header")
                    )
                    Text(
                        text = stringResource(R.string.auth_sign_in_subtitle),
                        style = KareTextStyles.body,
                        color = KareDesign.colors.textSecondary
                    )
                }

                // Error banner
                AuthErrorBanner(
                    error = uiState.lastError,
                    testTag = "sign-in-error-banner"
                )

                // Input fields
                Column(verticalArrangement = Arrangement.spacedBy(KareSpacing.md)) {
                    AuthTextField(
                        value = email,
                        onValueChange = { email = it },
                        label = stringResource(R.string.auth_email_label),
                        keyboardType = KeyboardType.Email,
                        imeAction = ImeAction.Next,
                        testTag = "sign-in-email-input"
                    )

                    PasswordTextField(
                        value = password,
                        onValueChange = { password = it },
                        label = stringResource(R.string.auth_password_label),
                        imeAction = ImeAction.Done,
                        onImeAction = {
                            if (email.isNotBlank() && password.isNotBlank()) {
                                onSignIn(email, password)
                            }
                        },
                        testTag = "sign-in-password-input"
                    )

                    // Forgot password link
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End
                    ) {
                        TextButton(
                            onClick = { showForgotDialog = true },
                            modifier = Modifier.testTag("sign-in-forgot-password-button")
                        ) {
                            Text(
                                text = stringResource(R.string.auth_forgot_password_action),
                                style = KareTextStyles.label,
                                color = KareDesign.colors.accent
                            )
                        }
                    }
                }

                // Sign in submit button
                AuthButton(
                    text = stringResource(R.string.auth_sign_in_action),
                    onClick = { onSignIn(email, password) },
                    loading = uiState.isLoading,
                    enabled = email.isNotBlank() && password.isNotBlank(),
                    testTag = "sign-in-submit-button"
                )

                // Switch to Sign Up prompt
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center
                ) {
                    TextButton(
                        onClick = onNavigateToSignUp,
                        modifier = Modifier.testTag("sign-in-go-to-sign-up-button")
                    ) {
                        Text(
                            text = stringResource(R.string.auth_no_account_prompt),
                            style = KareTextStyles.body.copy(fontWeight = FontWeight.Medium),
                            color = KareDesign.colors.textPrimary
                        )
                    }
                }
            }
        }
    }
}
