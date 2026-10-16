package com.example.kare.editor

import androidx.lifecycle.ViewModelStore
import com.example.kare.core.data.catalog.LocalCatalogDataSource
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import com.example.kare.core.repository.RepositoryException
import com.example.kare.feature.editor.*
import com.example.kare.presentation.LibraryFake
import kotlinx.coroutines.*
import kotlinx.coroutines.test.*
import org.junit.*
import org.junit.Assert.*

internal fun editorWidget() = runBlocking { LocalCatalogDataSource().load() }.templates.first { it.id == "p-sunset" }.let {
    InstalledWidget(it.id, it.name, it.author.displayName, it.category, it.primarySize, it.theme, it.content, isCustomizable = it.isEditable)
}
@OptIn(ExperimentalCoroutinesApi::class)
class EditorViewModelTest {
    private val dispatcher = StandardTestDispatcher()
    private val store = ViewModelStore()
    private val repo = LibraryFake()
    private val errors = mutableListOf<Throwable>()
    private fun vm(id: String = "p-sunset") = EditorViewModel(id, repo, ErrorReporter { _, e -> errors += e }).also { store.put(id, it) }
    @Before fun setup() { Dispatchers.setMain(dispatcher); repo.rows.value = listOf(editorWidget()) }
    @After fun teardown() { store.clear(); Dispatchers.resetMain() }
    @Test fun loadDraftRevertSaveAndReopenThroughRepository() = runTest {
        val vm = vm(); assertEquals(EditorState.Loading, vm.state.value); runCurrent()
        fun ready() = vm.state.value as EditorState.Ready
        assertEquals(editorWidget().content, ready().draft.content)
        val original = ready().draft.primary.text
        vm.edit { it.text("New\ntext") }; assertTrue(ready().dirty)
        vm.edit { it.text(original) }; assertFalse(ready().dirty)
        vm.edit { it.text("Saved").background("FFFFFF") }; vm.save(); runCurrent()
        assertFalse(ready().dirty); assertTrue(ready().saved)
        assertEquals("Saved", repo.rows.value.single().content!!.texts.single().text)
        assertEquals(editorWidget().theme, repo.rows.value.single().theme)
        val reopened = vm(); runCurrent()
        assertEquals("Saved", (reopened.state.value as EditorState.Ready).draft.primary.text)
    }
    @Test fun failuresKeepDraftAndDoNotExitOrClaimSave() = runTest {
        val vm = vm(); runCurrent(); vm.edit { it.text("Unsaved") }
        repo.mutation = { throw RepositoryException.Persistence(java.io.IOException()) }
        var exits = 0; vm.save { exits++ }; runCurrent()
        val state = vm.state.value as EditorState.Ready
        assertTrue(state.dirty); assertFalse(state.saved); assertEquals(UiError.STORAGE, state.error); assertEquals(0, exits)
        vm.discard(); assertFalse((vm.state.value as EditorState.Ready).dirty)
    }
    @Test fun missingInvalidAndUnsupportedFailSafely() = runTest {
        val missing = vm("absent"); runCurrent(); assertEquals(EditorState.Failed(UiError.NOT_FOUND), missing.state.value)
        repo.rows.value = listOf(editorWidget().copy(content = editorWidget().content!!.copy(texts = listOf(editorWidget().content!!.texts.single().copy(colorHex = "bad")))))
        val corrupt = vm(); runCurrent(); assertEquals(EditorState.Failed(UiError.INVALID_DATA), corrupt.state.value)
        repo.rows.value = listOf(editorWidget().copy(isCustomizable = false))
        val unsupported = vm(); runCurrent(); assertEquals(EditorState.Unsupported, unsupported.state.value)
    }
    @Test fun capabilityProtectsDynamicAndComplexDesigns() {
        assertEquals(EditorCapability.LIMITED, EditorCapabilities.forWidget(editorWidget()))
        for(id in listOf("t-proverb", "t-hush")) assertEquals(EditorCapability.UNSUPPORTED, EditorCapabilities.forWidget(editorWidget().copy(templateId = id)))
        assertEquals(EditorCapability.UNSUPPORTED, EditorCapabilities.forWidget(editorWidget().copy(content = editorWidget().content!!.copy(stickers = listOf(WidgetContent.Sticker())))))
    }
    @Test fun saveThenExitOnlyRunsAfterCommitAndEditingIsDisabledWhileSaving() = runTest {
        val gate = CompletableDeferred<Unit>(); repo.mutation = { gate.await() }
        val vm = vm(); runCurrent(); vm.edit { it.text("Commit") }
        var exit = false; vm.save { exit = true }; runCurrent()
        vm.edit { it.text("Should not overwrite") }; assertFalse(exit)
        gate.complete(Unit); runCurrent()
        assertTrue(exit); assertEquals("Commit", (vm.state.value as EditorState.Ready).draft.primary.text)
    }
}
