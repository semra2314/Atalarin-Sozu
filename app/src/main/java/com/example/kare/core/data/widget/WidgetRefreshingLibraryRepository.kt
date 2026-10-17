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
    private val syncEditable: suspend (String) -> Unit = {},
) : LibraryRepository by delegate {
    override suspend fun install(template: WidgetTemplate, size: WidgetSize): InstalledWidget =
        delegate.install(template, size).also { if (LauncherWidgetType.forTemplate(template.id) != null) notifyWidgets(); notifyEditable(template.id) }
    override suspend fun remove(templateId: String): InstalledWidget? =
        delegate.remove(templateId).also { if (LauncherWidgetType.forTemplate(templateId) != null) notifyWidgets(); notifyEditable(templateId) }
    override suspend fun updateContent(templateId: String, content: WidgetContent) {
        delegate.updateContent(templateId, content)
        notifyEditable(templateId)
    }
    private suspend fun notifyEditable(id: String) {
        try { syncEditable(id) } catch (error: Exception) {
            if (error is CancellationException) throw error
            errors.report("editable.refresh", error)
        }
    }
    private suspend fun notifyWidgets() {
        try { refresh() }
        catch (error: Exception) {
            if (error is CancellationException) throw error
            errors.report("widget.refresh", error)
        }
    }
}
