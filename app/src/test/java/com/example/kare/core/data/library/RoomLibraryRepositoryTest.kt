package com.example.kare.core.data.library

import androidx.room.Room
import com.example.kare.core.data.catalog.LocalCatalogDataSource
import com.example.kare.core.database.KareDatabase
import com.example.kare.core.model.*
import com.example.kare.core.repository.RepositoryException
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.first
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.SQLiteMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@SQLiteMode(SQLiteMode.Mode.NATIVE)
class RoomLibraryRepositoryTest {
    private lateinit var db: KareDatabase
    private lateinit var repo: RoomLibraryRepository
    private lateinit var editable: WidgetTemplate
    private lateinit var fixed: WidgetTemplate
    private val now = Instant.parse("2026-10-08T12:34:56.123456789Z")

    @Before fun setup() = runBlocking {
        db = Room.inMemoryDatabaseBuilder(RuntimeEnvironment.getApplication(), KareDatabase::class.java).build()
        repo = repository(db)
        val catalog = LocalCatalogDataSource().load()
        editable = catalog.templates.first { it.id == "p-sunset" }
        fixed = catalog.templates.first { it.id == "t-aurora" }
    }
    @After fun close() { db.close() }
    private fun repository(database: KareDatabase) = RoomLibraryRepository(database, clock = Clock.fixed(now, ZoneOffset.UTC))

    @Test fun installAndRetrieveOfflineSnapshot() = runBlocking {
        assertTrue(repo.observeWidgets().first().isEmpty())
        assertNull(repo.widget(editable.id))
        val installed = repo.install(editable, editable.primarySize)
        assertEquals(editable.id, installed.templateId)
        assertEquals(editable.theme, installed.theme)
        assertEquals(editable.content, installed.content)
        assertEquals(now, installed.addedAt)
        assertTrue(installed.isCustomizable)
        assertNull(installed.previewImageName)
        assertEquals(installed, repo.widget(editable.id))
        assertEquals(listOf(installed), repo.observeWidgets().first())
    }

    @Test fun duplicateInstallPreservesEditsAndFavoriteEvenConcurrently() = runBlocking {
        repo.install(editable, editable.primarySize)
        val content = editable.content!!.copy(text = "My saved design")
        repo.updateContent(editable.id, content)
        repo.setFavorite(editable.id, true)
        val results = (1..8).map { async(Dispatchers.Default) { repo.install(editable, editable.primarySize) } }.awaitAll()
        assertTrue(results.all { it.content == content && it.isFavorite && it.addedAt == now })
        assertEquals(1, repo.observeWidgets().first().size)
    }

    @Test fun concurrentFirstInstallCreatesOneRow() = runBlocking {
        val results = (1..8).map { async(Dispatchers.Default) { repo.install(editable, editable.primarySize) } }.awaitAll()
        assertEquals(1, results.distinct().size)
        assertEquals(1, repo.observeWidgets().first().size)
    }

    @Test fun favoriteDesiredStateCanToggleWithoutRetrySideEffects() = runBlocking {
        repo.install(editable, editable.primarySize)
        repo.setFavorite(editable.id, true)
        repo.setFavorite(editable.id, true)
        assertTrue(repo.widget(editable.id)!!.isFavorite)
        repo.setFavorite(editable.id, false)
        assertFalse(repo.widget(editable.id)!!.isFavorite)
        expect<RepositoryException.NotFound> { repo.setFavorite("missing", true) }
    }

    @Test fun removalReturnsSnapshotAndCompactsOrder() = runBlocking {
        val first = repo.install(editable, editable.primarySize)
        repo.install(fixed, fixed.primarySize)
        assertEquals(first, repo.remove(editable.id))
        assertNull(repo.remove(editable.id))
        assertNull(repo.widget(editable.id))
        assertEquals(0, repo.widget(fixed.id)!!.sortIndex)
        assertEquals(1, repo.install(editable, editable.primarySize).sortIndex)
    }

    @Test fun reorderIsCompleteAtomicAndStable() = runBlocking {
        repo.install(editable, editable.primarySize)
        repo.install(fixed, fixed.primarySize)
        repo.reorder(listOf(fixed.id, editable.id))
        val expected = repo.observeWidgets().first()
        assertEquals(listOf(fixed.id, editable.id), expected.map { it.templateId })
        assertEquals(listOf(0, 1), expected.map { it.sortIndex })
        for (bad in listOf(emptyList(), listOf(fixed.id), listOf(fixed.id, fixed.id), listOf(fixed.id, "unknown"))) {
            expect<RepositoryException.InvalidData> { repo.reorder(bad) }
            assertEquals(expected, repo.observeWidgets().first())
        }
    }

    @Test fun contentUpdatePreservesThemeAndRejectsFixedOrMissingWidgets() = runBlocking {
        val original = repo.install(editable, editable.primarySize)
        repo.install(fixed, fixed.primarySize)
        val content = editable.content!!.copy(background = WidgetContent.Background.Photo(ImageData(byteArrayOf(0, 1, -1))))
        repo.updateContent(editable.id, content)
        assertEquals(original.copy(content = content), repo.widget(editable.id))
        expect<RepositoryException.InvalidData> { repo.updateContent(fixed.id, content) }
        expect<RepositoryException.NotFound> { repo.updateContent("missing", content) }
        assertNull(repo.widget(fixed.id)!!.content)
    }

    @Test fun invalidSizeAndOversizedPayloadLeaveDatabaseUnchanged() = runBlocking {
        expect<RepositoryException.InvalidData> { repo.install(editable, WidgetSize.ACCESSORY_CIRCULAR) }
        repo.install(editable, editable.primarySize)
        val original = repo.widget(editable.id)
        expect<RepositoryException.InvalidData> {
            repo.updateContent(editable.id, editable.content!!.copy(text = "x".repeat(513 * 1024)))
        }
        assertEquals(original, repo.widget(editable.id))
    }

    @Test fun metadataRefreshUsesCatalogButRemovedTemplateUsesCache() = runBlocking {
        val current = repo.install(fixed.copy(author = fixed.author.copy(displayName = "Old"), isEditable = true), fixed.primarySize)
        assertEquals(fixed.author.displayName, current.authorName)
        assertFalse(current.isCustomizable)
        val retired = editable.copy(id = "retired", author = editable.author.copy(displayName = "Archived creator"))
        val saved = repo.install(retired, retired.primarySize)
        assertEquals("Archived creator", saved.authorName)
        assertEquals(retired.content, repo.widget(retired.id)!!.content)
    }

    @Test fun reactiveFlowEmitsCommittedChanges() = runBlocking {
        withTimeout(10_000) {
            val observed = async { repo.observeWidgets().first { it.singleOrNull()?.isFavorite == true } }
            repo.install(editable, editable.primarySize)
            repo.setFavorite(editable.id, true)
            assertTrue(observed.await().single().isFavorite)
        }
    }

    @Test fun malformedStoredJsonFailsInsteadOfSilentlyDroppingContent() = runBlocking {
        repo.install(editable, editable.primarySize)
        db.libraryDao().content(editable.id, "not json")
        expect<RepositoryException.InvalidData> { repo.widget(editable.id) }
        expect<RepositoryException.InvalidData> { repo.observeWidgets().first() }
    }

    @Test fun diskDatabaseSurvivesCloseAndReopen() = runBlocking {
        val context = RuntimeEnvironment.getApplication()
        val name = "library-reopen-test.db"
        context.deleteDatabase(name)
        var disk = Room.databaseBuilder(context, KareDatabase::class.java, name).build()
        try {
            val writer = repository(disk)
            writer.install(editable, editable.primarySize)
            writer.setFavorite(editable.id, true)
            val expected = writer.widget(editable.id)
            disk.close()
            disk = Room.databaseBuilder(context, KareDatabase::class.java, name).build()
            assertEquals(expected, repository(disk).widget(editable.id))
        } finally { disk.close(); context.deleteDatabase(name) }
    }

    @Test fun reorderDatabaseFailureRollsBackEarlierUpdates() = runBlocking {
        repo.install(editable, editable.primarySize)
        repo.install(fixed, fixed.primarySize)
        val before = repo.observeWidgets().first()
        withContext(Dispatchers.IO) {
            db.openHelper.writableDatabase.execSQL(
                "CREATE TRIGGER reject_order BEFORE UPDATE OF sortIndex ON installed_widgets " +
                    "WHEN NEW.sortIndex = 1 BEGIN SELECT RAISE(ABORT, 'test failure'); END",
            )
        }
        expect<RepositoryException.Persistence> { repo.reorder(listOf(fixed.id, editable.id)) }
        assertEquals(before, repo.observeWidgets().first())
    }

    @Test fun cancellationPropagatesWithoutInstalling() = runBlocking {
        val cancelled = Job().apply { cancel() }
        expect<CancellationException> {
            withContext(cancelled) { repo.install(editable, editable.primarySize) }
        }
        assertTrue(repo.observeWidgets().first().isEmpty())
    }

    private suspend inline fun <reified T : Throwable> expect(block: suspend () -> Unit) {
        try { block(); fail("Expected ${T::class.simpleName}") }
        catch (error: Throwable) { if (error !is T) throw error }
    }
}
