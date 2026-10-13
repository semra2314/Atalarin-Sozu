package com.example.kare.core.database

import androidx.room.InvalidationTracker
import androidx.room.RoomOpenDelegate
import androidx.room.migration.AutoMigrationSpec
import androidx.room.migration.Migration
import androidx.room.util.TableInfo
import androidx.room.util.TableInfo.Companion.read
import androidx.room.util.dropFtsSyncTriggers
import androidx.sqlite.SQLiteConnection
import androidx.sqlite.execSQL
import javax.`annotation`.processing.Generated
import kotlin.Lazy
import kotlin.String
import kotlin.Suppress
import kotlin.collections.List
import kotlin.collections.Map
import kotlin.collections.MutableList
import kotlin.collections.MutableMap
import kotlin.collections.MutableSet
import kotlin.collections.Set
import kotlin.collections.mutableListOf
import kotlin.collections.mutableMapOf
import kotlin.collections.mutableSetOf
import kotlin.reflect.KClass

@Generated(value = ["androidx.room.RoomProcessor"])
@Suppress(names = ["UNCHECKED_CAST", "DEPRECATION", "REDUNDANT_PROJECTION", "REMOVAL"])
public class KareDatabase_Impl : KareDatabase() {
  private val _libraryDao: Lazy<LibraryDao> = lazy {
    LibraryDao_Impl(this)
  }

  protected override fun createOpenDelegate(): RoomOpenDelegate {
    val _openDelegate: RoomOpenDelegate = object : RoomOpenDelegate(1, "4b96327a736322b887c9b0ffc468b1e9", "9af0d532bc2219b6e9e768784a5baf53") {
      public override fun createAllTables(connection: SQLiteConnection) {
        connection.execSQL("CREATE TABLE IF NOT EXISTS `installed_widgets` (`templateId` TEXT NOT NULL, `name` TEXT NOT NULL, `authorName` TEXT NOT NULL, `categoryRaw` TEXT NOT NULL, `sizeRaw` TEXT NOT NULL, `themeJson` TEXT, `contentJson` TEXT, `payloadVersion` INTEGER NOT NULL, `addedAtSeconds` INTEGER NOT NULL, `addedAtNanos` INTEGER NOT NULL, `isFavorite` INTEGER NOT NULL, `sortIndex` INTEGER NOT NULL, `isCustomizable` INTEGER NOT NULL, `previewImageName` TEXT, PRIMARY KEY(`templateId`))")
        connection.execSQL("CREATE TABLE IF NOT EXISTS room_master_table (id INTEGER PRIMARY KEY,identity_hash TEXT)")
        connection.execSQL("INSERT OR REPLACE INTO room_master_table (id,identity_hash) VALUES(42, '4b96327a736322b887c9b0ffc468b1e9')")
      }

      public override fun dropAllTables(connection: SQLiteConnection) {
        connection.execSQL("DROP TABLE IF EXISTS `installed_widgets`")
      }

      public override fun onCreate(connection: SQLiteConnection) {
      }

      public override fun onOpen(connection: SQLiteConnection) {
        internalInitInvalidationTracker(connection)
      }

      public override fun onPreMigrate(connection: SQLiteConnection) {
        dropFtsSyncTriggers(connection)
      }

      public override fun onPostMigrate(connection: SQLiteConnection) {
      }

      public override fun onValidateSchema(connection: SQLiteConnection): RoomOpenDelegate.ValidationResult {
        val _columnsInstalledWidgets: MutableMap<String, TableInfo.Column> = mutableMapOf()
        _columnsInstalledWidgets.put("templateId", TableInfo.Column("templateId", "TEXT", true, 1, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("name", TableInfo.Column("name", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("authorName", TableInfo.Column("authorName", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("categoryRaw", TableInfo.Column("categoryRaw", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("sizeRaw", TableInfo.Column("sizeRaw", "TEXT", true, 0, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("themeJson", TableInfo.Column("themeJson", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("contentJson", TableInfo.Column("contentJson", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("payloadVersion", TableInfo.Column("payloadVersion", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("addedAtSeconds", TableInfo.Column("addedAtSeconds", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("addedAtNanos", TableInfo.Column("addedAtNanos", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("isFavorite", TableInfo.Column("isFavorite", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("sortIndex", TableInfo.Column("sortIndex", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("isCustomizable", TableInfo.Column("isCustomizable", "INTEGER", true, 0, null, TableInfo.CREATED_FROM_ENTITY))
        _columnsInstalledWidgets.put("previewImageName", TableInfo.Column("previewImageName", "TEXT", false, 0, null, TableInfo.CREATED_FROM_ENTITY))
        val _foreignKeysInstalledWidgets: MutableSet<TableInfo.ForeignKey> = mutableSetOf()
        val _indicesInstalledWidgets: MutableSet<TableInfo.Index> = mutableSetOf()
        val _infoInstalledWidgets: TableInfo = TableInfo("installed_widgets", _columnsInstalledWidgets, _foreignKeysInstalledWidgets, _indicesInstalledWidgets)
        val _existingInstalledWidgets: TableInfo = read(connection, "installed_widgets")
        if (!_infoInstalledWidgets.equals(_existingInstalledWidgets)) {
          return RoomOpenDelegate.ValidationResult(false, """
              |installed_widgets(com.example.kare.core.database.InstalledWidgetEntity).
              | Expected:
              |""".trimMargin() + _infoInstalledWidgets + """
              |
              | Found:
              |""".trimMargin() + _existingInstalledWidgets)
        }
        return RoomOpenDelegate.ValidationResult(true, null)
      }
    }
    return _openDelegate
  }

  protected override fun createInvalidationTracker(): InvalidationTracker {
    val _shadowTablesMap: MutableMap<String, String> = mutableMapOf()
    val _viewTables: MutableMap<String, Set<String>> = mutableMapOf()
    return InvalidationTracker(this, _shadowTablesMap, _viewTables, "installed_widgets")
  }

  public override fun clearAllTables() {
    super.performClear(false, "installed_widgets")
  }

  protected override fun getRequiredTypeConverterClasses(): Map<KClass<*>, List<KClass<*>>> {
    val _typeConvertersMap: MutableMap<KClass<*>, List<KClass<*>>> = mutableMapOf()
    _typeConvertersMap.put(LibraryDao::class, LibraryDao_Impl.getRequiredConverters())
    return _typeConvertersMap
  }

  public override fun getRequiredAutoMigrationSpecClasses(): Set<KClass<out AutoMigrationSpec>> {
    val _autoMigrationSpecsSet: MutableSet<KClass<out AutoMigrationSpec>> = mutableSetOf()
    return _autoMigrationSpecsSet
  }

  public override fun createAutoMigrations(autoMigrationSpecs: Map<KClass<out AutoMigrationSpec>, AutoMigrationSpec>): List<Migration> {
    val _autoMigrations: MutableList<Migration> = mutableListOf()
    return _autoMigrations
  }

  internal override fun libraryDao(): LibraryDao = _libraryDao.value
}
