package com.example.kare.core.data.profile

import android.content.Context
import android.content.SharedPreferences
import com.example.kare.core.model.AuthState
import com.example.kare.core.model.PublicProfile
import com.example.kare.core.model.UserProfile
import com.example.kare.core.repository.AuthRepository
import com.example.kare.core.repository.ProfileRepository
import com.example.kare.core.repository.PublicProfileRepository
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch

/**
 * Local implementation of [ProfileRepository].
 * Synchronizes with [AuthRepository] state and persists custom display name, username,
 * and avatar path in local preferences while mirroring public identity to [PublicProfileRepository].
 */
class LocalProfileRepository(
    context: Context,
    private val authRepository: AuthRepository,
    private val publicProfileRepository: PublicProfileRepository,
    scope: CoroutineScope = CoroutineScope(Dispatchers.Default),
) : ProfileRepository {

    private val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    private val _profile = MutableStateFlow(loadInitialProfile())
    override val profile: StateFlow<UserProfile> = _profile.asStateFlow()

    init {
        scope.launch {
            authRepository.authState.collectLatest { authState ->
                reconcileWithAuth(authState)
            }
        }
    }

    private fun loadInitialProfile(): UserProfile {
        val savedName = prefs.getString(KEY_DISPLAY_NAME, "Kare User") ?: "Kare User"
        val savedUsername = prefs.getString(KEY_USERNAME, "kare_user") ?: "kare_user"
        val savedAvatar = prefs.getString(KEY_AVATAR_PATH, null)

        // Use currentUser snapshot for initial load — avoids needing a StateFlow.value.
        val user = authRepository.currentUser

        return UserProfile(
            uid = user?.id,
            displayName = user?.displayName?.ifBlank { savedName } ?: savedName,
            username = savedUsername,
            avatarPath = savedAvatar,
            hasAccount = user != null,
        )
    }

    private suspend fun reconcileWithAuth(authState: AuthState) {
        val current = _profile.value
        when (authState) {
            is AuthState.Authenticated -> {
                val user = authState.user
                val resolvedName = user.displayName?.ifBlank { null } ?: "Kare User"
                val updated = current.copy(
                    uid = user.id,
                    displayName = if (current.displayName.isBlank() || current.displayName == "Kare User") {
                        resolvedName
                    } else {
                        current.displayName
                    },
                    hasAccount = true,
                )
                _profile.value = updated
                publicProfileRepository.putProfile(
                    PublicProfile(
                        id = user.id,
                        displayName = updated.displayName,
                        username = updated.username,
                    )
                )
            }
            AuthState.Unauthenticated -> {
                _profile.value = current.copy(
                    uid = null,
                    hasAccount = false,
                )
            }
        }
    }

    override suspend fun updateProfile(
        displayName: String,
        username: String,
        avatarPath: String?,
    ): Result<Unit> = runCatching {
        val cleanedName = displayName.trim().ifBlank { "Kare User" }
        val cleanedUsername = username.trim().removePrefix("@").lowercase()

        prefs.edit()
            .putString(KEY_DISPLAY_NAME, cleanedName)
            .putString(KEY_USERNAME, cleanedUsername)
            .putString(KEY_AVATAR_PATH, avatarPath)
            .apply()

        val current = _profile.value
        val updated = current.copy(
            displayName = cleanedName,
            username = cleanedUsername,
            avatarPath = avatarPath,
        )
        _profile.value = updated

        updated.uid?.let { uid ->
            publicProfileRepository.putProfile(
                PublicProfile(
                    id = uid,
                    displayName = cleanedName,
                    username = cleanedUsername,
                )
            )
        }
    }

    override suspend fun refresh() {
        // Re-read auth state through the snapshot currentUser to avoid collecting the flow.
        val user = authRepository.currentUser
        val authState = if (user != null) AuthState.Authenticated(user) else AuthState.Unauthenticated
        reconcileWithAuth(authState)
    }

    companion object {
        private const val PREFS_NAME = "kare_profile_prefs"
        private const val KEY_DISPLAY_NAME = "profile_display_name"
        private const val KEY_USERNAME = "profile_username"
        private const val KEY_AVATAR_PATH = "profile_avatar_path"
    }
}
