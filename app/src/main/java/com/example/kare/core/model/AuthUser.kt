package com.example.kare.core.model

/**
 * Domain representation of an authenticated user identity.
 *
 * Independent of Firebase SDK types, Android framework types, and Compose types.
 *
 * @property id Unique user identifier (Firebase UID).
 * @property email Authenticated user's email address.
 * @property displayName User's display name, if provided.
 */
data class AuthUser(
    val id: String,
    val email: String,
    val displayName: String? = null,
)
