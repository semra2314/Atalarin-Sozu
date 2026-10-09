package com.example.kare.feature.library

import androidx.annotation.MainThread
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import com.example.kare.core.repository.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

enum class LibraryOperation { INSTALL, REMOVE, FAVORITE, REORDER, CONTENT }
data class LibraryAction(val operation: LibraryOperation, val templateId: String? = null)
sealed interface LibraryActionState {
    data object Idle : LibraryActionState
    data class Running(val action: LibraryAction) : LibraryActionState
    data class Succeeded(val action: LibraryAction) : LibraryActionState
    data class Failed(val action: LibraryAction, val error: UiError) : LibraryActionState
}
data class LibraryUiState(
    val widgets: LoadState<List<InstalledWidget>> = LoadState.Loading,
    val favoritesOnly: Boolean = false,
    val action: LibraryActionState = LibraryActionState.Idle,
) {
    val visibleWidgets: List<InstalledWidget> get() =
        (widgets as? LoadState.Loaded)?.value.orEmpty().filter { !favoritesOnly || it.isFavorite }
}

class LibraryViewModel(
    private val repository: LibraryRepository,
    private val catalog: WidgetRepository,
    private val errors: ErrorReporter,
) : ViewModel() {
    private val mutableState = MutableStateFlow(LibraryUiState())
    val state = mutableState.asStateFlow()
    private var observation: Job? = null
    private var generation = 0L

    init { retryObservation() }

    @MainThread
    fun retryObservation() {
        val token = ++generation
        observation?.cancel()
        mutableState.update { it.copy(widgets = LoadState.Loading) }
        observation = viewModelScope.launch {
            try {
                repository.observeWidgets().collect { widgets ->
                    ensureActive()
                    if (token == generation) mutableState.update { it.copy(widgets = LoadState.Loaded(widgets.toList())) }
                }
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                ensureActive()
                if (token == generation) {
                    val mapped = error.toUiError("library.observe", errors)
                    mutableState.update { it.copy(widgets = LoadState.Failed(mapped)) }
                }
            }
        }
    }

    @MainThread
    fun setFavoritesOnly(enabled: Boolean) { mutableState.update { it.copy(favoritesOnly = enabled) } }

    @MainThread
    fun install(templateId: String, size: WidgetSize): Boolean = mutate(LibraryAction(LibraryOperation.INSTALL, templateId)) {
        val template = catalog.template(templateId)
        if (template.installationAccess() != InstallationAccess.FREE) throw RepositoryException.Unavailable("paid installation")
        repository.install(template, size)
    }

    @MainThread
    fun remove(templateId: String): Boolean = mutate(LibraryAction(LibraryOperation.REMOVE, templateId)) {
        repository.remove(templateId)
    }

    @MainThread
    fun toggleFavorite(templateId: String): Boolean = mutate(LibraryAction(LibraryOperation.FAVORITE, templateId)) {
        val current = repository.widget(templateId) ?: throw RepositoryException.NotFound(templateId)
        repository.setFavorite(templateId, !current.isFavorite)
    }

    @MainThread
    fun reorder(templateIds: List<String>): Boolean {
        val ids = templateIds.toList()
        return mutate(LibraryAction(LibraryOperation.REORDER)) { repository.reorder(ids) }
    }

    @MainThread
    fun updateContent(templateId: String, content: WidgetContent): Boolean = mutate(LibraryAction(LibraryOperation.CONTENT, templateId)) {
        repository.updateContent(templateId, content)
    }

    @MainThread
    fun clearAction() {
        if (mutableState.value.action !is LibraryActionState.Running) {
            mutableState.update { it.copy(action = LibraryActionState.Idle) }
        }
    }

    /** False means busy: callers must not queue/replay destructive or toggle commands implicitly. */
    private fun mutate(action: LibraryAction, block: suspend () -> Unit): Boolean {
        if (mutableState.value.action is LibraryActionState.Running) return false
        mutableState.update { it.copy(action = LibraryActionState.Running(action)) }
        viewModelScope.launch {
            try {
                block()
                ensureActive()
                mutableState.update { it.copy(action = LibraryActionState.Succeeded(action)) }
            } catch (error: Exception) {
                if (error is CancellationException) {
                    mutableState.update { it.copy(action = LibraryActionState.Idle) }
                    throw error
                }
                ensureActive()
                val mapped = error.toUiError("library.${action.operation.name.lowercase()}", errors)
                mutableState.update { it.copy(action = LibraryActionState.Failed(action, mapped)) }
            }
        }
        return true
    }
}
