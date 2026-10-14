package com.example.kare.feature.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.model.AuthState
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.AuthRepository
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

/** Derived public session state; authentication implementation remains owned by Developer 2. */
class SettingsViewModel(private val auth: AuthRepository, private val errors: ErrorReporter, profile: com.example.kare.core.repository.ProfileRepository? = null) : ViewModel() {
    val account = auth.authState.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000),
        auth.currentUser?.let { AuthState.Authenticated(it) } ?: AuthState.Unauthenticated)
    val identity = profile?.profile ?: MutableStateFlow(com.example.kare.core.model.UserProfile()).asStateFlow()
    private val mutableFailure = MutableStateFlow(false)
    val signOutFailed = mutableFailure.asStateFlow()
    fun signOut() { viewModelScope.launch {
        mutableFailure.value = false
        try { auth.signOut() }
        catch (error: Exception) {
            if (error is CancellationException) throw error
            errors.report("settings sign out", error)
            mutableFailure.value = true
        }
    } }
}
