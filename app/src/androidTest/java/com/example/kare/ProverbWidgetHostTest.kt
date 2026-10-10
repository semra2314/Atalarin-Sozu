package com.example.kare

import android.appwidget.*
import android.content.ComponentName
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.kare.core.model.ProverbSelection
import com.example.kare.widget.*
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith

/** Real platform binding/rendering/deletion, with a test-owned host (not a launcher simulation). */
@RunWith(AndroidJUnit4::class)
class ProverbWidgetHostTest {
    @Test fun twoBoundInstancesRenderAndDeleteIndependently() = runBlocking {
        val instrumentation = InstrumentationRegistry.getInstrumentation()
        val context = instrumentation.targetContext
        val repository = (context.applicationContext as KareApplication).container.widgetInstances
        val manager = AppWidgetManager.getInstance(context)
        val host = AppWidgetHost(context, 87103)
        val ids = intArrayOf(host.allocateAppWidgetId(), host.allocateAppWidgetId())
        val views = mutableListOf<AppWidgetHostView>()
        instrumentation.uiAutomation.adoptShellPermissionIdentity("android.permission.BIND_APPWIDGET")
        try {
            ids.forEach { id ->
                assertTrue(manager.bindAppWidgetIdIfAllowed(id, ComponentName(context, ProverbReceiver::class.java)))
            }
            instrumentation.runOnMainSync {
                host.startListening()
                ids.forEach { views += host.createView(context, it, manager.getAppWidgetInfo(it)) }
            }
            fun resize(id: Int, width: Int, height: Int) {
                manager.updateAppWidgetOptions(id, Bundle().apply {
                    putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, width)
                    putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH, width)
                    putInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, height)
                    putInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, height)
                    if (android.os.Build.VERSION.SDK_INT >= 31) putParcelableArrayList(
                        AppWidgetManager.OPTION_APPWIDGET_SIZES, arrayListOf(SizeF(width.toFloat(), height.toFloat())))
                })
            }
            resize(ids[0], 300, 400); resize(ids[1], 300, 400)
            repository.configure(ids[0], ProverbSelection.PROVERBS)
            repository.configure(ids[1], ProverbSelection.IDIOMS)
            ProverbWidget.refreshAll(context)
            fun text(view: View): String = when(view) {
                is TextView -> view.text.toString()
                is ViewGroup -> (0 until view.childCount).joinToString(" ") { text(view.getChildAt(it)) }
                else -> ""
            }
            fun await(check: () -> Boolean) {
                val end = System.currentTimeMillis() + 20_000
                while (System.currentTimeMillis() < end) {
                    if (check()) return
                    Thread.sleep(100)
                }
                fail("Widget state did not arrive")
            }
            await {
                var ready = false
                instrumentation.runOnMainSync {
                    views.forEach { it.measure(View.MeasureSpec.makeMeasureSpec(900, View.MeasureSpec.EXACTLY),
                        View.MeasureSpec.makeMeasureSpec(1200, View.MeasureSpec.EXACTLY)); it.layout(0, 0, 900, 1200) }
                    ready = text(views[0]).contains(context.getString(R.string.proverb_kind)) &&
                    text(views[1]).contains(context.getString(R.string.proverb_idiom)) }
                ready
            }
            assertEquals(ProverbSelection.PROVERBS, repository.configuration(ids[0])!!.selection)
            assertEquals(ProverbSelection.IDIOMS, repository.configuration(ids[1])!!.selection)
            // Resize does not create or replace instance configuration; the other ID stays independent.
            resize(ids[0], 180, 180); resize(ids[1], 500, 500)
            ProverbWidget.refreshAll(context)
            assertEquals(ProverbSelection.PROVERBS, repository.configuration(ids[0])!!.selection)
            assertEquals(ProverbSelection.IDIOMS, repository.configuration(ids[1])!!.selection)
            host.deleteAppWidgetId(ids[0])
            await { runBlocking { repository.configuration(ids[0]) == null } }
            assertNotNull(repository.configuration(ids[1]))
            assertNotNull((context.applicationContext as KareApplication).container.library.widget("t-proverb"))
        } finally {
            host.deleteHost()
            instrumentation.runOnMainSync { host.stopListening() }
            instrumentation.uiAutomation.dropShellPermissionIdentity()
        }
    }
}
