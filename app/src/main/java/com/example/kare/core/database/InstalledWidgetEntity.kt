package com.example.kare.core.database

import androidx.room.Entity
import androidx.room.PrimaryKey

/** Offline snapshot. Never pass this persistence type to a ViewModel or screen. */
@Entity(tableName = "installed_widgets")
internal data class InstalledWidgetEntity(
    @PrimaryKey val templateId: String,
    val name: String,
    val authorName: String,
    val categoryRaw: String,
    val sizeRaw: String,
    val themeJson: String?,
    val contentJson: String?,
    val payloadVersion: Int,
    val addedAtSeconds: Long,
    val addedAtNanos: Int,
    val isFavorite: Boolean,
    val sortIndex: Int,
    val isCustomizable: Boolean,
    val previewImageName: String?,
)
