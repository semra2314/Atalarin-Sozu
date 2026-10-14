package com.example.kare.core.repository

import com.example.kare.core.model.UserProfile
import kotlinx.coroutines.flow.StateFlow

/**
 * Repository managing current user profile, local handle, display name, and avatar.
 */
interface ProfileRepository {
    val profile: StateFlow<UserProfile>

    suspend fun updateProfile(displayName: String, username: String, avatarPath: String?): Result<Unit>
    suspend fun refresh()
}
