package com.example.kare.feature.editor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.model.InstalledWidget
import com.example.kare.core.presentation.*
import com.example.kare.core.repository.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

sealed interface EditorState {
    data object Loading : EditorState
    data object Unsupported : EditorState
    data class Failed(val error: UiError) : EditorState
    data class Ready(val widget: InstalledWidget, val original: EditorDraft, val draft: EditorDraft,
        val saving: Boolean = false, val saved: Boolean = false, val error: UiError? = null) : EditorState {
        val dirty get() = draft != original
    }
}
class EditorViewModel(val templateId: String, private val library: LibraryRepository,
    private val errors: ErrorReporter) : ViewModel() {
    private val mutable = MutableStateFlow<EditorState>(EditorState.Loading)
    val state = mutable.asStateFlow()
    private var job: Job? = null
    init { reload() }
    fun reload() {
        val current = mutable.value as? EditorState.Ready
        if (current?.saving == true || current?.dirty == true) return
        job?.cancel(); mutable.value = EditorState.Loading
        job = viewModelScope.launch {
            try {
                val widget = library.widget(templateId) ?: throw RepositoryException.NotFound(templateId)
                mutable.value = if (EditorCapabilities.forWidget(widget) == EditorCapability.UNSUPPORTED) EditorState.Unsupported
                else EditorDraft.from(widget).let { EditorState.Ready(widget, it, it) }
            } catch (e: Exception) { mutable.value = EditorState.Failed(e.toUiError("editor.load", errors)) }
        }
    }
    fun edit(change: (EditorDraft) -> EditorDraft) {
        val s = mutable.value as? EditorState.Ready ?: return
        if (!s.saving) mutable.value = s.copy(draft = change(s.draft), saved = false, error = null)
    }
    fun discard() {
        val s = mutable.value as? EditorState.Ready ?: return
        if (!s.saving) mutable.value = s.copy(draft = s.original, saved = false, error = null)
    }
    fun save(onSaved: () -> Unit = {}) {
        val s = mutable.value as? EditorState.Ready ?: return
        if (s.saving || !s.dirty) return
        mutable.value = s.copy(saving = true, error = null)
        job = viewModelScope.launch {
            try {
                val content = s.draft.validate().content
                library.updateContent(templateId, content)
                mutable.value = s.copy(widget = s.widget.copy(content = content), original = s.draft, saving = false, saved = true)
                onSaved()
            } catch (e: Exception) {
                mutable.value = s.copy(error = e.toUiError("editor.save", errors), saving = false)
            }
        }
    }
}
