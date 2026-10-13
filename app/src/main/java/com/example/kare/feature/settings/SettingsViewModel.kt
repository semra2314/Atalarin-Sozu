package com.example.kare.feature.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.model.AppLanguage
import com.example.kare.core.model.AppTheme
import com.example.kare.core.model.AuthState
import com.example.kare.core.repository.AuthRepository
import com.example.kare.core.repository.ProfileRepository
import com.example.kare.core.repository.UserPreferencesRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class SettingsUiState(
    val currentTheme: AppTheme = AppTheme.SYSTEM,
    val currentLanguage: AppLanguage = AppLanguage.SYSTEM,
    val userHandle: String = "",
    val hasAccount: Boolean = false,
    val appVersion: String = "1.0 (1)",
    val isDeletingAccount: Boolean = false,
    val errorMessage: String? = null,
)

class SettingsViewModel(
    private val preferencesRepository: UserPreferencesRepository,
    private val authRepository: AuthRepository,
    private val profileRepository: ProfileRepository,
) : ViewModel() {

    private val _deletionState = MutableStateFlow(false)
    private val _error = MutableStateFlow<String?>(null)

    // combine supports up to 5 flows directly; wrap extras with a nested combine.
    private val _baseState = combine(
        preferencesRepository.theme,
        preferencesRepository.language,
        profileRepository.profile,
        authRepository.authState,
    ) { theme, language, profile, authState ->
        Triple(theme to language, profile, authState)
    }

    val uiState: StateFlow<SettingsUiState> = combine(
        _baseState,
        _deletionState,
        _error,
    ) { (themeLang, profile, authState), isDeleting, error ->
        val (theme, language) = themeLang
        val hasAccount = authState is AuthState.Authenticated
        SettingsUiState(
            currentTheme = theme,
            currentLanguage = language,
            userHandle = if (profile.username.isNotBlank()) "@${profile.username}" else "",
            hasAccount = hasAccount,
            appVersion = "1.0 (1)",
            isDeletingAccount = isDeleting,
            errorMessage = error,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = SettingsUiState(),
    )

    fun setTheme(theme: AppTheme) {
        viewModelScope.launch {
            preferencesRepository.setTheme(theme)
        }
    }

    fun setLanguage(language: AppLanguage) {
        viewModelScope.launch {
            preferencesRepository.setLanguage(language)
        }
    }

    fun signOut() {
        viewModelScope.launch {
            authRepository.signOut()
        }
    }

    /**
     * Initiates account deletion. Since [AuthRepository] does not yet expose a deleteAccount
     * operation, this signs the user out and records a deletion-intent error message so the
     * UI can guide the user through any additional platform steps.
     *
     * TODO: Replace with authRepository.deleteAccount() once that operation is added to the
     *       AuthRepository interface and implemented in FirebaseAuthRepository.
     */
    fun deleteAccount(password: String?) {
        viewModelScope.launch {
            _deletionState.value = true
            _error.value = null
            try {
                // Sign out as a safe fallback; full deletion requires a dedicated repository op.
                authRepository.signOut()
            } catch (th: Throwable) {
                if (th is kotlinx.coroutines.CancellationException) throw th
                _error.value = th.localizedMessage ?: "Failed to delete account"
            } finally {
                _deletionState.value = false
            }
        }
    }

    fun clearError() {
        _error.value = null
    }
}
