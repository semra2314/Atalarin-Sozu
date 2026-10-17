package com.example.kare

import android.appwidget.*
import android.content.ComponentName
import android.content.Intent
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createEmptyComposeRule
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.kare.core.data.widget.*
import com.example.kare.core.model.*
import com.example.kare.widget.*
import java.io.File
import kotlinx.coroutines.runBlocking
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class EditableWidgetHostTest {
    @get:Rule val compose = createEmptyComposeRule()
    @Test fun configuredInstancesRenderSavedEditsResizeRecoverAndDeleteIndependently() = runBlocking {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val container = (context.applicationContext as KareApplication).container
        val original = container.library.widget("p-sunset")
        val originalPastel = container.library.widget("p-pastel")
        val template = container.widgets.template("p-sunset")
        val installed = container.library.install(template, template.primarySize)
        val host = AppWidgetHost(context, 87115)
        val manager = AppWidgetManager.getInstance(context)
        val ids = mutableListOf<Int>()
        val views = mutableListOf<AppWidgetHostView>()
        val priorSpecialized = File(context.noBackupFilesDir, "widget-instances").listFiles()?.associate { it.name to it.readText() }.orEmpty()
        fun text(view: View): String = when(view) {
            is TextView -> view.text.toString()
            is ViewGroup -> (0 until view.childCount).joinToString(" ") { text(view.getChildAt(it)) }
            else -> ""
        }
        fun await(check: () -> Boolean) {
            val end = System.currentTimeMillis() + 20000
            while(System.currentTimeMillis() < end) { if(check()) return; Thread.sleep(100) }
            fail("Expected widget state did not arrive")
        }
        fun rendered(expected: String, second: String = expected) {
            await {
                var ready = false
                instrumentation.runOnMainSync {
                    views.forEach { it.measure(View.MeasureSpec.makeMeasureSpec(900, View.MeasureSpec.EXACTLY), View.MeasureSpec.makeMeasureSpec(1200, View.MeasureSpec.EXACTLY)); it.layout(0,0,900,1200) }
                    ready = text(views[0]).contains(expected) && text(views[1]).contains(second)
                }
                ready
            }
        }
        fun resize(id: Int, width: Int, height: Int) {
            manager.updateAppWidgetOptions(id, Bundle().apply {
                putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH,width); putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH,width)
                putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT,height); putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT,height)
                if(android.os.Build.VERSION.SDK_INT >= 31) putParcelableArrayList(AppWidgetManager.OPTION_APPWIDGET_SIZES, arrayListOf(SizeF(width.toFloat(),height.toFloat())))
            })
        }
        try {
            instrumentation.uiAutomation.adoptShellPermissionIdentity("android.permission.BIND_APPWIDGET")
            try {
                repeat(2) {
                    val id = host.allocateAppWidgetId(); ids += id
                    assertTrue(manager.bindAppWidgetIdIfAllowed(id, ComponentName(context, EditableReceiver::class.java)))
                }
            } finally { instrumentation.uiAutomation.dropShellPermissionIdentity() }
            instrumentation.runOnMainSync { host.startListening(); ids.forEach { views += host.createView(context,it,manager.getAppWidgetInfo(it)) } }
            ids.forEach { resize(it,300,300) }
            ActivityScenario.launch<EditableConfigurationActivity>(Intent(context,EditableConfigurationActivity::class.java)
                .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID,ids[0]).putExtra(EditableConfigurationActivity.INSTALLED_ID,"p-sunset")).use {
                compose.waitUntil(10000) { compose.onAllNodesWithText(installed.name).fetchSemanticsNodes().isNotEmpty() }
                compose.onNodeWithText(installed.name).assertIsSelected()
                compose.onNodeWithText(context.getString(R.string.action_save)).performScrollTo().performClick()
                compose.waitUntil(10000) { it.state == androidx.lifecycle.Lifecycle.State.DESTROYED }
            }
            container.editableInstances.bind(ids[1],"p-sunset")
            EditableWidget.refresh(context,ids[1])
            val content = installed.content!!
            fun edited(value: String) = content.copy(texts = listOf(content.texts.single().copy(text=value)), background=WidgetContent.Background.Color(listOf("1D1D1F")))
            container.library.updateContent("p-sunset",edited("First saved version")); rendered("First saved version")
            container.library.updateContent("p-sunset",edited("Second saved version")); rendered("Second saved version")
            listOf(160 to 180, 300 to 140, 500 to 500).forEach { (w,h) -> resize(ids[0],w,h); EditableWidget.refresh(context,ids[0]); rendered("Second saved version") }
            assertEquals("p-sunset",container.editableInstances.binding(ids[1])!!.installedId)
            val pastel = container.widgets.template("p-pastel")
            container.library.install(pastel, pastel.primarySize)
            container.editableInstances.bind(ids[1], "p-pastel")
            EditableWidget.refresh(context, ids[1])
            val pastelWords = container.library.widget("p-pastel")!!.content!!.texts.single().text
            val longText = "İyi akşamlar, çığ, öşü.\n" + "unbrokenword".repeat(30)
            container.library.updateContent("p-sunset", edited(longText))
            rendered("İyi akşamlar", pastelWords)
            assertEquals(longText, container.library.widget("p-sunset")!!.content!!.texts.single().text)
            assertEquals("p-pastel", container.editableInstances.binding(ids[1])!!.installedId)
            container.editableInstances.bind(ids[1], "p-sunset")
            EditableWidget.refresh(context, ids[1])

            // Never remove a pre-existing user installation (metadata must survive testing).
            if (original == null) {
                container.library.remove("p-sunset")
                assertEquals(EditableSnapshot.MissingLibrary,container.editableInstances.snapshot(ids[0]))
                container.library.install(template,template.primarySize)
            }
            File(context.noBackupFilesDir,"editable-instances/${ids[0]}.json").writeText("broken")
            EditableWidget.refresh(context,ids[0])
            assertEquals(EditableSnapshot.Unavailable,container.editableInstances.snapshot(ids[0]))
            assertTrue(container.editableInstances.snapshot(ids[1]) is EditableSnapshot.Ready)
            container.editableInstances.bind(ids[0],"p-sunset")
            host.deleteAppWidgetId(ids[0])
            await { runBlocking { container.editableInstances.binding(ids[0]) == null } }
            assertNotNull(container.editableInstances.binding(ids[1])); assertNotNull(container.library.widget("p-sunset"))
            assertEquals(priorSpecialized,File(context.noBackupFilesDir,"widget-instances").listFiles()?.associate { it.name to it.readText() }.orEmpty())
        } finally {
            host.deleteHost()
            instrumentation.runOnMainSync { host.stopListening() }
            ids.forEach { container.editableInstances.delete(it) }
            if(original == null) container.library.remove("p-sunset") else original.content?.let { container.library.updateContent("p-sunset",it) }
            if(originalPastel == null) container.library.remove("p-pastel")
        }
    }
}
