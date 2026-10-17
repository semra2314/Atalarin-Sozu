package com.example.kare.widget

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.example.kare.core.data.catalog.LocalCatalogDataSource
import com.example.kare.core.data.widget.*
import com.example.kare.core.model.*
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.presentation.LibraryFake
import kotlinx.coroutines.runBlocking
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.io.File
import java.util.UUID

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class EditableWidgetTest {
    private lateinit var directory: File
    private val errors = ErrorReporter { _, _ -> }
    private val library = LibraryFake()
    private lateinit var store: EditableBindingStore
    private lateinit var repository: EditableWidgetRepository
    private fun widget(id: String) = runBlocking { LocalCatalogDataSource().load() }.templates.first { it.id == id }.let {
        InstalledWidget(it.id, it.name, it.author.displayName, it.category, it.primarySize, it.theme, it.content, isCustomizable = it.isEditable)
    }
    @Before fun setup() {
        directory = File(ApplicationProvider.getApplicationContext<Context>().cacheDir, "editable-${UUID.randomUUID()}").apply { mkdirs() }
        store = EditableBindingStore(directory)
        library.rows.value = listOf(widget("p-sunset"), widget("p-pastel"))
        repository = EditableWidgetRepository(store, library, errors)
    }
    @After fun cleanup() { directory.deleteRecursively() }
    @Test fun capabilitiesUseInstalledPayloadAndKeepSpecializedProviders() {
        assertEquals(LauncherWidgetType.GENERIC_EDITABLE, LauncherWidgetType.forWidget(widget("p-sunset")))
        assertEquals(LauncherWidgetType.GENERIC_EDITABLE, LauncherWidgetType.forWidget(widget("p-pastel")))
        assertEquals(LauncherWidgetType.PROVERB, LauncherWidgetType.forWidget(widget("t-proverb")))
        assertEquals(LauncherWidgetType.HUSH, LauncherWidgetType.forWidget(widget("t-hush")))
        assertNull(LauncherWidgetType.forWidget(widget("t-custom")))
        assertNull(LauncherWidgetType.forWidget(widget("p-sunset").copy(isCustomizable = false)))
    }
    @Test fun bindingsSurviveReopeningAndDeletionIsIsolated() = runBlocking {
        repository.bind(11, "p-sunset"); repository.bind(12, "p-sunset"); repository.bind(13, "p-pastel")
        val reopened = EditableWidgetRepository(EditableBindingStore(directory), library, errors)
        assertEquals(EditableBinding("p-sunset"), reopened.binding(11))
        reopened.delete(11)
        assertNull(reopened.binding(11)); assertEquals("p-sunset", reopened.binding(12)!!.installedId)
        assertEquals("p-pastel", reopened.binding(13)!!.installedId)
        assertEquals(2, library.rows.value.size)
    }
    @Test fun savesUpdateOnlyMatchingInstancesAndRemovalShowsRecovery() = runBlocking {
        repository.bind(11, "p-sunset"); repository.bind(12, "p-sunset"); repository.bind(13, "p-pastel")
        File(directory, "14.json").writeText("broken")
        val updated = mutableListOf<Int>()
        val sync = EditableWidgetSyncCoordinator(repository, { intArrayOf(11,12,13,14) }, { updated += it }, errors)
        val decorated = WidgetRefreshingLibraryRepository(library, { fail("Must not refresh Proverb/Hush") }, errors, sync::sync)
        val original = library.widget("p-sunset")!!.content!!
        val content = original.copy(texts = listOf(original.texts.single().copy(text = "Saved customization", colorHex = "123456", alignment = WidgetContent.TextAlign.TRAILING, fontStyle = WidgetContent.FontStyle.MONOSPACED)), background = WidgetContent.Background.Color(listOf("ABCDEF")))
        decorated.updateContent("p-sunset", content)
        assertEquals(listOf(11,12), updated)
        val saved = (repository.snapshot(11) as EditableSnapshot.Ready).widget.content!!
        assertEquals(content, saved)
        assertEquals("ABCDEF", (saved.background as WidgetContent.Background.Color).hexes.single())
        assertEquals(androidx.glance.text.FontFamily.Monospace, editableFont(saved.texts.single().fontStyle))
        assertEquals(0xFF123456.toInt(), editableArgb(saved.texts.single().colorHex))
        assertEquals(androidx.glance.text.TextAlign.End, editableAlignment(saved.texts.single().alignment))
        updated.clear(); decorated.remove("p-sunset")
        assertEquals(listOf(11,12), updated)
        assertEquals(EditableSnapshot.MissingLibrary, repository.snapshot(11))
        assertTrue(repository.snapshot(13) is EditableSnapshot.Ready)
    }
    @Test fun invalidMissingUnsupportedAndCorruptStateFailSafelyAndCanBeRepaired() = runBlocking {
        assertEquals(EditableSnapshot.MissingBinding, repository.snapshot(10))
        File(directory,"10.json").writeText("broken")
        assertEquals(EditableSnapshot.Unavailable, repository.snapshot(10))
        repository.bind(10, "p-sunset")
        assertTrue(repository.snapshot(10) is EditableSnapshot.Ready)
        val row = library.rows.value.first()
        library.rows.value = listOf(row.copy(content = row.content!!.copy(texts = listOf(row.content.texts.single().copy(colorHex = "invalid")))) )
        assertEquals(EditableSnapshot.Unavailable, repository.snapshot(10))
        library.rows.value = listOf(row.copy(isCustomizable = false))
        assertEquals(EditableSnapshot.Unavailable, repository.snapshot(10))
        library.rows.value = emptyList()
        assertEquals(EditableSnapshot.MissingLibrary, repository.snapshot(10))
    }
    @Test fun bindingCodecRejectsOtherTypesAndVersionsAndLocaleKeysMatch() {
        for(json in listOf("{\"version\":2,\"type\":\"editable\",\"installedId\":\"p-sunset\"}", "{\"version\":1,\"type\":\"hush\",\"installedId\":\"p-sunset\"}")) {
            assertTrue(runCatching { EditableBindingStore.decode(json) }.isFailure)
        }
        fun strings(path: String): Map<String,String> {
            val doc = javax.xml.parsers.DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(File(path))
            val nodes = doc.getElementsByTagName("string")
            return (0 until nodes.length).associate { val e = nodes.item(it) as org.w3c.dom.Element; e.getAttribute("name") to e.textContent }
        }
        val en = strings("src/main/res/values/editable_widget_strings.xml")
        val tr = strings("src/main/res/values-tr/editable_widget_strings.xml")
        assertEquals(en.keys,tr.keys)
        en.forEach { (key,value) -> assertTrue(value.isNotBlank()); assertTrue(tr.getValue(key).isNotBlank()) }
    }
    @Test fun allPortableFontsAndAlignmentHaveExplicitNativeMappings() {
        assertEquals(androidx.glance.text.FontFamily.Serif, editableFont(WidgetContent.FontStyle.SERIF))
        assertEquals(androidx.glance.text.FontFamily.Monospace, editableFont(WidgetContent.FontStyle.MONOSPACED))
        assertEquals(androidx.glance.text.FontFamily.SansSerif, editableFont(WidgetContent.FontStyle.ROUNDED))
        assertEquals(androidx.glance.text.FontFamily.SansSerif, editableFont(WidgetContent.FontStyle.STANDARD))
        assertEquals(androidx.glance.text.TextAlign.Start, editableAlignment(WidgetContent.TextAlign.LEADING))
        assertEquals(androidx.glance.text.TextAlign.Center, editableAlignment(WidgetContent.TextAlign.CENTER))
        assertEquals(0xFFFFFFFF.toInt(), editableArgb("ffffff"))
    }
    @Test fun genericPlacementUsesExistingCoordinatorWithoutPrematureBinding() = runBlocking {
        var requested: Pair<LauncherWidgetType,String?>? = null
        var supported = false
        val manager = object: WidgetPlacementManager {
            override fun supportsPinning() = supported
            override fun request(type: LauncherWidgetType) = error("ID must be passed")
            override fun request(type: LauncherWidgetType, installedId: String?): Boolean { requested = type to installedId; return true }
        }
        val coordinator = WidgetPlacementCoordinator(manager)
        assertEquals(PlacementResult.UNSUPPORTED, coordinator.request(widget("p-sunset")))
        assertNull(requested)
        supported = true
        assertEquals(PlacementResult.REQUESTED, coordinator.request(widget("p-sunset")))
        assertEquals(LauncherWidgetType.GENERIC_EDITABLE to "p-sunset", requested)
        assertTrue(directory.listFiles()!!.isEmpty())
    }

    @Test fun portableSizingPreservesTemplateGeometryAndNormalizesOnlyRendering() {
        val sunset = widget("p-sunset").content!!.texts.single()
        val pastel = widget("p-pastel").content!!.texts.single()
        val (left, right) = EditableRendering.horizontalInsets(sunset, 300f)
        assertEquals(0f, left, .01f); assertEquals(84f, right, .01f)
        val centered = EditableRendering.horizontalInsets(pastel, 300f)
        assertEquals(centered.first, centered.second, .01f)
        assertEquals(8f, EditableRendering.textSize(8.0, 160f, 140f), .01f)
        assertTrue(EditableRendering.textSize(30.0, 500f, 500f) > EditableRendering.textSize(30.0, 160f, 140f))
        assertEquals(22f, EditableRendering.radius(Double.NaN), .01f)
        assertEquals(60f, EditableRendering.radius(900.0), .01f)
        assertEquals(0xFF1D1D1F.toInt(), editableArgb("not a color"))
        assertEquals(0xFF1D1D1F.toInt(), editableArgb("#FFFFFF"))
    }

    @Test fun emptyMultilineTurkishAndLongTextRemainUnmodified() = runBlocking {
        repository.bind(11, "p-sunset")
        val row = library.rows.value.first()
        for (value in listOf("", "  ", "İyi akşamlar\nçığ öşü", "longword".repeat(2000))) {
            val content = row.content!!.copy(texts = listOf(row.content.texts.single().copy(text = value)))
            library.updateContent(row.templateId, content)
            assertEquals(value, (repository.snapshot(11) as EditableSnapshot.Ready).widget.content!!.texts.single().text)
        }
    }

    @Test fun updateFailureCannotUndoSaveOrBlockOtherBindingsAcrossRepeatedSaves() = runBlocking {
        repository.bind(11, "p-sunset"); repository.bind(12, "p-sunset"); repository.bind(13, "p-pastel")
        val updates = mutableListOf<Int>()
        val sync = EditableWidgetSyncCoordinator(repository, { intArrayOf(11, 12, 13) }, {
            updates += it
            if (it == 11) error("Host unavailable")
        }, errors)
        val decorated = WidgetRefreshingLibraryRepository(library, { fail("Specialized provider refreshed") }, errors, sync::sync)
        val original = library.widget("p-sunset")!!.content!!
        repeat(3) { index ->
            val content = original.copy(texts = listOf(original.texts.single().copy(text = "Version $index")))
            decorated.updateContent("p-sunset", content)
            assertEquals(content, library.widget("p-sunset")!!.content)
        }
        assertEquals(listOf(11, 12, 11, 12, 11, 12), updates)
        assertEquals(widget("p-pastel").content, library.widget("p-pastel")!!.content)
    }
}
