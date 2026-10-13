package com.example.kare

import android.appwidget.AppWidgetHost
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.kare.core.model.*
import com.example.kare.widget.*
import kotlinx.coroutines.runBlocking
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith

/** Native real-ID configuration and resize; only test-owned instances are cleaned up. */
@RunWith(AndroidJUnit4::class)
class HushWidgetIntegrationTest {
    @get:Rule val compose = createEmptyComposeRule()

    @Test fun twoHushConfigurationsSurviveResizeAndDeletionWithoutAffectingProverb() = runBlocking {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val container = (context.applicationContext as KareApplication).container
        val hadHush = container.library.widget("t-hush") != null
        val hadProverb = container.library.widget("t-proverb") != null
        val host = AppWidgetHost(context, 87112)
        val manager = AppWidgetManager.getInstance(context)
        val ids = mutableListOf<Int>()
        try {
            instrumentation.uiAutomation.adoptShellPermissionIdentity("android.permission.BIND_APPWIDGET")
            try {
                listOf(HushReceiver::class.java, HushReceiver::class.java, ProverbReceiver::class.java).forEach { receiver ->
                    val id = host.allocateAppWidgetId(); ids += id
                    assertTrue(manager.bindAppWidgetIdIfAllowed(id, ComponentName(context, receiver)))
                }
            } finally { instrumentation.uiAutomation.dropShellPermissionIdentity() }
            container.widgetInstances.configure(ids[2], ProverbSelection.IDIOMS)
            assertNull(container.hushInstances.configuration(ids[0]))
            listOf(R.string.hush_language_english, R.string.hush_language_turkish).forEachIndexed { index, label ->
                ActivityScenario.launch<HushConfigurationActivity>(Intent(context, HushConfigurationActivity::class.java)
                    .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, ids[index])).use {
                    compose.waitUntil(10_000) { compose.onAllNodesWithText(context.getString(label)).fetchSemanticsNodes().isNotEmpty() }
                    compose.onNodeWithText(context.getString(label)).performScrollTo().performClick().assertIsSelected()
                    compose.onNodeWithText(context.getString(R.string.action_save)).performScrollTo().performClick()
                    compose.waitUntil(10_000) { it.state == androidx.lifecycle.Lifecycle.State.DESTROYED }
                }
            }
            manager.updateAppWidgetOptions(ids[0], Bundle().apply {
                putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
                putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, 180)
                putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 180)
                putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 180)
            })
            HushWidget.refreshAll(context)
            assertEquals(HushLanguage.ENGLISH, container.hushInstances.configuration(ids[0])!!.language)
            assertEquals(HushLanguage.TURKISH, container.hushInstances.configuration(ids[1])!!.language)
            container.hushInstances.delete(ids[0])
            assertNull(container.hushInstances.configuration(ids[0]))
            assertEquals(HushLanguage.TURKISH, container.hushInstances.configuration(ids[1])!!.language)
            assertEquals(ProverbSelection.IDIOMS, container.widgetInstances.configuration(ids[2])!!.selection)
            assertNotNull(container.library.widget("t-hush"))
        } finally {
            host.deleteHost()
            ids.take(2).forEach { container.hushInstances.delete(it) }
            ids.getOrNull(2)?.let { container.widgetInstances.delete(it) }
            if (!hadHush) container.library.remove("t-hush")
            if (!hadProverb) container.library.remove("t-proverb")
        }
    }
}
