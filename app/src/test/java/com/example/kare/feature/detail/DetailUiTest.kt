package com.example.kare.feature.detail

import androidx.compose.runtime.*
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import com.example.kare.core.design.KareTheme
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import com.example.kare.presentation.*
import java.math.BigDecimal
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.*

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@LooperMode(LooperMode.Mode.PAUSED)
class DetailUiTest {
    @get:Rule val compose = createComposeRule()
    private val loaded = DetailUiState(LoadState.Loaded(template.copy(supportedSizes = listOf(WidgetSize.SMALL, WidgetSize.MEDIUM))), LoadState.Loaded(null))

    private fun node(tag: String): SemanticsNodeInteraction {
        compose.onNodeWithTag("detail-test").performScrollToNode(hasTestTag(tag))
        return compose.onNodeWithTag(tag)
    }
    private fun text(value: String): SemanticsNodeInteraction {
        compose.onNodeWithTag("detail-test").performScrollToNode(hasText(value))
        return compose.onNodeWithText(value)
    }
    @Test fun contentSizeChoiceInstallAndInstalledAction() {
        val state = mutableStateOf(loaded)
        var installs = 0; var opens = 0
        compose.setContent { KareTheme { DetailContent(template.id, state.value, {}, { opens++ }, {}, {},
            { state.value = state.value.copy(selectedSize = it) }, { installs++ }) } }
        compose.onNodeWithText("Test").assertExists()
        node("detail-install").assertIsNotEnabled()
        node("size-medium").performClick().assertIsSelected()
        node("detail-install").performClick(); assertEquals(1, installs)
        compose.runOnIdle { state.value = state.value.copy(installed = LoadState.Loaded(installed())) }
        node("detail-installed").assertExists()
        node("open-library").performClick(); assertEquals(1, opens)
        compose.onNodeWithTag("detail-install").assertDoesNotExist()
    }
    @Test fun paidStateNeverExposesEnabledInstall() {
        val paid = template.copy(price = WidgetTemplate.Price.Paid(BigDecimal.ONE, "USD"))
        compose.setContent { KareTheme { DetailContent(template.id, loaded.copy(template = LoadState.Loaded(paid)), {}, {}, {}, {}, {}, {}) } }
        text("Paid widget · Locked").assertExists()
        node("purchase-unavailable").assertIsNotEnabled()
        compose.onNodeWithTag("detail-install").assertDoesNotExist()
    }
    @Test fun notFoundRetryAndInstallFailureAreLocalized() {
        val state = mutableStateOf(DetailUiState(template = LoadState.Failed(UiError.NOT_FOUND)))
        var retries = 0
        compose.setContent { KareTheme { DetailContent(template.id, state.value, {}, {}, { retries++ }, {}, {}, {}) } }
        compose.onNodeWithText("Try again").performClick(); assertEquals(1, retries)
        compose.runOnIdle { state.value = loaded.copy(selectedSize = WidgetSize.SMALL, action = InstallState.Failed(UiError.STORAGE)) }
        text("Could not install widget").assertExists()
        text("Try again").assertExists()
    }
}
