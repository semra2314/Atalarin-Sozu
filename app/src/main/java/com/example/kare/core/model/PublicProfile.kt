package com.example.kare.core.model

/** Public account identity; [id] is the Firebase UID, not a catalog author ID. */
data class PublicProfile(
    val id: String,
    val displayName: String,
    val username: String,
    val avatarData: ImageData? = null,
)
