package com.example.kare.widget

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.data.widget.EditableWidgetRepository
import com.example.kare.core.model.InstalledWidget
import com.example.kare.core.presentation.*
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class EditableConfigurationState(
    val choices: LoadState<List<InstalledWidget>> = LoadState.Loading,
    val selected: String? = null, val saving: Boolean = false, val saved: Boolean = false,
    val error: UiError? = null,
)
class EditableConfigurationViewModel(
    private val id: Int,
    private val requested: String?,
    private val repository: EditableWidgetRepository,
    private val update: suspend () -> Unit,
    private val errors: ErrorReporter,
    private val savedState: SavedStateHandle,
) : ViewModel() {
    private val mutable = MutableStateFlow(EditableConfigurationState())
    val state = mutable.asStateFlow()
    init { load() }
    fun load() {
        if(mutable.value.saving) return
        viewModelScope.launch {
            mutable.value = EditableConfigurationState()
            try {
                val choices = repository.choices()
                val binding = try { repository.binding(id)?.installedId } catch(error: Exception) {
                    if(error is CancellationException) throw error
                    errors.report("editable.configuration.recover", error); null
                }
                val selected = savedState.get<String>("selected") ?: requested ?: binding
                mutable.value = EditableConfigurationState(LoadState.Loaded(choices), selected?.takeIf { key -> choices.any { it.templateId == key } })
            } catch(error: Exception) { mutable.value = EditableConfigurationState(LoadState.Failed(error.toUiError("editable.configuration.load", errors))) }
        }
    }
    fun select(key: String) {
        if(mutable.value.saving) return
        savedState["selected"] = key
        mutable.value = mutable.value.copy(selected = key, error = null)
    }
    fun save() {
        val state = mutable.value
        val key = state.selected ?: return
        if(state.saving) return
        mutable.value = state.copy(saving = true)
        viewModelScope.launch {
            try {
                repository.bind(id, key)
                update()
                mutable.value = state.copy(saved = true)
            } catch(error: Exception) { mutable.value = state.copy(error = error.toUiError("editable.configuration.save", errors)) }
        }
    }
}
