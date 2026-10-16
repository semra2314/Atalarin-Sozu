package com.example.kare

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.espresso.Espresso.pressBack
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.kare.core.model.WidgetSize
import kotlinx.coroutines.runBlocking
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class Phase14EditorTest {
    @get:Rule(order = 0) val onboarding = CompletedOnboardingRule()
    @get:Rule(order = 1) val compose = createAndroidComposeRule<MainActivity>()
    @Test fun libraryEditorSaveReopenRecreateAndDirtyBackPreserveWidgetInstances() {
        val app = InstrumentationRegistry.getInstrumentation().targetContext.applicationContext as KareApplication
        val library = app.container.library
        val before = runBlocking { library.widget("p-sunset") }
        val directory = java.io.File(app.noBackupFilesDir, "widget-instances")
        fun snapshot() = directory.walkTopDown().filter { it.isFile }.associate { it.relativeTo(directory).path to it.readBytes().toList() }
        val launcherState = snapshot()
        runBlocking { library.install(app.container.widgets.template("p-sunset"), WidgetSize.SMALL) }
        fun openEditor() {
            compose.onNodeWithTag("nav-${R.string.library_title}").performClick()
            compose.onNode(hasScrollToIndexAction()).performScrollToNode(hasTestTag("edit-p-sunset"))
            compose.onNodeWithTag("edit-p-sunset").performClick()
            compose.waitUntil(10_000) { compose.onAllNodesWithTag("editor-text").fetchSemanticsNodes().isNotEmpty() }
        }
        try {
            openEditor()
            compose.onNodeWithTag("editor-text").performScrollTo().performTextReplacement("Phase 14 saved words")
            compose.onNodeWithTag("editor-preview-text").performScrollTo().assertTextEquals("Phase 14 saved words")
            compose.onNodeWithText(compose.activity.getString(R.string.editor_center)).performScrollTo().performClick().assertIsSelected()
            compose.onNodeWithTag("editor-save").performScrollTo().performClick()
            compose.waitUntil(10_000) { compose.onAllNodesWithTag("editor-saved").fetchSemanticsNodes().isNotEmpty() }
            pressBack(); openEditor()
            compose.onNodeWithTag("editor-text").performScrollTo().assertTextContains("Phase 14 saved words")
            compose.activityRule.scenario.recreate()
            compose.waitUntil(10_000) { compose.onAllNodesWithTag("editor-text").fetchSemanticsNodes().isNotEmpty() }
            compose.onNodeWithTag("editor-text").performScrollTo().assertTextContains("Phase 14 saved words")
            compose.onNodeWithTag("editor-text").performTextReplacement("Unsaved words")
            androidx.test.espresso.Espresso.closeSoftKeyboard()
            pressBack()
            compose.onNodeWithText(compose.activity.getString(R.string.editor_keep)).performClick()
            compose.onNodeWithText(compose.activity.getString(R.string.action_back)).performScrollTo().performClick()
            compose.onNodeWithText(compose.activity.getString(R.string.editor_discard)).performClick()
            assertEquals("Phase 14 saved words", runBlocking { library.widget("p-sunset") }!!.content!!.texts.single().text)
            assertEquals(launcherState, snapshot())
        } finally {
            runBlocking {
                if(before == null) library.remove("p-sunset")
                else before.content?.let { library.updateContent("p-sunset", it) }
            }
        }
    }
}
