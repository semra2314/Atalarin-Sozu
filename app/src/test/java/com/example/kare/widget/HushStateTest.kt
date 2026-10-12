package com.example.kare.widget

import android.content.Context
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModelStore
import androidx.test.core.app.ApplicationProvider
import com.example.kare.core.data.widget.*
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import com.example.kare.core.repository.WidgetRepository
import com.example.kare.presentation.*
import java.io.File
import java.time.ZonedDateTime
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.setMain
import kotlinx.coroutines.test.resetMain
import org.junit.*
import org.junit.Assert.*
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@OptIn(ExperimentalCoroutinesApi::class)
class HushStateTest {
    @get:Rule val temp = TemporaryFolder()
    private val library = LibraryFake()
    private val errors = mutableListOf<Throwable>()
    private val reporter = ErrorReporter { _, e -> errors += e }
    private val catalog = object : WidgetRepository by CatalogFake() {
        override suspend fun template(id: String) = template.copy(id = id)
    }
    private var now = ZonedDateTime.parse("2026-01-01T10:00:00Z")
    private fun repo(dir: File) = HushWidgetRepository(HushInstanceStore(dir), library, catalog, reporter) { now }

    @Test fun independentLanguagesReopenAndCoexistWithUnchangedProverbBytes() = runBlocking {
        val dir = temp.newFolder(); val repo = repo(dir)
        val proverb = WidgetInstanceStore(dir)
        proverb.save(3, WidgetInstance(selection = ProverbSelection.IDIOMS))
        val oldBytes = File(dir, "3.json").readText()
        repo.configure(1, HushLanguage.ENGLISH); repo.configure(2, HushLanguage.TURKISH)
        val reopened = repo(dir)
        assertEquals(HushLanguage.ENGLISH, reopened.configuration(1)!!.language)
        assertEquals(HushLanguage.TURKISH, reopened.configuration(2)!!.language)
        assertEquals(1, library.rows.value.size)
        assertEquals(oldBytes, File(dir, "3.json").readText())
        assertEquals(ProverbSelection.IDIOMS, WidgetInstanceStore(dir).read(3)!!.selection)
        assertEquals(HushLanguage.TURKISH, (reopened.observe(2).first() as HushSnapshot.Ready).entry.language)
    }
    @Test fun deletionAndLibraryRemovalAreSeparate() = runBlocking {
        val dir = temp.newFolder(); val repo = repo(dir)
        repo.configure(1, HushLanguage.APP); repo.configure(2, HushLanguage.TURKISH)
        repo.delete(1); repo.delete(1)
        assertEquals(HushSnapshot.NeedsConfiguration, repo.observe(1).first())
        assertNotNull(repo.configuration(2)); assertNotNull(library.widget("t-hush"))
        library.remove("t-hush")
        assertEquals(HushSnapshot.LibraryMissing, repo.observe(2).first())
        repo.configure(2, HushLanguage.ENGLISH)
        assertTrue(repo.observe(2).first() is HushSnapshot.Ready)
    }
    @Test fun missingCorruptForeignAndFutureStateDoNotRenderAsValid() = runBlocking {
        val dir = temp.newFolder(); val repo = repo(dir)
        assertEquals(HushSnapshot.NeedsConfiguration, repo.observe(1).first())
        for (json in listOf("broken", """{"version":2,"templateId":"t-hush","language":"app"}""",
            WidgetInstanceStore.encode(WidgetInstance()), """{"version":1,"templateId":"t-hush","language":"invalid"}""")) {
            File(dir, "1.json").writeText(json)
            assertEquals(HushSnapshot.Unavailable, repo.observe(1).first())
            assertEquals(json, File(dir, "1.json").readText())
        }
        try { repo.configure(0, HushLanguage.APP); fail("Invalid ID") } catch (_: IllegalArgumentException) { }
        assertEquals(4, errors.size)
    }
    @Test fun rotationUsesLocalHourDayAndPaletteBoundariesWithoutRandomRefresh() {
        assertEquals(HushPrompt.PAUSE, hushEntry(now, HushLanguage.APP).prompt) // (10 + Jan 1) % 10
        assertEquals(HushPalette.DAWN, hushEntry(now, HushLanguage.APP).palette)
        assertEquals(HushPalette.STILL, hushEntry(now.withHour(11), HushLanguage.APP).palette)
        assertEquals(HushPalette.NIGHT, hushEntry(now.withHour(20), HushLanguage.APP).palette)
        assertEquals(HushPalette.NIGHT, hushEntry(now.withHour(4), HushLanguage.APP).palette)
        assertEquals(hushEntry(now, HushLanguage.APP), hushEntry(now.plusMinutes(59), HushLanguage.APP))
        val yearEnd = ZonedDateTime.parse("2024-12-31T23:00:00+03:00")
        assertEquals(HushPrompt.BE_HERE, hushEntry(yearEnd, HushLanguage.APP).prompt) // leap day 366
        assertEquals(HushPrompt.PAUSE, hushEntry(yearEnd.plusHours(1), HushLanguage.APP).prompt)
    }
    @Test fun refreshRecomputesCurrentHourForActiveObservers() = runBlocking {
        val repo = repo(temp.newFolder()); repo.configure(1, HushLanguage.APP)
        val values = kotlinx.coroutines.channels.Channel<HushSnapshot>(10)
        val job = launch { repo.observe(1).collect { values.send(it) } }
        try {
            assertEquals(HushPrompt.PAUSE, (withTimeout(5000) { values.receive() } as HushSnapshot.Ready).entry.prompt)
            now = now.plusHours(1); repo.invalidate()
            assertEquals(HushPrompt.NOTICE, (withTimeout(5000) { values.receive() } as HushSnapshot.Ready).entry.prompt)
        } finally { job.cancelAndJoin() }
    }
    @Test fun localizedPromptMeaningMatchesIOSAndExplicitLanguageIsIndependent() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val entry = HushEntry(HushPrompt.SLOW_DOWN, HushPalette.STILL, HushLanguage.ENGLISH)
        assertEquals("slow down", hushText(context, entry))
        assertEquals("yavaşla", hushText(context, entry.copy(language = HushLanguage.TURKISH)))
        HushPrompt.entries.forEach { prompt ->
            assertTrue(hushText(context, entry.copy(prompt = prompt)).isNotBlank())
            assertTrue(hushText(context, entry.copy(prompt = prompt, language = HushLanguage.TURKISH)).isNotBlank())
        }
    }
    @Test fun corruptConfigurationRequiresExplicitSaveAndDoesNotTouchOtherTypes() = runBlocking {
        Dispatchers.setMain(UnconfinedTestDispatcher())
        val vms = ViewModelStore()
        try {
            val dir = temp.newFolder(); val repo = repo(dir)
            repo.configure(2, HushLanguage.ENGLISH)
            File(dir, "1.json").writeText("broken")
            var refreshes = 0
            val vm = HushConfigurationViewModel(1, repo, { refreshes++ }, reporter, SavedStateHandle())
            vms.put("hush", vm)
            withTimeout(5000) { vm.state.first { it.recovering } }
            vm.select(HushLanguage.TURKISH)
            assertEquals("broken", File(dir, "1.json").readText())
            vm.save()
            withTimeout(5000) { vm.state.first { it.saved } }
            assertEquals(HushLanguage.TURKISH, repo.configuration(1)!!.language)
            assertEquals(HushLanguage.ENGLISH, repo.configuration(2)!!.language)
            assertEquals(1, refreshes)
        } finally { vms.clear(); Dispatchers.resetMain() }
    }
    @Test fun libraryRefreshIncludesBothSupportedTypesButNotUnimplementedTemplates() = runBlocking {
        var count = 0
        val decorated = WidgetRefreshingLibraryRepository(library, { count++ }, reporter)
        for (id in listOf("t-hush", "t-proverb")) {
            decorated.install(template.copy(id = id), WidgetSize.SMALL)
            decorated.remove(id)
        }
        decorated.install(template.copy(id = "t-focus"), WidgetSize.SMALL)
        assertEquals(4, count)
    }
}
