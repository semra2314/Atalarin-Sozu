package com.example.kare.editor

import androidx.compose.runtime.*
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density
import com.example.kare.core.design.KareTheme
import com.example.kare.feature.editor.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.*

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], qualifiers = "en-rUS-w320dp-h640dp")
@LooperMode(LooperMode.Mode.PAUSED)
class EditorUiTest {
    @get:Rule val compose = createComposeRule()
    @Test fun previewDirtyBackDiscardAndSaveExitAtLargeFont() {
        val widget = editorWidget(); val initial = EditorDraft.from(widget)
        val state = mutableStateOf(EditorState.Ready(widget, initial, initial))
        var exits = 0
        compose.setContent { CompositionLocalProvider(LocalDensity provides Density(LocalDensity.current.density, 2f)) {
            KareTheme { EditorContent(state.value,
                { change -> state.value = state.value.copy(draft = change(state.value.draft)) },
                { state.value = state.value.copy(draft = initial) }, {},
                { done -> state.value = state.value.copy(original = state.value.draft, saved = true); done() }, { exits++ }) }
        } }
        compose.onNodeWithTag("editor-text").performScrollTo().performTextReplacement("Live words")
        compose.onNodeWithTag("editor-preview-text").performScrollTo().assertTextEquals("Live words")
        compose.onNodeWithText("Back").performScrollTo().performClick()
        compose.onNodeWithText("Keep editing").performClick(); assertEquals(0, exits)
        compose.onNodeWithText("Back").performScrollTo().performClick()
        compose.onNodeWithText("Discard and exit").performClick(); assertEquals(initial, state.value.draft); assertEquals(1, exits)
        compose.onNodeWithTag("editor-text").performScrollTo().performTextReplacement("Save before exit")
        compose.onNodeWithText("Back").performScrollTo().performClick()
        compose.onNodeWithText("Save and exit").performClick(); assertEquals(2, exits); assertFalse(state.value.dirty)
    }
    @Test fun paletteUpdatesPortableDraftAndRenderedTextColor() {
        val widget = editorWidget(); val initial = EditorDraft.from(widget)
        val state = mutableStateOf(EditorState.Ready(widget, initial, initial))
        compose.setContent { KareTheme { EditorContent(state.value,
            { change -> state.value = state.value.copy(draft = change(state.value.draft)) }, {}, {}, {}, {}) } }
        compose.onAllNodesWithText("Coral")[0].performScrollTo().performClick().assertIsSelected()
        assertEquals("D44A33", state.value.draft.primary.colorHex)
        val layouts = mutableListOf<androidx.compose.ui.text.TextLayoutResult>()
        compose.onNodeWithTag("editor-preview-text").performScrollTo().performSemanticsAction(androidx.compose.ui.semantics.SemanticsActions.GetTextLayoutResult) { it(layouts) }
        assertEquals(androidx.compose.ui.graphics.Color(0xFFD44A33), layouts.single().layoutInput.style.color)
    }
    @Test fun libraryExposesOnlyCompatibleEditActions() {
        val editable = editorWidget()
        val fixed = editable.copy(templateId = "t-proverb", isCustomizable = false)
        var opened: String? = null
        compose.setContent { KareTheme { com.example.kare.feature.library.LibraryContent(
            com.example.kare.feature.library.LibraryUiState(widgets = com.example.kare.core.presentation.LoadState.Loaded(listOf(editable, fixed))),
            {}, {}, {}, {}, {}, {}, {}, onEdit = { opened = it }) } }
        compose.onNode(hasScrollToIndexAction()).performScrollToNode(hasTestTag("edit-p-sunset"))
        compose.onNodeWithTag("edit-p-sunset").performClick()
        assertEquals("p-sunset", opened)
        compose.onNode(hasScrollToIndexAction()).performScrollToNode(hasTestTag("installed-t-proverb"))
        compose.onNodeWithTag("edit-t-proverb").assertDoesNotExist()
    }
    @Test fun editorResourceKeysAndFormatsMatch() {
        fun read(locale: String) = javax.xml.parsers.DocumentBuilderFactory.newInstance().newDocumentBuilder()
            .parse(java.io.File("src/main/res/$locale/editor_strings.xml")).getElementsByTagName("string").let { nodes ->
                (0 until nodes.length).associate { nodes.item(it).attributes.getNamedItem("name").nodeValue to nodes.item(it).textContent }
            }
        val en = read("values"); val tr = read("values-tr"); assertEquals(en.keys, tr.keys)
        val pattern = Regex("%[0-9]+\\$[sd]")
        en.forEach { (key, value) -> assertTrue(tr.getValue(key).isNotBlank()); assertEquals(pattern.findAll(value).map { it.value }.toList(), pattern.findAll(tr.getValue(key)).map { it.value }.toList()) }
    }
}
