package com.example.kare.widget

import androidx.lifecycle.*
import com.example.kare.core.data.widget.HushWidgetRepository
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

data class HushConfigurationState(
    val selection: LoadState<HushLanguage> = LoadState.Loading,
    val saving: Boolean = false,
    val saved: Boolean = false,
    val recovering: Boolean = false,
    val error: UiError? = null,
)
class HushConfigurationViewModel(
    private val id: Int,
    private val repository: HushWidgetRepository,
    private val refresh: suspend () -> Unit,
    private val errors: ErrorReporter,
    private val handle: SavedStateHandle,
) : ViewModel() {
    private val mutable = MutableStateFlow(HushConfigurationState())
    val state = mutable.asStateFlow()
    init { load() }
    fun load() {
        viewModelScope.launch {
            try {
                val existing = repository.configuration(id)
                val selected = HushLanguage.entries.find { it.name == handle.get<String>("selection") }
                    ?: existing?.language ?: HushLanguage.APP
                mutable.value = HushConfigurationState(LoadState.Loaded(selected))
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                errors.report("hush.configure.load", error)
                // Do not delete or overwrite until the user explicitly saves a new choice.
                mutable.value = HushConfigurationState(LoadState.Loaded(HushLanguage.APP), recovering = true)
            }
        }
    }
    fun select(value: HushLanguage) {
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
                mutable.update { it.copy(saving = false, error = error.toUiError("hush.configure.save", errors)) }
            }
        }
    }
}
