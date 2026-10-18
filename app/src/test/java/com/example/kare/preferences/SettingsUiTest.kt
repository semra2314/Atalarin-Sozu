package com.example.kare.preferences

import android.content.res.Configuration
import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import com.example.kare.R
import com.example.kare.core.design.KareTheme
import com.example.kare.core.model.*
import com.example.kare.feature.settings.*
import com.example.kare.feature.onboarding.OnboardingContent
import com.example.kare.widget.hushText
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory
import java.util.Locale
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.*

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], qualifiers = "en-rUS-w320dp-h480dp")
@LooperMode(LooperMode.Mode.PAUSED)
class SettingsUiTest {
    @get:Rule val compose = createComposeRule()
    @Test fun selectionAccountGuideAndBillingEntryRemainAccessibleAtLargeFont() {
        val prefs = mutableStateOf(AppPreferences(true, AppLanguage.ENGLISH, AppAppearance.DARK))
        var signIn = 0
        var plus = 0
        compose.setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density, 2f)) {
                KareTheme(darkTheme = true) { SettingsContent(PreferencesUiState(StartupState.Loaded(prefs.value)),
                    AuthState.Unauthenticated, false, "1.0 (1)",
                    { prefs.value = prefs.value.copy(language = it) }, { prefs.value = prefs.value.copy(appearance = it) },
                    { signIn++ }, {}, {}, {}, onKarePlus = { plus++ }) }
            }
        }
        compose.onNodeWithTag("appearance-DARK").performScrollTo().assertIsSelected()
        compose.onNodeWithTag("appearance-LIGHT").performScrollTo().performClick().assertIsSelected()
        compose.onNodeWithTag("language-TURKISH").performScrollTo().performClick().assertIsSelected()
        compose.onNodeWithTag("settings-sign-in").performScrollTo().performClick()
        assertEquals(1, signIn)
        compose.onNodeWithTag("settings-kare-plus").performScrollTo().performClick()
        assertEquals(1, plus)
        compose.onNodeWithTag("settings-widget-guide").performScrollTo().performClick()
        compose.onNodeWithText("Install Söz or Hush", substring = true).performScrollTo().assertIsDisplayed()
    }
    @Test fun authenticatedSettingsShowsIdentityAndHonestDeletionLimitWithPersistentToggleCallback() {
        val prefs = mutableStateOf(AppPreferences())
        var signOuts = 0
        compose.setContent { KareTheme { SettingsContent(PreferencesUiState(StartupState.Loaded(prefs.value)),
            AuthState.Authenticated(AuthUser("uid", "ada@example.com", "Ada")), false, "2.0 (8)",
            {}, {}, {}, { signOuts++ }, {}, {},
            onNotifications = { prefs.value = prefs.value.copy(notificationsEnabled = it) },
            identity = UserProfile(displayName = "Ada", username = "ada")) } }
        compose.onNodeWithText("@ada").performScrollTo().assertIsDisplayed()
        compose.onNodeWithText("Account deletion is not available yet.", substring = true)
            .performScrollTo().assertHasNoClickAction()
        assertEquals(0, signOuts)
        compose.onNodeWithTag("settings-notification-preference").performScrollTo().assertIsOn().performClick().assertIsOff()
        assertFalse(prefs.value.notificationsEnabled)
        compose.onNodeWithTag("settings-sign-out").performScrollTo().performClick()
        assertEquals(1, signOuts)
    }
    @Test fun onboardingShowsLanguageSelectionAndCompletesOnlyThroughExplicitAction() {
        var page by mutableIntStateOf(0); var completed = false
        compose.setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density, 2f)) {
                KareTheme { OnboardingContent(page, AppPreferences(), false, null,
                    { page++ }, { page-- }, { completed = true }, {}, {}) }
            }
        }
        compose.onNodeWithTag("language-SYSTEM").performScrollTo().assertIsSelected()
        repeat(3) { compose.onNodeWithTag("onboarding-next").performScrollTo().performClick() }
        assertFalse(completed)
        compose.onNodeWithTag("onboarding-page-3").assertExists()
        compose.onNodeWithTag("onboarding-next").performScrollTo().performClick()
        assertTrue(completed)
    }
    @Test fun newResourcesHaveIdenticalKeysAndFormattingContracts() {
        fun strings(locale: String): Map<String, String> {
            val document = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(File("src/main/res/$locale/preferences_strings.xml"))
            val nodes = document.getElementsByTagName("string")
            return (0 until nodes.length).associate { nodes.item(it).attributes.getNamedItem("name").nodeValue to nodes.item(it).textContent }
        }
        val en = strings("values"); val tr = strings("values-tr")
        assertEquals(en.keys, tr.keys)
        val format = Regex("%[0-9]+\\$[sd]")
        en.forEach { (key, text) ->
            assertTrue(tr.getValue(key).isNotBlank())
            assertEquals(key, format.findAll(text).map { it.value }.sorted().toList(), format.findAll(tr.getValue(key)).map { it.value }.sorted().toList())
        }
    }
    @Test fun explicitHushLanguageIsIndependentOfApplicationLanguage() {
        val app = RuntimeEnvironment.getApplication()
        fun context(tag: String) = app.createConfigurationContext(Configuration(app.resources.configuration).apply { setLocale(Locale.forLanguageTag(tag)) })
        val english = HushEntry(HushPrompt.BREATHE, HushPalette.STILL, HushLanguage.ENGLISH)
        val turkish = english.copy(language = HushLanguage.TURKISH)
        assertEquals(hushText(context("en"), english), hushText(context("tr"), english))
        assertEquals(hushText(context("en"), turkish), hushText(context("tr"), turkish))
        assertNotEquals(hushText(context("en"), english), hushText(context("en"), turkish))
        assertNotEquals(hushText(context("en"), english.copy(language = HushLanguage.APP)), hushText(context("tr"), english.copy(language = HushLanguage.APP)))
    }
}
