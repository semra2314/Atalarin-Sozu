package com.example.kare.core.data.widget

import com.example.kare.core.model.*
import com.example.kare.core.repository.LibraryRepository
import com.example.kare.core.presentation.ErrorReporter
import kotlinx.coroutines.CancellationException

/** Refresh failure cannot turn a committed library write into an apparent write failure. */
class WidgetRefreshingLibraryRepository(
    private val delegate: LibraryRepository,
    private val refresh: suspend () -> Unit,
    private val errors: ErrorReporter,
) : LibraryRepository by delegate {
    override suspend fun install(template: WidgetTemplate, size: WidgetSize): InstalledWidget =
        delegate.install(template, size).also { if (template.id == "t-proverb") notifyWidgets() }
    override suspend fun remove(templateId: String): InstalledWidget? =
        delegate.remove(templateId).also { if (templateId == "t-proverb") notifyWidgets() }
    private suspend fun notifyWidgets() {
        try { refresh() }
        catch (error: Exception) {
            if (error is CancellationException) throw error
            errors.report("widget.refresh", error)
        }
    }
}
