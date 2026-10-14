package com.example.kare.core.repository

import com.example.kare.core.model.PublicProfile
import kotlinx.coroutines.flow.Flow

/**
 * Repository for accessing and caching public user identities (display name, handle, avatar).
 */
interface PublicProfileRepository {
    fun observeProfile(uid: String): Flow<PublicProfile?>
    suspend fun getProfile(uid: String): PublicProfile?
    suspend fun putProfile(profile: PublicProfile)
}
