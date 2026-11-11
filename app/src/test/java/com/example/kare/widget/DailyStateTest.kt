package com.example.kare.widget

import com.example.kare.core.data.widget.*
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import com.example.kare.core.repository.WidgetRepository
import com.example.kare.presentation.*
import java.io.File
import java.time.LocalDate
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
class DailyStateTest {
    @get:Rule val temp = TemporaryFolder()
    private val library = LibraryFake()
    private val errors = mutableListOf<Throwable>()
    private val reporter = ErrorReporter { _, e -> errors += e }
    private val catalog = object : WidgetRepository by CatalogFake() {
        override suspend fun template(id: String) = template.copy(id = id)
    }
    private var date = LocalDate.of(2026, 1, 1)
    private fun repo(dir: File) = DailyWidgetRepository(DailyInstanceStore(dir), library, catalog, reporter) { date }

    @Test fun selectionIsStablePerDayAndAdvancesAtMidnight() {
        for (source in DailySource.entries) {
            val first = dailyPassage(date, source)
            assertEquals(first, dailyPassage(date, source))
            assertNotEquals(first, dailyPassage(date.plusDays(1), source))
            assertEquals(source, first.source)
            assertTrue(first.text.isNotBlank() && first.attribution.isNotBlank())
        }
    }
    @Test fun selectionCyclesThroughWholeCorpusAndHandlesPreEpochDates() {
        for (source in DailySource.entries) {
            val seen = (0 until 40).map { dailyPassage(date.plusDays(it.toLong()), source) }.toSet()
            assertEquals(seen.size, seen.map { it.text }.toSet().size)
            assertTrue(seen.size >= 5)
        }
        assertEquals(DailySource.BIBLE, dailyPassage(LocalDate.of(1960, 5, 5), DailySource.BIBLE).source)
    }
    @Test fun instancesKeepIndependentSourcesAndReopen() = runBlocking {
        val dir = temp.newFolder(); val repo = repo(dir)
        repo.configure(1, DailySource.BIBLE); repo.configure(2, DailySource.POETRY)
        val reopened = repo(dir)
        assertEquals(DailySource.BIBLE, reopened.configuration(1)!!.source)
        assertEquals(DailySource.POETRY, reopened.configuration(2)!!.source)
        assertEquals(1, library.rows.value.size)
        assertEquals(DailySource.POETRY, (reopened.observe(2).first() as DailySnapshot.Ready).passage.source)
    }
    @Test fun deletionAndLibraryRemovalAreSeparate() = runBlocking {
        val dir = temp.newFolder(); val repo = repo(dir)
        repo.configure(1, DailySource.BIBLE); repo.configure(2, DailySource.POETRY)
        repo.delete(1); repo.delete(1)
        assertEquals(DailySnapshot.NeedsConfiguration, repo.observe(1).first())
        assertNotNull(repo.configuration(2))
        library.remove("t-daily")
        assertEquals(DailySnapshot.LibraryMissing, repo.observe(2).first())
        repo.configure(2, DailySource.BIBLE)
        assertTrue(repo.observe(2).first() is DailySnapshot.Ready)
    }
    @Test fun corruptForeignAndFutureStateDoNotRenderAsValid() = runBlocking {
        val dir = temp.newFolder(); val repo = repo(dir)
        assertEquals(DailySnapshot.NeedsConfiguration, repo.observe(1).first())
        for (json in listOf("broken", """{"version":2,"templateId":"t-daily","source":"bible"}""",
            HushInstanceStore.encode(HushConfiguration()), """{"version":1,"templateId":"t-daily","source":"invalid"}""")) {
            File(dir, "1.json").writeText(json)
            assertEquals(DailySnapshot.Unavailable, repo.observe(1).first())
            assertEquals(json, File(dir, "1.json").readText())
        }
        try { repo.configure(0, DailySource.BIBLE); fail("Invalid ID") } catch (_: IllegalArgumentException) { }
        assertEquals(4, errors.size)
    }
}
