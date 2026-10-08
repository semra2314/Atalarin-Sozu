package com.example.kare.core.model

/** Catalog creator identity, distinct from a signed-in user's public profile. */
data class Author(
    val id: String,
    val displayName: String,
    val handle: String,
    val avatarUrl: String? = null,
    val isVerified: Boolean = false,
)
