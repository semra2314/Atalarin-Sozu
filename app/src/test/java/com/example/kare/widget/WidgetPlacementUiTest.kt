package com.example.kare.widget

import androidx.compose.runtime.*
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import com.example.kare.core.design.KareTheme
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
    @Test fun detailOffersPlacementOnlyAfterInstallationAndKeepsLibraryAction() {
        val state = mutableStateOf(DetailUiState(template = LoadState.Loaded(template.copy(id = "t-proverb")), installed = LoadState.Loaded(null)))
        var requests = 0
        compose.setContent { KareTheme {
            DetailContent("t-proverb", state.value, {}, {}, {}, {}, {}, {}, placement = { id ->
                WidgetPlacementContent(id == "t-proverb", null, { requests++ }, {})
            })
        } }
        compose.onNodeWithTag("place-widget").assertDoesNotExist()
        compose.runOnIdle { state.value = state.value.copy(installed = LoadState.Loaded(installed("t-proverb"))) }
        compose.onNodeWithTag("detail-t-proverb").performScrollToNode(hasTestTag("place-widget"))
        compose.onNodeWithTag("place-widget").performClick()
        assertEquals(1, requests)
        compose.onNodeWithTag("detail-t-proverb").performScrollToNode(hasTestTag("open-library"))
        compose.onNodeWithTag("open-library").assertExists()
    }
    @Test fun libraryPlacementDoesNotInvokeRemovalOrFavorite() {
        var requests = 0; var otherActions = 0
        compose.setContent { KareTheme {
            LibraryContent(LibraryUiState(widgets = LoadState.Loaded(listOf(installed("t-proverb")))), {}, {},
                { otherActions++ }, { otherActions++ }, {}, {}, {}, placement = { id ->
                    WidgetPlacementContent(id == "t-proverb", null, { requests++ }, {})
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
