package com.example.kare.core.repository

import com.example.kare.core.model.AuthState
import com.example.kare.core.model.AuthUser
import kotlinx.coroutines.flow.Flow

/**
 * Authentication repository contract matching the application's account domain requirements.
 *
 * All operations must be main-safe. Implementations map SDK/infrastructure errors to
 * [AuthException] or [RepositoryException], and propagate coroutine cancellation unchanged.
 * No Firebase or platform framework types cross this interface boundary.
 */
interface AuthRepository {
    /**
     * Hot reactive stream emitting the current authentication session state.
     */
    val authState: Flow<AuthState>

    /**
     * Snapshot of the current authenticated user, or null if no active session exists.
     */
    val currentUser: AuthUser?

    /**
     * Signs in with the given email address and password.
     *
     * @param email User's email address.
     * @param password User's account password.
     * @return The authenticated [AuthUser].
     * @throws AuthException on authentication failure.
     */
    suspend fun signIn(email: String, password: String): AuthUser

    /**
     * Registers a new account with the given display name, email address, and password.
     *
     * @param name User's display name.
     * @param email User's email address.
     * @param password Chosen password.
     * @return The newly registered [AuthUser].
     * @throws AuthException on registration failure.
     */
    suspend fun register(name: String, email: String, password: String): AuthUser

    /**
     * Convenience alias for [register] matching the iOS signUp nomenclature.
     */
    suspend fun signUp(name: String, email: String, password: String): AuthUser = register(name, email, password)

    /**
     * Signs out the currently authenticated user session.
     */
    suspend fun signOut()

    /**
     * Initiates a password reset email for the given email address.
     *
     * @param email Target user email address.
     * @throws AuthException on failure.
     */
    suspend fun resetPassword(email: String)
}
