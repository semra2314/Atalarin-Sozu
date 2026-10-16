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
