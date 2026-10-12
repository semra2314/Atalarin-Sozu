package com.example.kare.widget

import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import com.example.kare.core.design.KareTheme
import com.example.kare.core.model.LauncherWidgetType
import com.example.kare.core.presentation.LoadState
import com.example.kare.feature.detail.*
import com.example.kare.feature.library.*
import com.example.kare.presentation.*
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.*

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@LooperMode(LooperMode.Mode.PAUSED)
class WidgetPlacementUiTest {
    @get:Rule val compose = createComposeRule()
    @Test @Config(qualifiers = "en-rUS-w320dp-h480dp-night")
    fun englishLargeTextInstructionsScrollWithDismissStillVisible() = checkLargeTextGuidance()

    @Test @Config(qualifiers = "tr-rTR-w320dp-h480dp-night")
    fun turkishLargeTextInstructionsScrollWithDismissStillVisible() = checkLargeTextGuidance()

    private fun checkLargeTextGuidance() {
        var dismissed = false
        compose.setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density, 2f)) {
                KareTheme(darkTheme = true) {
                    WidgetPlacementContent(true, PlacementResult.REQUESTED, {}, { dismissed = true })
                }
            }
        }
        // The full instructions must be reachable, without shrinking accessible text.
        compose.onNode(hasScrollAction()).assertExists()
        val context = androidx.test.core.app.ApplicationProvider.getApplicationContext<android.content.Context>()
        compose.onNodeWithText(context.getString(com.example.kare.R.string.widget_placement_manual))
            .performScrollTo().assertIsDisplayed()
        compose.onNodeWithText(context.getString(com.example.kare.R.string.action_dismiss))
            .assertIsDisplayed().performClick()
        assertTrue(dismissed)
    }

    @Test fun detailOffersPlacementOnlyAfterInstallationAndKeepsLibraryAction() = checkDetail("t-proverb")
    @Test fun hushDetailOffersPlacementOnlyAfterInstallation() = checkDetail("t-hush")
    private fun checkDetail(templateId: String) {
        val state = mutableStateOf(DetailUiState(template = LoadState.Loaded(template.copy(id = templateId)), installed = LoadState.Loaded(null)))
        var requests = 0
        compose.setContent { KareTheme {
            DetailContent(templateId, state.value, {}, {}, {}, {}, {}, {}, placement = { id ->
                WidgetPlacementContent(LauncherWidgetType.forTemplate(id) != null, null, { requests++ }, {})
            })
        } }
        compose.onNodeWithTag("place-widget").assertDoesNotExist()
        compose.runOnIdle { state.value = state.value.copy(installed = LoadState.Loaded(installed(templateId))) }
        compose.onNodeWithTag("detail-$templateId").performScrollToNode(hasTestTag("place-widget"))
        compose.onNodeWithTag("place-widget").performClick()
        assertEquals(1, requests)
        compose.onNodeWithTag("detail-$templateId").performScrollToNode(hasTestTag("open-library"))
        compose.onNodeWithTag("open-library").assertExists()
    }
    @Test fun libraryPlacementDoesNotInvokeRemovalOrFavorite() = checkLibrary("t-proverb")
    @Test fun hushLibraryPlacementPreservesMembershipActions() = checkLibrary("t-hush")
    private fun checkLibrary(templateId: String) {
        var requests = 0; var otherActions = 0
        compose.setContent { KareTheme {
            LibraryContent(LibraryUiState(widgets = LoadState.Loaded(listOf(installed(templateId)))), {}, {},
                { otherActions++ }, { otherActions++ }, {}, {}, {}, placement = { id ->
                    WidgetPlacementContent(LauncherWidgetType.forTemplate(id) != null, null, { requests++ }, {})
                })
        } }
        compose.onNodeWithTag("place-widget").performScrollTo().performClick()
        assertEquals(1, requests); assertEquals(0, otherActions)
    }
    @Test fun unsupportedTemplateHasNoActionAndFallbackIsActionable() {
        val available = mutableStateOf(false)
        val result = mutableStateOf<PlacementResult?>(null)
        compose.setContent { KareTheme {
            WidgetPlacementContent(available.value, result.value, {}, { result.value = null })
        } }
        compose.onNodeWithTag("place-widget").assertDoesNotExist()
        compose.runOnIdle { available.value = true; result.value = PlacementResult.UNSUPPORTED }
        compose.onNodeWithText("Your launcher does not support direct widget placement.").assertExists()
        compose.onNodeWithText("To add manually", substring = true).assertExists()
        compose.onNodeWithText("Dismiss").performClick()
        compose.runOnIdle { assertNull(result.value) }
    }
}
