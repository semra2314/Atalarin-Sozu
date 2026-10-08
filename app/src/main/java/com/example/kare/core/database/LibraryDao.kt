package com.example.kare.core.database

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
internal interface LibraryDao {
    @Query("SELECT * FROM installed_widgets ORDER BY sortIndex, templateId")
    fun observeAll(): Flow<List<InstalledWidgetEntity>>

    @Query("SELECT * FROM installed_widgets ORDER BY sortIndex, templateId")
    suspend fun all(): List<InstalledWidgetEntity>

    @Query("SELECT * FROM installed_widgets WHERE templateId = :id")
    suspend fun find(id: String): InstalledWidgetEntity?

    @Insert
    suspend fun insert(widget: InstalledWidgetEntity)

    @Query("DELETE FROM installed_widgets WHERE templateId = :id")
    suspend fun delete(id: String)

    @Query("UPDATE installed_widgets SET isFavorite = :favorite WHERE templateId = :id")
    suspend fun favorite(id: String, favorite: Boolean): Int

    @Query("UPDATE installed_widgets SET contentJson = :content WHERE templateId = :id")
    suspend fun content(id: String, content: String)

    @Query("UPDATE installed_widgets SET sortIndex = :position WHERE templateId = :id")
    suspend fun position(id: String, position: Int)
}
