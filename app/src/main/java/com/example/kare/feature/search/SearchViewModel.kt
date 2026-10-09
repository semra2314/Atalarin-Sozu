package com.example.kare.feature.search

import androidx.annotation.MainThread
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.model.WidgetCategory
import com.example.kare.core.model.WidgetTemplate
import com.example.kare.core.presentation.*
import com.example.kare.core.repository.WidgetRepository
import java.util.Locale
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

data class SearchUiState(
    val query: String = "",
    val category: WidgetCategory? = null,
    val results: LoadState<List<WidgetTemplate>> = LoadState.Loading,
) {
    val isEmpty: Boolean get() = (results as? LoadState.Loaded)?.value?.isEmpty() == true
}

class SearchViewModel(private val repository: WidgetRepository, private val errors: ErrorReporter,
    private val savedState: SavedStateHandle = SavedStateHandle(),
) : ViewModel() {
    private val mutableState = MutableStateFlow(SearchUiState(
        query = savedState["search.query"] ?: "",
        category = WidgetCategory.entries.find { it.rawValue == savedState.get<String>("search.category") },
    ))
    val state = mutableState.asStateFlow()
    private var request: Job? = null
    private var generation = 0L

    init { search(debounce = false) }

    @MainThread
    fun setQuery(query: String) {
        savedState["search.query"] = query
        val previous = mutableState.value.query.normalized()
        mutableState.update { it.copy(query = query) }
        if (query.normalized() != previous) search(debounce = true)
    }

    /** Desired category; a future chip may explicitly pass null to clear selection. */
    @MainThread
    fun setCategory(category: WidgetCategory?) {
        if (category == mutableState.value.category) return
        savedState["search.category"] = category?.rawValue
        mutableState.update { it.copy(category = category) }
        search(debounce = true)
    }

    @MainThread
    fun retry() = search(debounce = false)

    private fun search(debounce: Boolean) {
        val token = ++generation
        request?.cancel() // Cancel immediately, including while waiting for the next debounce interval.
        val criteria = mutableState.value
        mutableState.update { it.copy(results = LoadState.Loading) }
        request = viewModelScope.launch {
            try {
                if (debounce) delay(280)
                val results = repository.search(criteria.query.trim(), criteria.category).toList()
                ensureActive()
                if (token == generation) mutableState.update { it.copy(results = LoadState.Loaded(results)) }
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                ensureActive()
                if (token == generation) {
                    val mapped = error.toUiError("search", errors)
                    mutableState.update { it.copy(results = LoadState.Failed(mapped)) }
                }
            }
        }
    }

    private fun String.normalized() = trim().lowercase(Locale.ROOT)
}
