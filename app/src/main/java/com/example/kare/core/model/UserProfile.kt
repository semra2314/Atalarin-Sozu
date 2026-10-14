package com.example.kare.core.model

/**
 * User profile identity model.
 *
 * @property uid Unique account identifier (Firebase UID or null if anonymous/guest).
 * @property displayName User's public display name (e.g. "Semra").
 * @property username User's unique handle without leading @ symbol (e.g. "semra23").
 * @property avatarPath Local file path or URI of the cached avatar image.
 * @property hasAccount Whether this profile is linked to an authenticated account.
 */
data class UserProfile(
    val uid: String? = null,
    val displayName: String = "",
    val username: String = "",
    val avatarPath: String? = null,
    val hasAccount: Boolean = false,
)
