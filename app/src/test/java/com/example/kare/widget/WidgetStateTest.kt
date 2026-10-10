package com.example.kare.widget

import com.example.kare.core.data.widget.*
import com.example.kare.core.model.*
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.*
import com.example.kare.presentation.*
import java.io.File
import java.time.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import org.junit.*
import org.junit.Assert.*
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class WidgetStateTest {
    @get:Rule val temp = TemporaryFolder()
    private val errors = mutableListOf<Throwable>()
    private val reporter = ErrorReporter { _, error -> errors += error }
    private val library = LibraryFake()
    private val catalog = object : WidgetRepository by CatalogFake() {
        override suspend fun template(id: String) = template.copy(id = id, supportedSizes = listOf(WidgetSize.MEDIUM))
    }
    private fun repo(store: WidgetInstanceStore, clock: Clock = Clock.fixed(Instant.EPOCH, ZoneOffset.UTC)) =
        ProverbWidgetRepository(store, library, catalog, reporter, clock = clock)

    @Test fun configurationRoundTripAndRepositoryReopeningPreserveIndependentInstances() = runBlocking {
        val dir = temp.newFolder(); val store = WidgetInstanceStore(dir); val repo = repo(store)
        repo.configure(41, ProverbSelection.PROVERBS); repo.configure(42, ProverbSelection.IDIOMS)
        val reopened = repo(WidgetInstanceStore(dir))
        assertEquals(ProverbSelection.PROVERBS, reopened.configuration(41)!!.selection)
        assertEquals(ProverbSelection.IDIOMS, reopened.configuration(42)!!.selection)
        assertEquals("t-proverb", reopened.configuration(42)!!.templateId)
        assertEquals(1, library.rows.value.size)
        assertTrue((reopened.observe(41).first() as ProverbSnapshot.Ready).proverb.isProverb)
        assertFalse((reopened.observe(42).first() as ProverbSnapshot.Ready).proverb.isProverb)
    }
    @Test fun deletionOnlyRemovesOneConfigurationNeverLibrary() = runBlocking {
        val store = WidgetInstanceStore(temp.newFolder()); val repo = repo(store)
        repo.configure(1, ProverbSelection.ALL); repo.configure(2, ProverbSelection.IDIOMS)
        repo.delete(1); repo.delete(1)
        assertNull(repo.configuration(1)); assertNotNull(repo.configuration(2))
        assertEquals(1, library.rows.value.size)
        assertEquals(ProverbSnapshot.NeedsConfiguration, repo.observe(1).first())
    }
    @Test fun missingCorruptAndFutureConfigurationFailSafely() = runBlocking {
        val dir = temp.newFolder(); val repo = repo(WidgetInstanceStore(dir))
        assertEquals(ProverbSnapshot.NeedsConfiguration, repo.observe(1).first())
        File(dir, "1.json").writeText("{broken")
        assertEquals(ProverbSnapshot.Unavailable, repo.observe(1).first()); assertEquals(1, errors.size)
        for (json in listOf("""{"version":2,"templateId":"t-proverb","selection":"all"}""",
            """{"version":1,"templateId":"paid","selection":"all"}""",
            """{"version":1,"templateId":"t-proverb","selection":"bad"}""")) {
            try { WidgetInstanceStore.decode(json); fail("Invalid config accepted") } catch (_: IllegalArgumentException) { }
            catch (_: NoSuchElementException) { }
        }
        try { repo.configure(-1, ProverbSelection.ALL); fail("Invalid ID accepted") } catch (_: IllegalArgumentException) { }
    }
    @Test fun libraryRemovalGatesRenderingAndReinstallationRestoresIt() = runBlocking {
        val repo = repo(WidgetInstanceStore(temp.newFolder())); repo.configure(1, ProverbSelection.ALL)
        library.remove("t-proverb")
        assertEquals(ProverbSnapshot.LibraryMissing, repo.observe(1).first())
        repo.configure(1, ProverbSelection.IDIOMS)
        assertTrue(repo.observe(1).first() is ProverbSnapshot.Ready)
    }
    @Test fun refreshAdvancesClockSlotAndReconfigurationUpdatesActiveObserver() = runBlocking {
        var now = Instant.EPOCH
        val clock = object : Clock() {
            override fun getZone() = ZoneOffset.UTC
            override fun withZone(zone: ZoneId) = this
            override fun instant() = now
        }
        val repo = repo(WidgetInstanceStore(temp.newFolder()), clock); repo.configure(1, ProverbSelection.ALL)
        val values = kotlinx.coroutines.channels.Channel<ProverbSnapshot>(10)
        val job = launch { repo.observe(1).collect { values.send(it) } }
        assertEquals(1, (withTimeout(5000) { values.receive() } as ProverbSnapshot.Ready).proverb.id)
        now = Instant.ofEpochSecond(14400); repo.invalidate()
        assertEquals(2, (withTimeout(5000) { values.receive() } as ProverbSnapshot.Ready).proverb.id)
        repo.configure(1, ProverbSelection.IDIOMS)
        assertFalse((withTimeout(5000) { values.receive() } as ProverbSnapshot.Ready).proverb.isProverb)
        job.cancelAndJoin()
    }
    @Test fun sourceDatasetAndRotationMatchPinnedIOS() {
        val source = ProverbSource()
        assertEquals(400, source.entries.size); assertEquals(400, source.entries.map { it.id }.toSet().size)
        assertEquals("Ağaç yaşken eğilir.", source.entry(Instant.EPOCH, ProverbSelection.ALL).title)
        assertEquals(1, source.entry(Instant.ofEpochSecond(14399), ProverbSelection.ALL).id)
        assertEquals(2, source.entry(Instant.ofEpochSecond(14400), ProverbSelection.ALL).id)
        assertEquals(1, source.entry(Instant.ofEpochSecond(14400L * 400), ProverbSelection.ALL).id)
        assertEquals(source.entries.last(), source.entry(Instant.ofEpochSecond(-14400), ProverbSelection.ALL))
        assertTrue(source.entries.all { it.meaning.isNotBlank() && it.example.isNotBlank() })
    }
    @Test fun refreshDecoratorOnlyNotifiesRelevantCommittedWritesAndPreservesSuccess() = runBlocking {
        var count = 0
        val decorated = WidgetRefreshingLibraryRepository(library, { count++; error("refresh failed") }, reporter)
        decorated.install(template, WidgetSize.SMALL); assertEquals(0, count)
        decorated.install(template.copy(id = "t-proverb"), WidgetSize.SMALL)
        assertNotNull(library.widget("t-proverb")); assertEquals(1, count); assertEquals(1, errors.size)
        decorated.remove("t-proverb"); assertNull(library.widget("t-proverb")); assertEquals(2, count)
        library.mutation = { error("write failed") }
        try { decorated.install(template.copy(id = "t-proverb"), WidgetSize.SMALL) } catch (_: IllegalStateException) { }
        assertEquals(2, count)
    }
}
