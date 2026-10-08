package com.example.kare.core.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(entities = [InstalledWidgetEntity::class], version = 1, exportSchema = true)
abstract class KareDatabase : RoomDatabase() {
    internal abstract fun libraryDao(): LibraryDao

    companion object {
        /** The composition root owns one instance per process and closes it when appropriate. */
        fun open(context: Context): KareDatabase =
            Room.databaseBuilder(context.applicationContext, KareDatabase::class.java, "kare-library.db")
                // No destructive fallback: future schema upgrades must supply explicit migrations.
                .build()
    }
}
