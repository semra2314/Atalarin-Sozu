package com.example.kare.core.data.widget

import com.example.kare.core.model.*
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.LibraryRepository
import java.io.File
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.*
import kotlinx.serialization.json.*

data class EditableBinding(val installedId: String)

class EditableBindingStore(directory: File) : AtomicWidgetStateStore<EditableBinding>(directory, ::encode, ::decode) {
    companion object {
        fun encode(binding: EditableBinding): String {
            require(binding.installedId.isNotBlank())
            return buildJsonObject { put("version", 1); put("type", "editable"); put("installedId", binding.installedId) }.toString()
        }
        fun decode(json: String): EditableBinding {
            val root = Json.parseToJsonElement(json).jsonObject
            require(root.getValue("version").jsonPrimitive.int == 1)
            require(root.getValue("type").jsonPrimitive.content == "editable")
            return EditableBinding(root.getValue("installedId").jsonPrimitive.content.also { require(it.isNotBlank()) })
        }
    }
}

sealed interface EditableSnapshot {
    data object MissingBinding : EditableSnapshot
    data object MissingLibrary : EditableSnapshot
    data object Unavailable : EditableSnapshot
    data class Ready(val widget: InstalledWidget) : EditableSnapshot
}

/** Reads the authoritative Library copy; no content mirror, launcher API or screen state. */
class EditableWidgetRepository(
    private val store: EditableBindingStore,
    private val library: LibraryRepository,
    private val errors: ErrorReporter,
) {
    private val revisions = MutableStateFlow<Map<Int, Long>>(emptyMap())
    fun invalidate(id: Int) { revisions.update { it + (id to ((it[id] ?: 0L) + 1)) } }
    fun observe(id: Int): Flow<EditableSnapshot> = revisions.map { it[id] ?: 0L }.distinctUntilChanged().map { snapshot(id) }
    suspend fun binding(id: Int) = store.read(id)
    suspend fun choices(): List<InstalledWidget> = library.observeWidgets().first().filter {
        LauncherWidgetType.forWidget(it) == LauncherWidgetType.GENERIC_EDITABLE
    }
    suspend fun bind(id: Int, installedId: String) {
        val widget = requireNotNull(library.widget(installedId))
        require(LauncherWidgetType.forWidget(widget) == LauncherWidgetType.GENERIC_EDITABLE)
        EditableContentValidation.validate(requireNotNull(widget.content))
        store.save(id, EditableBinding(installedId))
        invalidate(id)
    }
    suspend fun delete(id: Int) { store.delete(id); invalidate(id) }
    suspend fun snapshot(id: Int): EditableSnapshot = try {
        val binding = store.read(id)
        if (binding == null) EditableSnapshot.MissingBinding else {
            val widget = library.widget(binding.installedId)
            when {
                widget == null -> EditableSnapshot.MissingLibrary
                LauncherWidgetType.forWidget(widget) != LauncherWidgetType.GENERIC_EDITABLE -> EditableSnapshot.Unavailable
                else -> {
                    EditableContentValidation.validate(requireNotNull(widget.content))
                    EditableSnapshot.Ready(widget)
                }
            }
        }
    } catch (error: Exception) {
        if (error is CancellationException) throw error
        errors.report("editable.snapshot", error)
        EditableSnapshot.Unavailable
    }
}

/** Only IDs allocated to this provider are candidates; corrupt bindings cannot block others. */
class EditableWidgetSyncCoordinator(
    private val repository: EditableWidgetRepository,
    private val activeIds: () -> IntArray,
    private val update: suspend (Int) -> Unit,
    private val errors: ErrorReporter,
) {
    suspend fun sync(installedId: String) {
        for (id in activeIds()) {
            try {
                if (repository.binding(id)?.installedId == installedId) {
                    repository.invalidate(id)
                    update(id)
                }
            } catch (error: Exception) {
                if (error is CancellationException) throw error
                errors.report("editable.sync", error)
            }
        }
    }
}
