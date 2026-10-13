package com.example.kare.feature.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.model.AuthState
import com.example.kare.core.model.InstalledWidget
import com.example.kare.core.model.UserProfile
import com.example.kare.core.repository.AuthRepository
import com.example.kare.core.repository.LibraryRepository
import com.example.kare.core.repository.ProfileRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class ProfileUiState(
    val userProfile: UserProfile = UserProfile(),
    val isGuest: Boolean = true,
    val widgetCount: Int = 0,
    val favoritesCount: Int = 0,
    val myWidgets: List<InstalledWidget> = emptyList(),
    val favoriteWidgets: List<InstalledWidget> = emptyList(),
    val isLoading: Boolean = false,
)

class ProfileViewModel(
    private val profileRepository: ProfileRepository,
    private val libraryRepository: LibraryRepository,
    private val authRepository: AuthRepository,
) : ViewModel() {

    val uiState: StateFlow<ProfileUiState> = combine(
        profileRepository.profile,
        libraryRepository.observeWidgets(),
        authRepository.authState,
    ) { profile, installedWidgets, authState ->
        val isGuest = authState !is AuthState.Authenticated
        val favorites = installedWidgets.filter { it.isFavorite }
        ProfileUiState(
            userProfile = profile,
            isGuest = isGuest,
            widgetCount = installedWidgets.size,
            favoritesCount = favorites.size,
            myWidgets = installedWidgets,
            favoriteWidgets = favorites,
            isLoading = false,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = ProfileUiState(isLoading = true),
    )

    fun toggleFavorite(widget: InstalledWidget) {
        viewModelScope.launch {
            libraryRepository.setFavorite(widget.templateId, !widget.isFavorite)
        }
    }

    fun updateProfile(displayName: String, username: String, avatarPath: String?) {
        viewModelScope.launch {
            profileRepository.updateProfile(displayName, username, avatarPath)
        }
    }

    fun refresh() {
        viewModelScope.launch {
            profileRepository.refresh()
        }
    }
}
