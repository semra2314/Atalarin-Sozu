package com.example.kare

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.kare.widget.ProverbConfigurationActivity
import com.example.kare.widget.ProverbReceiver
import java.io.File
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** Uses a test-owned real ID; checks semantics, not TalkBack speech synthesis. */
@RunWith(AndroidJUnit4::class)
class ProverbConfigurationAccessibilityTest {
    @get:Rule val compose = createEmptyComposeRule()

    @Test fun corruptConfigurationAnnouncesRecoveryAndExposesSelectableContent() {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val host = AppWidgetHost(context, 87111)
        val id = host.allocateAppWidgetId()
        instrumentation.uiAutomation.adoptShellPermissionIdentity("android.permission.BIND_APPWIDGET")
        try {
            assertTrue(AppWidgetManager.getInstance(context).bindAppWidgetIdIfAllowed(
                id, ComponentName(context, ProverbReceiver::class.java)))
        } finally { instrumentation.uiAutomation.dropShellPermissionIdentity() }
        val file = File(context.noBackupFilesDir, "widget-instances/$id.json")
        file.parentFile!!.mkdirs()
        file.writeText("broken")
        try {
            ActivityScenario.launch<ProverbConfigurationActivity>(Intent(context, ProverbConfigurationActivity::class.java)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)).use {
                val recovery = context.getString(R.string.proverb_recovery)
                compose.waitUntil(10_000) { compose.onAllNodesWithText(recovery).fetchSemanticsNodes().isNotEmpty() }
                compose.onNodeWithText(recovery).performScrollTo()
                    .assert(SemanticsMatcher.expectValue(SemanticsProperties.LiveRegion, LiveRegionMode.Polite))
                compose.onNodeWithText(context.getString(R.string.proverb_all)).performScrollTo().assertIsSelected()
                compose.onNodeWithText(context.getString(R.string.proverb_idioms)).performScrollTo().performClick().assertIsSelected()
                compose.onNodeWithText(context.getString(R.string.action_save)).performScrollTo().assertIsEnabled()
                // Merely visiting/choosing must not repair or save without the user's Save action.
                assertTrue(file.readText() == "broken")
            }
        } finally {
            host.deleteHost()
            file.delete() // Test-owned state only; Library was never mutated.
        }
    }
}
