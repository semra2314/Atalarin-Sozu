package com.example.kare

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.espresso.Espresso.pressBack
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.example.kare.core.model.*
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class Phase13PreferencesTest {
    @get:Rule(order = 0) val onboarding = CompletedOnboardingRule()
    @get:Rule(order = 1) val compose = createAndroidComposeRule<MainActivity>()

    @Test fun preferencesPersistAcrossActivityRecreationAndExistingRoutesRemainReachable() {
        val app = InstrumentationRegistry.getInstrumentation().targetContext.applicationContext as KareApplication
        val preferences = app.container.preferences
        val before = runBlocking { preferences.preferences.first() }
        val widgetDirectory = java.io.File(app.noBackupFilesDir, "widget-instances")
        val widgetBytes = widgetDirectory.walkTopDown().filter { it.isFile }.associate { it.relativeTo(widgetDirectory).path to it.readBytes().toList() }
        try {
            compose.waitUntil(10_000) { compose.onAllNodesWithTag("nav-${R.string.settings_title}").fetchSemanticsNodes().isNotEmpty() }
            compose.onNodeWithTag("nav-${R.string.settings_title}").performClick()
            compose.onNodeWithTag("appearance-DARK").performScrollTo().performClick()
            compose.onNodeWithTag("language-TURKISH").performScrollTo().performClick()
            compose.waitUntil(10_000) { compose.onAllNodesWithText("Türkçe").fetchSemanticsNodes().isNotEmpty() }
            compose.onNodeWithTag("language-TURKISH").performScrollTo().assertIsSelected()
            compose.activityRule.scenario.recreate()
            compose.onNodeWithTag("language-TURKISH").performScrollTo().assertIsSelected()
            compose.onNodeWithTag("appearance-DARK").performScrollTo().assertIsSelected()
            assertEquals(AppLanguage.TURKISH, runBlocking { preferences.preferences.first() }.language)
            assertEquals(AppAppearance.DARK, runBlocking { preferences.preferences.first() }.appearance)
            compose.onNodeWithTag("language-ENGLISH").performScrollTo().performClick()
            compose.waitUntil(10_000) {
                compose.onAllNodesWithTag("settings-sign-in").fetchSemanticsNodes().isNotEmpty() &&
                    androidx.appcompat.app.AppCompatDelegate.getApplicationLocales().toLanguageTags() == "en"
            }
            compose.onNodeWithTag("settings-sign-in").performScrollTo().performClick()
            compose.onNodeWithTag("sign-in-screen").assertExists()
            pressBack()
            compose.onNodeWithTag("nav-${R.string.search_title}").performClick()
            compose.onNodeWithTag("search-query").assertExists()
            compose.onNodeWithTag("nav-${R.string.library_title}").performClick()
            compose.onNodeWithTag("nav-${R.string.library_title}").assertIsSelected()
            val afterBytes = widgetDirectory.walkTopDown().filter { it.isFile }.associate { it.relativeTo(widgetDirectory).path to it.readBytes().toList() }
            assertEquals(widgetBytes, afterBytes)
        } finally {
            runBlocking {
                preferences.setLanguage(before.language)
                preferences.setAppearance(before.appearance)
            }
        }
    }
}
