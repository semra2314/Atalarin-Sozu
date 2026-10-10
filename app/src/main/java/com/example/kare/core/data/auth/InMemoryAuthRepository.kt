package com.example.kare.core.data.auth

import com.example.kare.core.model.AuthState
import com.example.kare.core.model.AuthUser
import com.example.kare.core.repository.AuthException
import com.example.kare.core.repository.AuthRepository
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * Clean in-memory implementation of [AuthRepository] for local application runtime,
 * previews, and integration without requiring immediate external Firebase cloud provisioning.
 */
class InMemoryAuthRepository : AuthRepository {

    private val _authState = MutableStateFlow<AuthState>(AuthState.Unauthenticated)
    override val authState: Flow<AuthState> = _authState.asStateFlow()

    private var _currentUser: AuthUser? = null
    override val currentUser: AuthUser? get() = _currentUser

    // Internal registered accounts store: email -> (password, AuthUser)
    private val accounts = ConcurrentHashMap<String, Pair<String, AuthUser>>()

    override suspend fun signIn(email: String, password: String): AuthUser {
        val trimmedEmail = email.trim()
        val account = accounts[trimmedEmail] ?: throw AuthException.UserNotFound()

        if (account.first != password) {
            throw AuthException.InvalidCredentials()
        }

        val user = account.second
        _currentUser = user
        _authState.value = AuthState.Authenticated(user)
        return user
    }

    override suspend fun register(name: String, email: String, password: String): AuthUser {
        val trimmedName = name.trim()
        val trimmedEmail = email.trim()

        if (accounts.containsKey(trimmedEmail)) {
            throw AuthException.EmailAlreadyInUse()
        }

        if (password.length < 6) {
            throw AuthException.WeakPassword()
        }

        val newUser = AuthUser(
            id = UUID.randomUUID().toString(),
            email = trimmedEmail,
            displayName = trimmedName,
        )

        accounts[trimmedEmail] = password to newUser
        _currentUser = newUser
        _authState.value = AuthState.Authenticated(newUser)
        return newUser
    }

    override suspend fun signOut() {
        _currentUser = null
        _authState.value = AuthState.Unauthenticated
    }

    override suspend fun resetPassword(email: String) {
        val trimmedEmail = email.trim()
        if (!accounts.containsKey(trimmedEmail)) {
            throw AuthException.UserNotFound()
        }
    }
}
