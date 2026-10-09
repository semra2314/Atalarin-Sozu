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
 * Stateful entry route for the Sign Up / Account Creation screen.
 */
@Composable
fun SignUpRoute(
    viewModel: AuthViewModel,
    onNavigateToSignIn: () -> Unit,
    onSignUpSuccess: () -> Unit,
    onBack: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    LaunchedEffect(uiState.isAuthenticated) {
        if (uiState.isAuthenticated) {
            onSignUpSuccess()
        }
    }

    SignUpContent(
        uiState = uiState,
        onSignUp = { name, email, pass -> viewModel.register(name, email, pass) },
        onNavigateToSignIn = onNavigateToSignIn,
        onBack = onBack,
        modifier = modifier
    )
}

/**
 * Pure presentation component for Sign Up.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SignUpContent(
    uiState: AuthUiState,
    onSignUp: (name: String, email: String, pass: String) -> Unit,
    onNavigateToSignIn: () -> Unit,
    onBack: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
) {
    var name by remember { mutableStateOf("") }
    var email by remember { mutableStateOf("") }
    var password by remember { mutableStateOf("") }

    val canSubmit = name.isNotBlank() && email.isNotBlank() && password.length >= 6

    Scaffold(
        topBar = {
            if (onBack != null) {
                TopAppBar(
                    title = {},
                    navigationIcon = {
                        IconButton(
                            onClick = onBack,
                            modifier = Modifier.testTag("auth-sign-up-back")
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
        modifier = modifier.testTag("sign-up-screen")
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
                        text = stringResource(R.string.auth_sign_up_title),
                        style = KareTextStyles.display,
                        color = KareDesign.colors.textPrimary,
                        modifier = Modifier.testTag("sign-up-header")
                    )
                    Text(
                        text = stringResource(R.string.auth_sign_up_subtitle),
                        style = KareTextStyles.body,
                        color = KareDesign.colors.textSecondary
                    )
                }

                // Error banner
                AuthErrorBanner(
                    error = uiState.lastError,
                    testTag = "sign-up-error-banner"
                )

                // Input fields
                Column(verticalArrangement = Arrangement.spacedBy(KareSpacing.md)) {
                    AuthTextField(
                        value = name,
                        onValueChange = { name = it },
                        label = stringResource(R.string.auth_name_label),
                        keyboardType = KeyboardType.Text,
                        imeAction = ImeAction.Next,
                        testTag = "sign-up-name-input"
                    )

                    AuthTextField(
                        value = email,
                        onValueChange = { email = it },
                        label = stringResource(R.string.auth_email_label),
                        keyboardType = KeyboardType.Email,
                        imeAction = ImeAction.Next,
                        testTag = "sign-up-email-input"
                    )

                    PasswordTextField(
                        value = password,
                        onValueChange = { password = it },
                        label = stringResource(R.string.auth_password_label),
                        imeAction = ImeAction.Done,
                        onImeAction = {
                            if (canSubmit) {
                                onSignUp(name, email, password)
                            }
                        },
                        testTag = "sign-up-password-input"
                    )

                    // Password hint
                    Text(
                        text = stringResource(R.string.auth_error_weak_password),
                        style = KareTextStyles.label,
                        color = if (password.isNotEmpty() && password.length < 6) KareDesign.colors.accent else KareDesign.colors.textSecondary,
                        modifier = Modifier.padding(start = KareSpacing.xs)
                    )
                }

                // Create account submit button
                AuthButton(
                    text = stringResource(R.string.auth_sign_up_action),
                    onClick = { onSignUp(name, email, password) },
                    loading = uiState.isLoading,
                    enabled = canSubmit,
                    testTag = "sign-up-submit-button"
                )

                // Switch to Sign In prompt
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center
                ) {
                    TextButton(
                        onClick = onNavigateToSignIn,
                        modifier = Modifier.testTag("sign-up-go-to-sign-in-button")
                    ) {
                        Text(
                            text = stringResource(R.string.auth_have_account_prompt),
                            style = KareTextStyles.body.copy(fontWeight = FontWeight.Medium),
                            color = KareDesign.colors.textPrimary
                        )
                    }
                }
            }
        }
    }
}
