package com.example.kare.core.database

import androidx.room.EntityInsertAdapter
import androidx.room.RoomDatabase
import androidx.room.coroutines.createFlow
import androidx.room.util.getColumnIndexOrThrow
import androidx.room.util.getTotalChangedRows
import androidx.room.util.performSuspending
import androidx.sqlite.SQLiteStatement
import javax.`annotation`.processing.Generated
import kotlin.Boolean
import kotlin.Int
import kotlin.Long
import kotlin.String
import kotlin.Suppress
import kotlin.Unit
import kotlin.collections.List
import kotlin.collections.MutableList
import kotlin.collections.mutableListOf
import kotlin.reflect.KClass
import kotlinx.coroutines.flow.Flow

@Generated(value = ["androidx.room.RoomProcessor"])
@Suppress(names = ["UNCHECKED_CAST", "DEPRECATION", "REDUNDANT_PROJECTION", "REMOVAL"])
internal class LibraryDao_Impl(
  __db: RoomDatabase,
) : LibraryDao {
  private val __db: RoomDatabase

  private val __insertAdapterOfInstalledWidgetEntity: EntityInsertAdapter<InstalledWidgetEntity>
  init {
    this.__db = __db
    this.__insertAdapterOfInstalledWidgetEntity = object : EntityInsertAdapter<InstalledWidgetEntity>() {
      protected override fun createQuery(): String = "INSERT OR ABORT INTO `installed_widgets` (`templateId`,`name`,`authorName`,`categoryRaw`,`sizeRaw`,`themeJson`,`contentJson`,`payloadVersion`,`addedAtSeconds`,`addedAtNanos`,`isFavorite`,`sortIndex`,`isCustomizable`,`previewImageName`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)"

      protected override fun bind(statement: SQLiteStatement, entity: InstalledWidgetEntity) {
        statement.bindText(1, entity.templateId)
        statement.bindText(2, entity.name)
        statement.bindText(3, entity.authorName)
        statement.bindText(4, entity.categoryRaw)
        statement.bindText(5, entity.sizeRaw)
        val _tmpThemeJson: String? = entity.themeJson
        if (_tmpThemeJson == null) {
          statement.bindNull(6)
        } else {
          statement.bindText(6, _tmpThemeJson)
        }
        val _tmpContentJson: String? = entity.contentJson
        if (_tmpContentJson == null) {
          statement.bindNull(7)
        } else {
          statement.bindText(7, _tmpContentJson)
        }
        statement.bindLong(8, entity.payloadVersion.toLong())
        statement.bindLong(9, entity.addedAtSeconds)
        statement.bindLong(10, entity.addedAtNanos.toLong())
        val _tmp: Int = if (entity.isFavorite) 1 else 0
        statement.bindLong(11, _tmp.toLong())
        statement.bindLong(12, entity.sortIndex.toLong())
        val _tmp_1: Int = if (entity.isCustomizable) 1 else 0
        statement.bindLong(13, _tmp_1.toLong())
        val _tmpPreviewImageName: String? = entity.previewImageName
        if (_tmpPreviewImageName == null) {
          statement.bindNull(14)
        } else {
          statement.bindText(14, _tmpPreviewImageName)
        }
      }
    }
  }

  public override suspend fun insert(widget: InstalledWidgetEntity): Unit = performSuspending(__db, false, true) { _connection ->
    __insertAdapterOfInstalledWidgetEntity.insert(_connection, widget)
  }

  public override fun observeAll(): Flow<List<InstalledWidgetEntity>> {
    val _sql: String = "SELECT * FROM installed_widgets ORDER BY sortIndex, templateId"
    return createFlow(__db, false, arrayOf("installed_widgets")) { _connection ->
      val _stmt: SQLiteStatement = _connection.prepare(_sql)
      try {
        val _columnIndexOfTemplateId: Int = getColumnIndexOrThrow(_stmt, "templateId")
        val _columnIndexOfName: Int = getColumnIndexOrThrow(_stmt, "name")
        val _columnIndexOfAuthorName: Int = getColumnIndexOrThrow(_stmt, "authorName")
        val _columnIndexOfCategoryRaw: Int = getColumnIndexOrThrow(_stmt, "categoryRaw")
        val _columnIndexOfSizeRaw: Int = getColumnIndexOrThrow(_stmt, "sizeRaw")
        val _columnIndexOfThemeJson: Int = getColumnIndexOrThrow(_stmt, "themeJson")
        val _columnIndexOfContentJson: Int = getColumnIndexOrThrow(_stmt, "contentJson")
        val _columnIndexOfPayloadVersion: Int = getColumnIndexOrThrow(_stmt, "payloadVersion")
        val _columnIndexOfAddedAtSeconds: Int = getColumnIndexOrThrow(_stmt, "addedAtSeconds")
        val _columnIndexOfAddedAtNanos: Int = getColumnIndexOrThrow(_stmt, "addedAtNanos")
        val _columnIndexOfIsFavorite: Int = getColumnIndexOrThrow(_stmt, "isFavorite")
        val _columnIndexOfSortIndex: Int = getColumnIndexOrThrow(_stmt, "sortIndex")
        val _columnIndexOfIsCustomizable: Int = getColumnIndexOrThrow(_stmt, "isCustomizable")
        val _columnIndexOfPreviewImageName: Int = getColumnIndexOrThrow(_stmt, "previewImageName")
        val _result: MutableList<InstalledWidgetEntity> = mutableListOf()
        while (_stmt.step()) {
          val _item: InstalledWidgetEntity
          val _tmpTemplateId: String
          _tmpTemplateId = _stmt.getText(_columnIndexOfTemplateId)
          val _tmpName: String
          _tmpName = _stmt.getText(_columnIndexOfName)
          val _tmpAuthorName: String
          _tmpAuthorName = _stmt.getText(_columnIndexOfAuthorName)
          val _tmpCategoryRaw: String
          _tmpCategoryRaw = _stmt.getText(_columnIndexOfCategoryRaw)
          val _tmpSizeRaw: String
          _tmpSizeRaw = _stmt.getText(_columnIndexOfSizeRaw)
          val _tmpThemeJson: String?
          if (_stmt.isNull(_columnIndexOfThemeJson)) {
            _tmpThemeJson = null
          } else {
            _tmpThemeJson = _stmt.getText(_columnIndexOfThemeJson)
          }
          val _tmpContentJson: String?
          if (_stmt.isNull(_columnIndexOfContentJson)) {
            _tmpContentJson = null
          } else {
            _tmpContentJson = _stmt.getText(_columnIndexOfContentJson)
          }
          val _tmpPayloadVersion: Int
          _tmpPayloadVersion = _stmt.getLong(_columnIndexOfPayloadVersion).toInt()
          val _tmpAddedAtSeconds: Long
          _tmpAddedAtSeconds = _stmt.getLong(_columnIndexOfAddedAtSeconds)
          val _tmpAddedAtNanos: Int
          _tmpAddedAtNanos = _stmt.getLong(_columnIndexOfAddedAtNanos).toInt()
          val _tmpIsFavorite: Boolean
          val _tmp: Int
          _tmp = _stmt.getLong(_columnIndexOfIsFavorite).toInt()
          _tmpIsFavorite = _tmp != 0
          val _tmpSortIndex: Int
          _tmpSortIndex = _stmt.getLong(_columnIndexOfSortIndex).toInt()
          val _tmpIsCustomizable: Boolean
          val _tmp_1: Int
          _tmp_1 = _stmt.getLong(_columnIndexOfIsCustomizable).toInt()
          _tmpIsCustomizable = _tmp_1 != 0
          val _tmpPreviewImageName: String?
          if (_stmt.isNull(_columnIndexOfPreviewImageName)) {
            _tmpPreviewImageName = null
          } else {
            _tmpPreviewImageName = _stmt.getText(_columnIndexOfPreviewImageName)
          }
          _item = InstalledWidgetEntity(_tmpTemplateId,_tmpName,_tmpAuthorName,_tmpCategoryRaw,_tmpSizeRaw,_tmpThemeJson,_tmpContentJson,_tmpPayloadVersion,_tmpAddedAtSeconds,_tmpAddedAtNanos,_tmpIsFavorite,_tmpSortIndex,_tmpIsCustomizable,_tmpPreviewImageName)
          _result.add(_item)
        }
        _result
      } finally {
        _stmt.close()
      }
    }
  }

  public override suspend fun all(): List<InstalledWidgetEntity> {
    val _sql: String = "SELECT * FROM installed_widgets ORDER BY sortIndex, templateId"
    return performSuspending(__db, true, false) { _connection ->
      val _stmt: SQLiteStatement = _connection.prepare(_sql)
      try {
        val _columnIndexOfTemplateId: Int = getColumnIndexOrThrow(_stmt, "templateId")
        val _columnIndexOfName: Int = getColumnIndexOrThrow(_stmt, "name")
        val _columnIndexOfAuthorName: Int = getColumnIndexOrThrow(_stmt, "authorName")
        val _columnIndexOfCategoryRaw: Int = getColumnIndexOrThrow(_stmt, "categoryRaw")
        val _columnIndexOfSizeRaw: Int = getColumnIndexOrThrow(_stmt, "sizeRaw")
        val _columnIndexOfThemeJson: Int = getColumnIndexOrThrow(_stmt, "themeJson")
        val _columnIndexOfContentJson: Int = getColumnIndexOrThrow(_stmt, "contentJson")
        val _columnIndexOfPayloadVersion: Int = getColumnIndexOrThrow(_stmt, "payloadVersion")
        val _columnIndexOfAddedAtSeconds: Int = getColumnIndexOrThrow(_stmt, "addedAtSeconds")
        val _columnIndexOfAddedAtNanos: Int = getColumnIndexOrThrow(_stmt, "addedAtNanos")
        val _columnIndexOfIsFavorite: Int = getColumnIndexOrThrow(_stmt, "isFavorite")
        val _columnIndexOfSortIndex: Int = getColumnIndexOrThrow(_stmt, "sortIndex")
        val _columnIndexOfIsCustomizable: Int = getColumnIndexOrThrow(_stmt, "isCustomizable")
        val _columnIndexOfPreviewImageName: Int = getColumnIndexOrThrow(_stmt, "previewImageName")
        val _result: MutableList<InstalledWidgetEntity> = mutableListOf()
        while (_stmt.step()) {
          val _item: InstalledWidgetEntity
          val _tmpTemplateId: String
          _tmpTemplateId = _stmt.getText(_columnIndexOfTemplateId)
          val _tmpName: String
          _tmpName = _stmt.getText(_columnIndexOfName)
          val _tmpAuthorName: String
          _tmpAuthorName = _stmt.getText(_columnIndexOfAuthorName)
          val _tmpCategoryRaw: String
          _tmpCategoryRaw = _stmt.getText(_columnIndexOfCategoryRaw)
          val _tmpSizeRaw: String
          _tmpSizeRaw = _stmt.getText(_columnIndexOfSizeRaw)
          val _tmpThemeJson: String?
          if (_stmt.isNull(_columnIndexOfThemeJson)) {
            _tmpThemeJson = null
          } else {
            _tmpThemeJson = _stmt.getText(_columnIndexOfThemeJson)
          }
          val _tmpContentJson: String?
          if (_stmt.isNull(_columnIndexOfContentJson)) {
            _tmpContentJson = null
          } else {
            _tmpContentJson = _stmt.getText(_columnIndexOfContentJson)
          }
          val _tmpPayloadVersion: Int
          _tmpPayloadVersion = _stmt.getLong(_columnIndexOfPayloadVersion).toInt()
          val _tmpAddedAtSeconds: Long
          _tmpAddedAtSeconds = _stmt.getLong(_columnIndexOfAddedAtSeconds)
          val _tmpAddedAtNanos: Int
          _tmpAddedAtNanos = _stmt.getLong(_columnIndexOfAddedAtNanos).toInt()
          val _tmpIsFavorite: Boolean
          val _tmp: Int
          _tmp = _stmt.getLong(_columnIndexOfIsFavorite).toInt()
          _tmpIsFavorite = _tmp != 0
          val _tmpSortIndex: Int
          _tmpSortIndex = _stmt.getLong(_columnIndexOfSortIndex).toInt()
          val _tmpIsCustomizable: Boolean
          val _tmp_1: Int
          _tmp_1 = _stmt.getLong(_columnIndexOfIsCustomizable).toInt()
          _tmpIsCustomizable = _tmp_1 != 0
          val _tmpPreviewImageName: String?
          if (_stmt.isNull(_columnIndexOfPreviewImageName)) {
            _tmpPreviewImageName = null
          } else {
            _tmpPreviewImageName = _stmt.getText(_columnIndexOfPreviewImageName)
          }
          _item = InstalledWidgetEntity(_tmpTemplateId,_tmpName,_tmpAuthorName,_tmpCategoryRaw,_tmpSizeRaw,_tmpThemeJson,_tmpContentJson,_tmpPayloadVersion,_tmpAddedAtSeconds,_tmpAddedAtNanos,_tmpIsFavorite,_tmpSortIndex,_tmpIsCustomizable,_tmpPreviewImageName)
          _result.add(_item)
        }
        _result
      } finally {
        _stmt.close()
      }
    }
  }

  public override suspend fun find(id: String): InstalledWidgetEntity? {
    val _sql: String = "SELECT * FROM installed_widgets WHERE templateId = ?"
    return performSuspending(__db, true, false) { _connection ->
      val _stmt: SQLiteStatement = _connection.prepare(_sql)
      try {
        var _argIndex: Int = 1
        _stmt.bindText(_argIndex, id)
        val _columnIndexOfTemplateId: Int = getColumnIndexOrThrow(_stmt, "templateId")
        val _columnIndexOfName: Int = getColumnIndexOrThrow(_stmt, "name")
        val _columnIndexOfAuthorName: Int = getColumnIndexOrThrow(_stmt, "authorName")
        val _columnIndexOfCategoryRaw: Int = getColumnIndexOrThrow(_stmt, "categoryRaw")
        val _columnIndexOfSizeRaw: Int = getColumnIndexOrThrow(_stmt, "sizeRaw")
        val _columnIndexOfThemeJson: Int = getColumnIndexOrThrow(_stmt, "themeJson")
        val _columnIndexOfContentJson: Int = getColumnIndexOrThrow(_stmt, "contentJson")
        val _columnIndexOfPayloadVersion: Int = getColumnIndexOrThrow(_stmt, "payloadVersion")
        val _columnIndexOfAddedAtSeconds: Int = getColumnIndexOrThrow(_stmt, "addedAtSeconds")
        val _columnIndexOfAddedAtNanos: Int = getColumnIndexOrThrow(_stmt, "addedAtNanos")
        val _columnIndexOfIsFavorite: Int = getColumnIndexOrThrow(_stmt, "isFavorite")
        val _columnIndexOfSortIndex: Int = getColumnIndexOrThrow(_stmt, "sortIndex")
        val _columnIndexOfIsCustomizable: Int = getColumnIndexOrThrow(_stmt, "isCustomizable")
        val _columnIndexOfPreviewImageName: Int = getColumnIndexOrThrow(_stmt, "previewImageName")
        val _result: InstalledWidgetEntity?
        if (_stmt.step()) {
          val _tmpTemplateId: String
          _tmpTemplateId = _stmt.getText(_columnIndexOfTemplateId)
          val _tmpName: String
          _tmpName = _stmt.getText(_columnIndexOfName)
          val _tmpAuthorName: String
          _tmpAuthorName = _stmt.getText(_columnIndexOfAuthorName)
          val _tmpCategoryRaw: String
          _tmpCategoryRaw = _stmt.getText(_columnIndexOfCategoryRaw)
          val _tmpSizeRaw: String
          _tmpSizeRaw = _stmt.getText(_columnIndexOfSizeRaw)
          val _tmpThemeJson: String?
          if (_stmt.isNull(_columnIndexOfThemeJson)) {
            _tmpThemeJson = null
          } else {
            _tmpThemeJson = _stmt.getText(_columnIndexOfThemeJson)
          }
          val _tmpContentJson: String?
          if (_stmt.isNull(_columnIndexOfContentJson)) {
            _tmpContentJson = null
          } else {
            _tmpContentJson = _stmt.getText(_columnIndexOfContentJson)
          }
          val _tmpPayloadVersion: Int
          _tmpPayloadVersion = _stmt.getLong(_columnIndexOfPayloadVersion).toInt()
          val _tmpAddedAtSeconds: Long
          _tmpAddedAtSeconds = _stmt.getLong(_columnIndexOfAddedAtSeconds)
          val _tmpAddedAtNanos: Int
          _tmpAddedAtNanos = _stmt.getLong(_columnIndexOfAddedAtNanos).toInt()
          val _tmpIsFavorite: Boolean
          val _tmp: Int
          _tmp = _stmt.getLong(_columnIndexOfIsFavorite).toInt()
          _tmpIsFavorite = _tmp != 0
          val _tmpSortIndex: Int
          _tmpSortIndex = _stmt.getLong(_columnIndexOfSortIndex).toInt()
          val _tmpIsCustomizable: Boolean
          val _tmp_1: Int
          _tmp_1 = _stmt.getLong(_columnIndexOfIsCustomizable).toInt()
          _tmpIsCustomizable = _tmp_1 != 0
          val _tmpPreviewImageName: String?
          if (_stmt.isNull(_columnIndexOfPreviewImageName)) {
            _tmpPreviewImageName = null
          } else {
            _tmpPreviewImageName = _stmt.getText(_columnIndexOfPreviewImageName)
          }
          _result = InstalledWidgetEntity(_tmpTemplateId,_tmpName,_tmpAuthorName,_tmpCategoryRaw,_tmpSizeRaw,_tmpThemeJson,_tmpContentJson,_tmpPayloadVersion,_tmpAddedAtSeconds,_tmpAddedAtNanos,_tmpIsFavorite,_tmpSortIndex,_tmpIsCustomizable,_tmpPreviewImageName)
        } else {
          _result = null
        }
        _result
      } finally {
        _stmt.close()
      }
    }
  }

  public override suspend fun delete(id: String) {
    val _sql: String = "DELETE FROM installed_widgets WHERE templateId = ?"
    return performSuspending(__db, false, true) { _connection ->
      val _stmt: SQLiteStatement = _connection.prepare(_sql)
      try {
        var _argIndex: Int = 1
        _stmt.bindText(_argIndex, id)
        _stmt.step()
      } finally {
        _stmt.close()
      }
    }
  }

  public override suspend fun favorite(id: String, favorite: Boolean): Int {
    val _sql: String = "UPDATE installed_widgets SET isFavorite = ? WHERE templateId = ?"
    return performSuspending(__db, false, true) { _connection ->
      val _stmt: SQLiteStatement = _connection.prepare(_sql)
      try {
        var _argIndex: Int = 1
        val _tmp: Int = if (favorite) 1 else 0
        _stmt.bindLong(_argIndex, _tmp.toLong())
        _argIndex = 2
        _stmt.bindText(_argIndex, id)
        _stmt.step()
        getTotalChangedRows(_connection)
      } finally {
        _stmt.close()
      }
    }
  }

  public override suspend fun content(id: String, content: String) {
    val _sql: String = "UPDATE installed_widgets SET contentJson = ? WHERE templateId = ?"
    return performSuspending(__db, false, true) { _connection ->
      val _stmt: SQLiteStatement = _connection.prepare(_sql)
      try {
        var _argIndex: Int = 1
        _stmt.bindText(_argIndex, content)
        _argIndex = 2
        _stmt.bindText(_argIndex, id)
        _stmt.step()
      } finally {
        _stmt.close()
      }
    }
  }

  public override suspend fun position(id: String, position: Int) {
    val _sql: String = "UPDATE installed_widgets SET sortIndex = ? WHERE templateId = ?"
    return performSuspending(__db, false, true) { _connection ->
      val _stmt: SQLiteStatement = _connection.prepare(_sql)
      try {
        var _argIndex: Int = 1
        _stmt.bindLong(_argIndex, position.toLong())
        _argIndex = 2
        _stmt.bindText(_argIndex, id)
        _stmt.step()
      } finally {
        _stmt.close()
      }
    }
  }

  public companion object {
    public fun getRequiredConverters(): List<KClass<*>> = emptyList()
  }
}
