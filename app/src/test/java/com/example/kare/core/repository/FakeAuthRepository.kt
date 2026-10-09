package com.example.kare.core.repository

import com.example.kare.core.model.AuthState
import com.example.kare.core.model.AuthUser
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * In-memory test fake implementation of [AuthRepository].
 *
 * Supports simulating latency, error injection, credential verification,
 * and reactive auth state emission without Android or Firebase dependencies.
 */
class FakeAuthRepository(
    initialUser: AuthUser? = null,
) : AuthRepository {

    private val _authState = MutableStateFlow<AuthState>(
        initialUser?.let { AuthState.Authenticated(it) } ?: AuthState.Unauthenticated
    )
    override val authState: Flow<AuthState> = _authState.asStateFlow()

    private var _currentUser: AuthUser? = initialUser
    override val currentUser: AuthUser? get() = _currentUser

    // Internal in-memory store: email -> (password, AuthUser)
    private val accounts = mutableMapOf<String, Pair<String, AuthUser>>()

    // Configurable simulated failures
    var nextSignInFailure: Exception? = null
    var nextRegisterFailure: Exception? = null
    var nextSignOutFailure: Exception? = null
    var nextResetPasswordFailure: Exception? = null
    var simulatedDelayMs: Long = 0L

    // Call audit records
    val signInCalls = mutableListOf<Pair<String, String>>()
    val registerCalls = mutableListOf<Triple<String, String, String>>()
    var signOutCount: Int = 0
    val resetPasswordCalls = mutableListOf<String>()

    init {
        initialUser?.let { user ->
            accounts[user.email] = "initialPassword123" to user
        }
    }

    /**
     * Seeds an account into the in-memory store for sign-in tests.
     */
    fun seedUser(email: String, password: String, user: AuthUser) {
        accounts[email] = password to user
    }

    /**
     * Directly forces the current session to a given state.
     */
    fun setSession(user: AuthUser?) {
        _currentUser = user
        _authState.value = user?.let { AuthState.Authenticated(it) } ?: AuthState.Unauthenticated
    }

    override suspend fun signIn(email: String, password: String): AuthUser {
        if (simulatedDelayMs > 0) delay(simulatedDelayMs)
        signInCalls += email to password

        nextSignInFailure?.let { failure ->
            nextSignInFailure = null
            throw failure
        }

        val account = accounts[email]
            ?: throw AuthException.UserNotFound()

        if (account.first != password) {
            throw AuthException.InvalidCredentials()
        }

        val authenticatedUser = account.second
        _currentUser = authenticatedUser
        _authState.value = AuthState.Authenticated(authenticatedUser)
        return authenticatedUser
    }

    override suspend fun register(name: String, email: String, password: String): AuthUser {
        if (simulatedDelayMs > 0) delay(simulatedDelayMs)
        registerCalls += Triple(name, email, password)

        nextRegisterFailure?.let { failure ->
            nextRegisterFailure = null
            throw failure
        }

        if (accounts.containsKey(email)) {
            throw AuthException.EmailAlreadyInUse()
        }

        if (password.length < 6) {
            throw AuthException.WeakPassword()
        }

        val newUser = AuthUser(
            id = "mock-uid-${accounts.size + 1}",
            email = email,
            displayName = name,
        )
        accounts[email] = password to newUser
        _currentUser = newUser
        _authState.value = AuthState.Authenticated(newUser)
        return newUser
    }

    override suspend fun signOut() {
        if (simulatedDelayMs > 0) delay(simulatedDelayMs)
        signOutCount++

        nextSignOutFailure?.let { failure ->
            nextSignOutFailure = null
            throw failure
        }

        _currentUser = null
        _authState.value = AuthState.Unauthenticated
    }

    override suspend fun resetPassword(email: String) {
        if (simulatedDelayMs > 0) delay(simulatedDelayMs)
        resetPasswordCalls += email

        nextResetPasswordFailure?.let { failure ->
            nextResetPasswordFailure = null
            throw failure
        }

        if (!accounts.containsKey(email)) {
            throw AuthException.UserNotFound()
        }
    }
}
