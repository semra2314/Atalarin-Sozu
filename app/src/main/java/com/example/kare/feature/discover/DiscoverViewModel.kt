package com.example.kare.feature.discover

import androidx.annotation.MainThread
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.model.CatalogSection
import com.example.kare.core.presentation.*
import com.example.kare.core.repository.WidgetRepository
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

class DiscoverViewModel(private val repository: WidgetRepository, private val errors: ErrorReporter) : ViewModel() {
    private val mutableState = MutableStateFlow<LoadState<List<CatalogSection>>>(LoadState.Loading)
    val state = mutableState.asStateFlow()
    private var request: Job? = null
    private var generation = 0L

    init { reload() }

    @MainThread
    fun reload() {
        val token = ++generation
        request?.cancel()
        mutableState.value = LoadState.Loading
        request = viewModelScope.launch {
            try {
                val sections = repository.discoverSections().toList()
                ensureActive()
                if (token == generation) mutableState.value = LoadState.Loaded(sections)
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                ensureActive()
                if (token == generation) mutableState.value = LoadState.Failed(error.toUiError("discover", errors))
            }
        }
    }
}
