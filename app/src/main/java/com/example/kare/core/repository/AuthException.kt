package com.example.kare.core.repository

/**
 * Domain-specific exceptions for authentication failures.
 *
 * All platform and SDK-level errors (such as FirebaseAuthException) must be mapped
 * to subclasses of this type before crossing repository boundaries.
 */
sealed class AuthException(message: String, cause: Throwable? = null) : RepositoryException(message, cause) {
    class InvalidCredentials(cause: Throwable? = null) : AuthException("Invalid email or password", cause)
    class EmailAlreadyInUse(cause: Throwable? = null) : AuthException("Email is already in use", cause)
    class WeakPassword(cause: Throwable? = null) : AuthException("Password is too weak", cause)
    class UserNotFound(cause: Throwable? = null) : AuthException("User not found", cause)
    class UserDisabled(cause: Throwable? = null) : AuthException("User account has been disabled", cause)
    class TooManyRequests(cause: Throwable? = null) : AuthException("Too many attempts; please try again later", cause)
    class Network(cause: Throwable? = null) : AuthException("Network connection failed", cause)
    class Unavailable(operation: String = "auth") : AuthException("Auth service is unavailable: $operation")
    class Unauthenticated : AuthException("User is not signed in")
    class InvalidInput(val field: String) : AuthException("Invalid input for field: $field")
    class Unknown(cause: Throwable? = null) : AuthException("Unknown authentication failure", cause)
}
