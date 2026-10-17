package com.example.kare.editor

import androidx.room.Room
import com.example.kare.core.data.catalog.LocalCatalogDataSource
import com.example.kare.core.data.library.RoomLibraryRepository
import com.example.kare.core.database.KareDatabase
import com.example.kare.feature.editor.EditorDraft
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.flow.first
import org.junit.Test
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.SQLiteMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@SQLiteMode(SQLiteMode.Mode.NATIVE)
class EditorPersistenceTest {
    @Test fun corruptSerializedThemeOrContentIsolatedToBoundLibraryItem() = runBlocking {
        val context = RuntimeEnvironment.getApplication()
        val db = Room.inMemoryDatabaseBuilder(context, KareDatabase::class.java).build()
        val directory = java.io.File(context.cacheDir, "recovery-${java.util.UUID.randomUUID()}").apply { mkdirs() }
        try {
            val library = RoomLibraryRepository(db)
            val catalog = LocalCatalogDataSource().load().templates
            for (id in listOf("p-sunset", "p-pastel")) {
                val template = catalog.first { it.id == id }
                library.install(template, template.primarySize)
            }
            val repository = com.example.kare.core.data.widget.EditableWidgetRepository(
                com.example.kare.core.data.widget.EditableBindingStore(directory), library,
                com.example.kare.core.presentation.ErrorReporter { _, _ -> })
            repository.bind(11, "p-sunset"); repository.bind(12, "p-pastel")
            val dao = db.libraryDao()
            val original = dao.find("p-sunset")!!
            for (damaged in listOf(original.copy(themeJson = "broken"), original.copy(contentJson = "broken"))) {
                dao.delete(original.templateId); dao.insert(damaged)
                assertEquals(com.example.kare.core.data.widget.EditableSnapshot.Unavailable, repository.snapshot(11))
                assertTrue(repository.snapshot(12) is com.example.kare.core.data.widget.EditableSnapshot.Ready)
            }
            dao.delete(original.templateId); dao.insert(original)
            assertTrue(repository.snapshot(11) is com.example.kare.core.data.widget.EditableSnapshot.Ready)
        } finally { db.close(); directory.deleteRecursively() }
    }

    @Test fun editedContentSurvivesDatabaseReopeningWithoutMutatingCatalogOrTheme() = runBlocking {
        val context = RuntimeEnvironment.getApplication()
        val name = "editor-${java.util.UUID.randomUUID()}.db"
        fun open() = Room.databaseBuilder(context, KareDatabase::class.java, name).build()
        var db = open()
        try {
            val catalog = LocalCatalogDataSource().load().templates.first { it.id == "p-sunset" }
            val repo = RoomLibraryRepository(db)
            val installed = repo.install(catalog, catalog.primarySize)
            val content = EditorDraft.from(installed).text("Persistent\nwords").background("FFFFFF").content
            repo.updateContent(catalog.id, content)
            assertEquals(content, repo.observeWidgets().first().single().content)
            db.close(); db = open()
            val restored = RoomLibraryRepository(db).widget(catalog.id)!!
            assertEquals(content, restored.content); assertEquals(installed.theme, restored.theme)
            assertNotEquals(content, LocalCatalogDataSource().load().templates.first { it.id == catalog.id }.content)
        } finally { db.close(); context.deleteDatabase(name) }
    }
}
