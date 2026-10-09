package com.example.kare.feature.detail

import androidx.annotation.MainThread
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import com.example.kare.core.repository.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

sealed interface InstallState {
    data object Idle : InstallState
    data object Installing : InstallState
    data class Failed(val error: UiError) : InstallState
}

data class DetailUiState(
    val template: LoadState<WidgetTemplate> = LoadState.Loading,
    val installed: LoadState<InstalledWidget?> = LoadState.Loading,
    val selectedSize: WidgetSize? = null,
    val action: InstallState = InstallState.Idle,
) {
    val canInstall: Boolean get() {
        val value = (template as? LoadState.Loaded)?.value ?: return false
        val membership = installed as? LoadState.Loaded ?: return false
        return value.installationAccess() == InstallationAccess.FREE && membership.value == null &&
            selectedSize in value.supportedSizes && action != InstallState.Installing
    }
}

class DetailViewModel(
    val templateId: String,
    private val catalog: WidgetRepository,
    private val library: LibraryRepository,
    private val errors: ErrorReporter,
    private val savedState: SavedStateHandle = SavedStateHandle(),
) : ViewModel() {
    private val mutableState = MutableStateFlow(DetailUiState())
    val state = mutableState.asStateFlow()
    private var loadJob: Job? = null
    private var observation: Job? = null
    private var generation = 0L

    init { reload(); retryLibrary() }

    @MainThread
    fun reload() {
        if (state.value.action == InstallState.Installing) return
        val token = ++generation
        loadJob?.cancel()
        mutableState.update { it.copy(template = LoadState.Loading, action = InstallState.Idle) }
        loadJob = viewModelScope.launch {
            try {
                val template = catalog.template(templateId)
                ensureActive()
                if (token != generation) return@launch
                val restored = WidgetSize.entries.find { it.rawValue == savedState.get<String>("detail.size") }
                mutableState.update { it.copy(template = LoadState.Loaded(template), selectedSize =
                    restored?.takeIf { size -> size in template.supportedSizes } ?: template.supportedSizes.singleOrNull()) }
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                ensureActive()
                if (token == generation) mutableState.update { it.copy(template = LoadState.Failed(error.toUiError("detail.load", errors))) }
            }
        }
    }

    @MainThread
    fun retryLibrary() {
        observation?.cancel()
        mutableState.update { it.copy(installed = LoadState.Loading) }
        observation = viewModelScope.launch {
            try {
                library.observeWidgets().collect { widgets ->
                    ensureActive()
                    mutableState.update { it.copy(installed = LoadState.Loaded(widgets.find { row -> row.templateId == templateId })) }
                }
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                ensureActive()
                mutableState.update { it.copy(installed = LoadState.Failed(error.toUiError("detail.observe", errors))) }
            }
        }
    }

    @MainThread
    fun selectSize(size: WidgetSize) {
        if (state.value.action == InstallState.Installing || (state.value.installed as? LoadState.Loaded)?.value != null) return
        val template = (state.value.template as? LoadState.Loaded)?.value ?: return
        if (size !in template.supportedSizes) {
            mutableState.update { it.copy(action = InstallState.Failed(UiError.INVALID_DATA)) }
            return
        }
        savedState["detail.size"] = size.rawValue
        mutableState.update { it.copy(selectedSize = size, action = InstallState.Idle) }
    }

    @MainThread
    fun install() {
        val current = state.value
        if (current.action == InstallState.Installing) return
        val template = (current.template as? LoadState.Loaded)?.value ?: return
        if (template.installationAccess() != InstallationAccess.FREE) {
            mutableState.update { it.copy(action = InstallState.Failed(UiError.UNAVAILABLE)) }
            return
        }
        val membership = current.installed as? LoadState.Loaded ?: return
        if (membership.value != null) return
        val size = current.selectedSize
        if (size == null || size !in template.supportedSizes) {
            mutableState.update { it.copy(action = InstallState.Failed(UiError.INVALID_DATA)) }
            return
        }
        mutableState.update { it.copy(action = InstallState.Installing) }
        viewModelScope.launch {
            try {
                // Repository transaction returns an existing row unchanged if another caller won.
                val installed = library.install(template, size)
                ensureActive()
                mutableState.update { it.copy(installed = LoadState.Loaded(installed), action = InstallState.Idle) }
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                ensureActive()
                mutableState.update { it.copy(action = InstallState.Failed(error.toUiError("detail.install", errors))) }
            }
        }
    }
}
