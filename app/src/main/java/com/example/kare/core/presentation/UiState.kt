package com.example.kare.core.presentation

import com.example.kare.core.repository.RepositoryException
import kotlinx.coroutines.CancellationException

/** Semantic errors only. Localization and presentation belong to the future UI. */
enum class UiError { NOT_FOUND, UNAVAILABLE, SIGN_IN_REQUIRED, INVALID_DATA, CONNECTION, STORAGE, UNEXPECTED }

sealed interface LoadState<out T> {
    data object Loading : LoadState<Nothing>
    data class Loaded<T>(val value: T) : LoadState<T>
    data class Failed(val error: UiError) : LoadState<Nothing>
}

/** Receives original exceptions for diagnostics; they never enter UI state. Must not throw. */
fun interface ErrorReporter {
    fun report(operation: String, error: Throwable)
}

internal fun Throwable.toUiError(operation: String, reporter: ErrorReporter): UiError {
    if (this is CancellationException) throw this
    reporter.report(operation, this)
    return when (this) {
        is RepositoryException.NotFound -> UiError.NOT_FOUND
        is RepositoryException.Unavailable -> UiError.UNAVAILABLE
        is RepositoryException.Unauthenticated -> UiError.SIGN_IN_REQUIRED
        is RepositoryException.InvalidData -> UiError.INVALID_DATA
        is RepositoryException.Transport -> UiError.CONNECTION
        is RepositoryException.Persistence -> UiError.STORAGE
        else -> UiError.UNEXPECTED
    }
}
