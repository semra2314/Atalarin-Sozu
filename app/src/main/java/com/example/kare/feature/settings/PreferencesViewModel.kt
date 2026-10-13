package com.example.kare.feature.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.model.*
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.PreferencesRepository
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

sealed interface StartupState {
    data object Loading : StartupState
    data object Unavailable : StartupState
    data class Loaded(val preferences: AppPreferences) : StartupState
}
enum class PreferenceError { READ, WRITE }
data class PreferencesUiState(
    val startup: StartupState = StartupState.Loading,
    val saving: Boolean = false,
    val sessionOnly: Boolean = false,
    val error: PreferenceError? = null,
)

class PreferencesViewModel(private val repository: PreferencesRepository, private val errors: ErrorReporter) : ViewModel() {
    private val mutable = MutableStateFlow(PreferencesUiState())
    val state = mutable.asStateFlow()
    private var observation: Job? = null
    init { retry() }
    fun retry() {
        observation?.cancel()
        mutable.update { it.copy(startup = StartupState.Loading, error = null, sessionOnly = false) }
        observation = viewModelScope.launch {
            try {
                repository.preferences.collect { prefs -> mutable.update { it.copy(startup = StartupState.Loaded(prefs)) } }
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                errors.report("read preferences", error)
                mutable.update { it.copy(startup = StartupState.Unavailable, error = PreferenceError.READ) }
            }
        }
    }
    // Explicit user choice after a failure. Never pretends completion was durably saved.
    fun continueForSession() {
        observation?.cancel()
        val prefs = (mutable.value.startup as? StartupState.Loaded)?.preferences ?: AppPreferences()
        mutable.update { it.copy(startup = StartupState.Loaded(prefs.copy(onboardingCompleted = true)), error = PreferenceError.READ, sessionOnly = true) }
    }
    fun completeOnboarding() = write { repository.completeOnboarding() }
    fun language(value: AppLanguage) = write { repository.setLanguage(value) }
    fun appearance(value: AppAppearance) = write { repository.setAppearance(value) }
    private fun write(action: suspend () -> Unit) {
        if (mutable.value.saving || mutable.value.sessionOnly) return
        mutable.update { it.copy(saving = true, error = null) }
        viewModelScope.launch {
            try { action() }
            catch (error: Exception) {
                if (error is CancellationException) throw error
                errors.report("write preferences", error)
                mutable.update { it.copy(error = PreferenceError.WRITE) }
            } finally { mutable.update { it.copy(saving = false) } }
        }
    }
}
