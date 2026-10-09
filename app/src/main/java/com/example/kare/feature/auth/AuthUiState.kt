package com.example.kare.feature.auth

import com.example.kare.core.model.AuthState
import com.example.kare.core.model.AuthUser

/**
 * Semantic error identifiers for authentication failures.
 *
 * Specific UI copy and localization belong entirely in the presentation layer,
 * never hardcoded in ViewModels or domain models.
 */
enum class AuthError {
    INVALID_CREDENTIALS,
    EMAIL_ALREADY_IN_USE,
    WEAK_PASSWORD,
    USER_NOT_FOUND,
    USER_DISABLED,
    TOO_MANY_REQUESTS,
    NETWORK,
    UNAVAILABLE,
    INVALID_INPUT,
    UNAUTHENTICATED,
    UNEXPECTED,
}

/**
 * Distinguishes the category of a successfully completed user action.
 */
enum class AuthSuccessType {
    SIGN_IN,
    REGISTRATION,
    SIGN_OUT,
    PASSWORD_RESET,
}

/**
 * Transient state of a user-initiated authentication operation.
 */
sealed interface AuthActionState {
    /** No operation is in flight. */
    data object Idle : AuthActionState

    /** An asynchronous authentication operation is running. */
    data object Loading : AuthActionState

    /** An authentication operation completed successfully. */
    data class Success(val type: AuthSuccessType, val user: AuthUser? = null) : AuthActionState

    /** An authentication operation failed with a recoverable semantic error. */
    data class Error(val error: AuthError) : AuthActionState
}

/**
 * Immutable UI state for the authentication feature.
 *
 * Exposes clear states for:
 * - Unauthenticated: `session is AuthState.Unauthenticated`
 * - Authenticated: `session is AuthState.Authenticated`
 * - Loading: `actionState is AuthActionState.Loading`
 * - Recoverable failure: `actionState is AuthActionState.Error`
 *
 * @property session Authoritative session state observed from [AuthRepository].
 * @property actionState Transient execution state of interactive actions.
 */
data class AuthUiState(
    val session: AuthState = AuthState.Unauthenticated,
    val actionState: AuthActionState = AuthActionState.Idle,
) {
    /** Whether an active authenticated user session is established. */
    val isAuthenticated: Boolean get() = session is AuthState.Authenticated

    /** The authenticated user if available, or null. */
    val currentUser: AuthUser? get() = (session as? AuthState.Authenticated)?.user

    /** Whether an action is currently executing in the background. */
    val isLoading: Boolean get() = actionState is AuthActionState.Loading

    /** The last recoverable error, if any. */
    val lastError: AuthError? get() = (actionState as? AuthActionState.Error)?.error
}
