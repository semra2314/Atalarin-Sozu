package com.example.kare.core.data.auth

import com.example.kare.core.model.AuthState
import com.example.kare.core.model.AuthUser
import com.example.kare.core.repository.AuthException
import com.example.kare.core.repository.AuthRepository
import com.google.firebase.FirebaseNetworkException
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseAuthException
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.userProfileChangeRequest
import kotlin.coroutines.cancellation.CancellationException
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await

/**
 * Production [AuthRepository] implementation backed by Firebase Authentication.
 *
 * Implements reactive session observation via [FirebaseAuth.AuthStateListener],
 * safe coroutine cancellation propagation, and strict mapping of Firebase SDK
 * errors to domain [AuthException] models.
 */
class FirebaseAuthRepository(
    private val firebaseAuth: FirebaseAuth = FirebaseAuth.getInstance(),
) : AuthRepository {

    override val authState: Flow<AuthState> = callbackFlow {
        val listener = FirebaseAuth.AuthStateListener { auth ->
            val user = auth.currentUser?.toAuthUser()
            trySend(if (user != null) AuthState.Authenticated(user) else AuthState.Unauthenticated)
        }
        firebaseAuth.addAuthStateListener(listener)
        awaitClose { firebaseAuth.removeAuthStateListener(listener) }
    }

    override val currentUser: AuthUser?
        get() = firebaseAuth.currentUser?.toAuthUser()

    override suspend fun signIn(email: String, password: String): AuthUser {
        val trimmedEmail = email.trim()
        if (trimmedEmail.isBlank()) throw AuthException.InvalidInput("email")
        if (password.isBlank()) throw AuthException.InvalidInput("password")

        return try {
            val result = firebaseAuth.signInWithEmailAndPassword(trimmedEmail, password).await()
            val user = result.user?.toAuthUser() ?: throw AuthException.Unknown()
            user
        } catch (e: CancellationException) {
            throw e
        } catch (e: FirebaseAuthException) {
            throw mapAuthException(e)
        } catch (e: FirebaseNetworkException) {
            throw AuthException.Network(e)
        } catch (e: Exception) {
            if (e is AuthException) throw e
            throw AuthException.Unknown(e)
        }
    }

    override suspend fun register(name: String, email: String, password: String): AuthUser {
        val trimmedName = name.trim()
        val trimmedEmail = email.trim()
        if (trimmedEmail.isBlank()) throw AuthException.InvalidInput("email")
        if (password.length < 6) throw AuthException.WeakPassword()

        return try {
            val result = firebaseAuth.createUserWithEmailAndPassword(trimmedEmail, password).await()
            val user = result.user ?: throw AuthException.Unknown()

            if (trimmedName.isNotBlank()) {
                val profileUpdates = userProfileChangeRequest {
                    displayName = trimmedName
                }
                user.updateProfile(profileUpdates).await()
            }

            user.toAuthUser()
        } catch (e: CancellationException) {
            throw e
        } catch (e: FirebaseAuthException) {
            throw mapAuthException(e)
        } catch (e: FirebaseNetworkException) {
            throw AuthException.Network(e)
        } catch (e: Exception) {
            if (e is AuthException) throw e
            throw AuthException.Unknown(e)
        }
    }

    override suspend fun signOut() {
        firebaseAuth.signOut()
    }

    override suspend fun resetPassword(email: String) {
        val trimmedEmail = email.trim()
        if (trimmedEmail.isBlank()) throw AuthException.InvalidInput("email")

        try {
            firebaseAuth.sendPasswordResetEmail(trimmedEmail).await()
        } catch (e: CancellationException) {
            throw e
        } catch (e: FirebaseAuthException) {
            throw mapAuthException(e)
        } catch (e: FirebaseNetworkException) {
            throw AuthException.Network(e)
        } catch (e: Exception) {
            if (e is AuthException) throw e
            throw AuthException.Unknown(e)
        }
    }

    private fun FirebaseUser.toAuthUser(): AuthUser = AuthUser(
        id = uid,
        email = email ?: "",
        displayName = displayName ?: "",
    )

    private fun mapAuthException(e: FirebaseAuthException): AuthException {
        return when (e.errorCode) {
            "ERROR_INVALID_CREDENTIAL",
            "ERROR_WRONG_PASSWORD" -> AuthException.InvalidCredentials(e)
            "ERROR_USER_NOT_FOUND" -> AuthException.UserNotFound(e)
            "ERROR_EMAIL_ALREADY_IN_USE" -> AuthException.EmailAlreadyInUse(e)
            "ERROR_WEAK_PASSWORD" -> AuthException.WeakPassword(e)
            "ERROR_USER_DISABLED" -> AuthException.UserDisabled(e)
            "ERROR_TOO_MANY_REQUESTS" -> AuthException.TooManyRequests(e)
            "ERROR_NETWORK_REQUEST_FAILED" -> AuthException.Network(e)
            else -> AuthException.Unknown(e)
        }
    }
}
