package com.example.kare.core.data.library

import android.database.sqlite.SQLiteException
import androidx.room.withTransaction
import com.example.kare.core.data.catalog.LocalCatalogDataSource
import com.example.kare.core.data.serialization.frozen
import com.example.kare.core.database.KareDatabase
import com.example.kare.core.database.InstalledWidgetEntity
import com.example.kare.core.model.*
import com.example.kare.core.repository.LibraryRepository
import com.example.kare.core.repository.RepositoryException
import java.io.IOException
import java.time.Clock
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerializationException

/** Room owns transactions; the caller owns coroutine lifetime. No widget mirror or launcher side effects. */
class RoomLibraryRepository(
    private val database: KareDatabase,
    private val catalog: LocalCatalogDataSource = LocalCatalogDataSource(),
    private val clock: Clock = Clock.systemUTC(),
) : LibraryRepository {
    private val dao = database.libraryDao()

    override fun observeWidgets(): Flow<List<InstalledWidget>> = dao.observeAll().map { rows ->
        val templates = catalog.load().templates.associateBy { it.id }
        frozen(rows.map { resolve(it, templates) })
    }.catch { throw mappedError(it) }.flowOn(Dispatchers.IO)

    override suspend fun widget(templateId: String): InstalledWidget? = access {
        val templates = catalog.load().templates.associateBy { it.id }
        dao.find(templateId)?.let { resolve(it, templates) }
    }

    override suspend fun install(template: WidgetTemplate, size: WidgetSize): InstalledWidget = access {
        val templates = catalog.load().templates.associateBy { it.id }
        database.withTransaction {
            dao.find(template.id)?.let { return@withTransaction resolve(it, templates) }
            if (size !in template.supportedSizes) throw RepositoryException.InvalidData("size")
            val last = dao.all().maxOfOrNull { it.sortIndex } ?: -1
            if (last == Int.MAX_VALUE) throw RepositoryException.InvalidData("sortIndex")
            val installed = InstalledWidget(
                template.id, template.name, template.author.displayName, template.category, size,
                template.theme, template.content, clock.instant(), false, last + 1,
                template.isEditable, template.previewImageName,
            )
            val entity = InstalledWidgetMapper.toEntity(installed)
            dao.insert(entity)
            resolve(entity, templates)
        }
    }

    override suspend fun remove(templateId: String): InstalledWidget? = access {
        val templates = catalog.load().templates.associateBy { it.id }
        database.withTransaction {
            val entity = dao.find(templateId) ?: return@withTransaction null
            val snapshot = resolve(entity, templates)
            dao.delete(templateId)
            dao.all().forEachIndexed { index, row -> dao.position(row.templateId, index) }
            snapshot
        }
    }

    override suspend fun setFavorite(templateId: String, isFavorite: Boolean): Unit = access {
        if (dao.favorite(templateId, isFavorite) == 0) throw RepositoryException.NotFound(templateId)
    }

    override suspend fun updateContent(templateId: String, content: WidgetContent): Unit = access {
        val templates = catalog.load().templates.associateBy { it.id }
        database.withTransaction {
            val entity = dao.find(templateId) ?: throw RepositoryException.NotFound(templateId)
            val snapshot = resolve(entity, templates)
            if (!snapshot.isCustomizable) throw RepositoryException.InvalidData("fixed widget content")
            val updated = InstalledWidgetMapper.toEntity(snapshot.copy(content = content))
            dao.content(templateId, checkNotNull(updated.contentJson))
        }
    }

    override suspend fun reorder(templateIds: List<String>): Unit = access {
        // Snapshot the caller-owned collection before entering the transaction.
        val ids = templateIds.toList()
        database.withTransaction {
            val existing = dao.all().map { it.templateId }.toSet()
            if (ids.size != existing.size || ids.toSet() != existing) {
                throw RepositoryException.InvalidData("library order")
            }
            ids.forEachIndexed { index, id -> dao.position(id, index) }
        }
    }

    private fun resolve(entity: InstalledWidgetEntity, templates: Map<String, WidgetTemplate>): InstalledWidget {
        val snapshot = InstalledWidgetMapper.toDomain(entity)
        val current = templates[snapshot.templateId]
        val editable = current?.isEditable ?: snapshot.isCustomizable
        return snapshot.copy(
            authorName = current?.author?.displayName ?: snapshot.authorName,
            isCustomizable = editable,
            previewImageName = if (editable) null else current?.previewImageName ?: snapshot.previewImageName,
        )
    }

    private suspend fun <T> access(block: suspend () -> T): T = withContext(Dispatchers.IO) {
        try { block() } catch (error: Exception) { throw mappedError(error) }
    }

    private fun mappedError(error: Throwable): Throwable = when (error) {
        is SQLiteException, is IOException -> RepositoryException.Persistence(error)
        is SerializationException -> RepositoryException.InvalidData("library JSON").also { it.addSuppressed(error) }
        else -> error // Includes coroutine cancellation and domain errors.
    }
}
