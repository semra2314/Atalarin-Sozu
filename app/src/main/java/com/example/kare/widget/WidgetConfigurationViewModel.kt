package com.example.kare.widget

import androidx.lifecycle.*
import com.example.kare.core.data.widget.ProverbWidgetRepository
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

data class WidgetConfigurationState(
    val selection: LoadState<ProverbSelection> = LoadState.Loading,
    val saving: Boolean = false,
    val saved: Boolean = false,
    val error: UiError? = null,
)
class WidgetConfigurationViewModel(
    private val id: Int,
    private val repository: ProverbWidgetRepository,
    private val refresh: suspend () -> Unit,
    private val errors: ErrorReporter,
    private val handle: SavedStateHandle,
) : ViewModel() {
    private val mutable = MutableStateFlow(WidgetConfigurationState())
    val state = mutable.asStateFlow()
    init { load() }
    fun load() {
        viewModelScope.launch {
            try {
                val existing = repository.configuration(id)
                val selected = ProverbSelection.entries.find { it.name == handle.get<String>("selection") }
                    ?: existing?.selection ?: ProverbSelection.ALL
                mutable.value = WidgetConfigurationState(LoadState.Loaded(selected))
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                mutable.value = WidgetConfigurationState(LoadState.Failed(error.toUiError("widget.configure.load", errors)))
            }
        }
    }
    fun select(value: ProverbSelection) {
        if (state.value.saving) return
        handle["selection"] = value.name
        mutable.update { it.copy(selection = LoadState.Loaded(value), error = null) }
    }
    fun save() {
        if (state.value.saving || state.value.saved) return
        val choice = (state.value.selection as? LoadState.Loaded)?.value ?: return
        mutable.update { it.copy(saving = true, error = null) }
        viewModelScope.launch {
            try {
                repository.configure(id, choice)
                refresh()
                mutable.update { it.copy(saving = false, saved = true) }
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                mutable.update { it.copy(saving = false, error = error.toUiError("widget.configure.save", errors)) }
            }
        }
    }
}
