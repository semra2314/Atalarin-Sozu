package com.example.kare.core.data.profile

import com.example.kare.core.model.PublicProfile
import com.example.kare.core.repository.PublicProfileRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.map

/**
 * Thread-safe in-memory cache of public profiles.
 */
class InMemoryPublicProfileRepository(
    initialProfiles: Map<String, PublicProfile> = emptyMap(),
) : PublicProfileRepository {

    private val profilesState = MutableStateFlow(initialProfiles)

    override fun observeProfile(uid: String): Flow<PublicProfile?> {
        return profilesState.map { it[uid] }
    }

    override suspend fun getProfile(uid: String): PublicProfile? {
        return profilesState.value[uid]
    }

    override suspend fun putProfile(profile: PublicProfile) {
        val current = profilesState.value.toMutableMap()
        current[profile.id] = profile
        profilesState.value = current
    }
}
