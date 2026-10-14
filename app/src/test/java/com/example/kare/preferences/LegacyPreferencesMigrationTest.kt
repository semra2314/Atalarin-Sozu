package com.example.kare.preferences

import android.content.Context
import androidx.datastore.preferences.core.*
import com.example.kare.core.preferences.LegacyPreferencesMigration
import kotlinx.coroutines.test.runTest
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class LegacyPreferencesMigrationTest {
    @Test fun importsLegacyChoicesAndCleansOnlyLegacyKeys() = runTest {
        val context = RuntimeEnvironment.getApplication()
        val old = context.getSharedPreferences("kare_user_preferences", Context.MODE_PRIVATE)
        old.edit().clear().putString("pref_language", "tr").putString("pref_theme", "DARK").putString("unrelated", "keep").commit()
        val migration = LegacyPreferencesMigration(context)
        assertTrue(migration.shouldMigrate(emptyPreferences()))
        val result = migration.migrate(emptyPreferences())
        assertEquals("TURKISH", result[stringPreferencesKey("language")])
        assertEquals("DARK", result[stringPreferencesKey("appearance")])
        assertNull(result[booleanPreferencesKey("onboarding_completed")])
        migration.cleanUp()
        assertFalse(migration.shouldMigrate(result))
        assertEquals("keep", old.getString("unrelated", null))
    }
    @Test fun existingDataStorePreferencesAlwaysWin() = runTest {
        val context = RuntimeEnvironment.getApplication()
        context.getSharedPreferences("kare_user_preferences", Context.MODE_PRIVATE).edit()
            .clear().putString("pref_language", "tr").putString("pref_theme", "DARK").commit()
        val existing = preferencesOf(stringPreferencesKey("language") to "ENGLISH",
            stringPreferencesKey("appearance") to "LIGHT", booleanPreferencesKey("onboarding_completed") to true,
            booleanPreferencesKey("notifications_enabled") to false)
        assertEquals(existing, LegacyPreferencesMigration(context).migrate(existing))
    }
}
