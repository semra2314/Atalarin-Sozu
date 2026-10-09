package com.example.kare.core.model

/**
 * Represents the observable authentication session state.
 *
 * Independent of platform, framework, and SDK types.
 */
sealed interface AuthState {
    /** No user is currently signed in. */
    data object Unauthenticated : AuthState

    /** A user is signed in with active session [user]. */
    data class Authenticated(val user: AuthUser) : AuthState
}
