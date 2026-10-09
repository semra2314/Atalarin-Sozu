package com.example.kare.feature.auth

import androidx.compose.runtime.mutableStateOf
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import com.example.kare.core.design.KareTheme
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@LooperMode(LooperMode.Mode.PAUSED)
class AuthScreensTest {

    @get:Rule
    val compose = createComposeRule()

    @Test
    fun signInContentRendersFieldsAndSubmitsCredentials() {
        var submittedEmail = ""
        var submittedPassword = ""
        var goToSignUpClicked = false

        compose.setContent {
            KareTheme {
                SignInContent(
                    uiState = AuthUiState(),
                    onSignIn = { email, pass ->
                        submittedEmail = email
                        submittedPassword = pass
                    },
                    onResetPassword = {},
                    onClearAction = {},
                    onNavigateToSignUp = { goToSignUpClicked = true },
                    onBack = null
                )
            }
        }

        compose.onNodeWithTag("sign-in-header").assertExists()
        compose.onNodeWithTag("sign-in-email-input").performTextInput("user@kare.app")
        compose.onNodeWithTag("sign-in-password-input").performTextInput("secret123")

        compose.onNodeWithTag("sign-in-submit-button").assertIsEnabled().performClick()
        assertEquals("user@kare.app", submittedEmail)
        assertEquals("secret123", submittedPassword)

        compose.onNodeWithTag("sign-in-go-to-sign-up-button").performClick()
        assertTrue(goToSignUpClicked)
    }

    @Test
    fun signInDisplaysErrorBannerWhenErrorPresent() {
        val state = AuthUiState(actionState = AuthActionState.Error(AuthError.INVALID_CREDENTIALS))

        compose.setContent {
            KareTheme {
                SignInContent(
                    uiState = state,
                    onSignIn = { _, _ -> },
                    onResetPassword = {},
                    onClearAction = {},
                    onNavigateToSignUp = {},
                    onBack = null
                )
            }
        }

        compose.onNodeWithTag("sign-in-error-banner").assertExists()
        compose.onNodeWithText("Email or password is wrong.").assertExists()
    }

    @Test
    fun signUpValidatesMinimumPasswordLength() {
        var submittedName = ""
        var submittedEmail = ""
        var submittedPassword = ""

        compose.setContent {
            KareTheme {
                SignUpContent(
                    uiState = AuthUiState(),
                    onSignUp = { name, email, pass ->
                        submittedName = name
                        submittedEmail = email
                        submittedPassword = pass
                    },
                    onNavigateToSignIn = {},
                    onBack = null
                )
            }
        }

        compose.onNodeWithTag("sign-up-header").assertExists()
        compose.onNodeWithTag("sign-up-name-input").performTextInput("Alice")
        compose.onNodeWithTag("sign-up-email-input").performTextInput("alice@kare.app")

        // 5 characters -> button should remain disabled
        compose.onNodeWithTag("sign-up-password-input").performTextInput("12345")
        compose.onNodeWithTag("sign-up-submit-button").assertIsNotEnabled()

        // 6 characters -> button becomes enabled
        compose.onNodeWithTag("sign-up-password-input").performTextInput("6")
        compose.onNodeWithTag("sign-up-submit-button").assertIsEnabled().performClick()

        assertEquals("Alice", submittedName)
        assertEquals("alice@kare.app", submittedEmail)
        assertEquals("123456", submittedPassword)
    }

    @Test
    fun forgotPasswordDialogSubmitsEmailAndShowsSuccess() {
        var submittedEmail = ""
        var dismissed = false
        val isSuccessState = mutableStateOf(false)

        compose.setContent {
            KareTheme {
                ForgotPasswordDialog(
                    onDismissRequest = { dismissed = true },
                    onSubmit = { submittedEmail = it },
                    isLoading = false,
                    error = null,
                    isSuccess = isSuccessState.value
                )
            }
        }

        compose.onNodeWithTag("forgot-password-dialog").assertExists()
        compose.onNodeWithTag("forgot-password-email-input").performTextInput("reset@kare.app")
        compose.onNodeWithTag("forgot-password-submit-button").performClick()
        assertEquals("reset@kare.app", submittedEmail)

        // Switch to success
        compose.runOnIdle { isSuccessState.value = true }
        compose.onNodeWithTag("reset-password-success-text").assertExists()
        compose.onNodeWithTag("forgot-password-dismiss-button").performClick()
        assertTrue(dismissed)
    }
}
