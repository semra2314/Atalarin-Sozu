package com.example.kare.feature.auth

import androidx.annotation.MainThread
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.model.AuthState
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.AuthException
import com.example.kare.core.repository.AuthRepository
import com.example.kare.core.repository.RepositoryException
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

/**
 * Android ViewModel managing authentication state and user operations.
 *
 * Implements the dependency flow: UI -> ViewModel -> AuthRepository.
 * Maintains immutable [AuthUiState] backed by [StateFlow].
 *
 * Guarantees:
 * - Never converts [CancellationException] into a standard error.
 * - Protects against duplicate concurrent actions while an operation is in flight.
 * - Maps exceptions to semantic [AuthError] codes without localized strings.
 * - Forwards diagnostic exceptions to [ErrorReporter] if provided.
 */
class AuthViewModel(
    private val repository: AuthRepository,
    private val errorReporter: ErrorReporter? = null,
) : ViewModel() {

    private val _uiState = MutableStateFlow(
        AuthUiState(
            session = repository.currentUser?.let { AuthState.Authenticated(it) } ?: AuthState.Unauthenticated,
            actionState = AuthActionState.Idle,
        )
    )
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    private var activeJob: Job? = null

    init {
        // Observe repository auth state continuously for authoritative session updates.
        viewModelScope.launch {
            repository.authState.collect { sessionState ->
                _uiState.update { currentState ->
                    currentState.copy(session = sessionState)
                }
            }
        }
    }

    /**
     * Attempts sign in with email and password.
     *
     * In-flight requests are protected; duplicate clicks while loading are ignored.
     */
    @MainThread
    fun signIn(email: String, password: String) {
        val trimmedEmail = email.trim()
        if (trimmedEmail.isEmpty() || password.isEmpty()) {
            _uiState.update { it.copy(actionState = AuthActionState.Error(AuthError.INVALID_INPUT)) }
            return
        }

        executeAction("signIn") {
            val user = repository.signIn(trimmedEmail, password)
            AuthActionState.Success(AuthSuccessType.SIGN_IN, user)
        }
    }

    /**
     * Attempts to register a new account with the given display name, email, and password.
     */
    @MainThread
    fun register(name: String, email: String, password: String) {
        val trimmedName = name.trim()
        val trimmedEmail = email.trim()
        if (trimmedName.isEmpty() || trimmedEmail.isEmpty() || password.isEmpty()) {
            _uiState.update { it.copy(actionState = AuthActionState.Error(AuthError.INVALID_INPUT)) }
            return
        }

        executeAction("register") {
            val user = repository.register(trimmedName, trimmedEmail, password)
            AuthActionState.Success(AuthSuccessType.REGISTRATION, user)
        }
    }

    /**
     * Convenience alias for [register] matching the iOS signUp nomenclature.
     */
    @MainThread
    fun signUp(name: String, email: String, password: String) {
        register(name, email, password)
    }

    /**
     * Signs out the current active session.
     */
    @MainThread
    fun signOut() {
        executeAction("signOut") {
            repository.signOut()
            AuthActionState.Success(AuthSuccessType.SIGN_OUT)
        }
    }

    /**
     * Requests a password reset email for the given address.
     */
    @MainThread
    fun resetPassword(email: String) {
        val trimmedEmail = email.trim()
        if (trimmedEmail.isEmpty()) {
            _uiState.update { it.copy(actionState = AuthActionState.Error(AuthError.INVALID_INPUT)) }
            return
        }

        executeAction("resetPassword") {
            repository.resetPassword(trimmedEmail)
            AuthActionState.Success(AuthSuccessType.PASSWORD_RESET)
        }
    }

    /**
     * Clears any active error or success action state back to [AuthActionState.Idle].
     */
    @MainThread
    fun clearActionState() {
        if (_uiState.value.actionState !is AuthActionState.Loading) {
            _uiState.update { it.copy(actionState = AuthActionState.Idle) }
        }
    }

    /**
     * Executes an authentication action with loading state, cancellation propagation,
     * and semantic error mapping.
     */
    private fun executeAction(operation: String, action: suspend () -> AuthActionState) {
        if (_uiState.value.isLoading) {
            // Protect against concurrent/duplicate requests
            return
        }

        activeJob?.cancel()
        _uiState.update { it.copy(actionState = AuthActionState.Loading) }

        activeJob = viewModelScope.launch {
            try {
                val nextActionState = action()
                ensureActive()
                _uiState.update { it.copy(actionState = nextActionState) }
            } catch (error: Throwable) {
                if (error is CancellationException) {
                    throw error
                }
                ensureActive()
                val semanticError = error.toAuthError(operation)
                _uiState.update { it.copy(actionState = AuthActionState.Error(semanticError)) }
            }
        }
    }

    /**
     * Maps domain/repository exceptions into semantic [AuthError] codes.
     */
    private fun Throwable.toAuthError(operation: String): AuthError {
        errorReporter?.report(operation, this)
        return when (this) {
            is AuthException.InvalidCredentials -> AuthError.INVALID_CREDENTIALS
            is AuthException.EmailAlreadyInUse -> AuthError.EMAIL_ALREADY_IN_USE
            is AuthException.WeakPassword -> AuthError.WEAK_PASSWORD
            is AuthException.UserNotFound -> AuthError.USER_NOT_FOUND
            is AuthException.UserDisabled -> AuthError.USER_DISABLED
            is AuthException.TooManyRequests -> AuthError.TOO_MANY_REQUESTS
            is AuthException.Network, is RepositoryException.Transport -> AuthError.NETWORK
            is AuthException.Unavailable, is RepositoryException.Unavailable -> AuthError.UNAVAILABLE
            is AuthException.InvalidInput, is RepositoryException.InvalidData -> AuthError.INVALID_INPUT
            is AuthException.Unauthenticated, is RepositoryException.Unauthenticated -> AuthError.UNAUTHENTICATED
            else -> AuthError.UNEXPECTED
        }
    }
}
