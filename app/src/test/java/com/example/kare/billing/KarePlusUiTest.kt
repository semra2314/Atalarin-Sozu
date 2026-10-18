package com.example.kare.billing

import androidx.compose.runtime.*
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.Density
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import com.example.kare.core.billing.*
import com.example.kare.core.design.KareTheme
import com.example.kare.feature.plus.*
import java.io.File
import javax.xml.parsers.DocumentBuilderFactory
import org.junit.*
import org.junit.Assert.*
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.*

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28], qualifiers = "en-rUS-w320dp-h480dp")
@LooperMode(LooperMode.Mode.PAUSED)
class KarePlusUiTest {
    @get:Rule val compose = createComposeRule()
    @Test fun playPriceSelectionPurchaseAndRestoreRemainReachableAtDoubleFontScale() {
        val product = BillingProduct("offer", "test.monthly", "Monthly plan", "", PlayProductType.SUBSCRIPTION,
            listOf(PricingPhase("₺49.99", "P1M", 0, true)), "monthly", null)
        var selected by mutableStateOf<String?>(null)
        var purchases = 0
        var restores = 0
        compose.setContent {
            val density = LocalDensity.current
            CompositionLocalProvider(LocalDensity provides Density(density.density, 2f)) {
                KareTheme { KarePlusContent(KarePlusUiState(BillingState(products = listOf(product)), EntitlementState.Free, selected),
                    {}, { selected = it }, { purchases++ }, { restores++ }, {}) }
            }
        }
        compose.onNodeWithText("Monthly plan").performScrollTo().performClick().assertIsSelected()
        compose.onNodeWithText("₺49.99 per month", substring = true).assertExists()
        compose.onNodeWithTag("plus-purchase").performScrollTo().performClick()
        compose.onNodeWithTag("plus-restore").performScrollTo().performClick()
        assertEquals(1, purchases)
        assertEquals(1, restores)
    }
    @Test fun pendingDoesNotOfferPurchaseAndMissingProductsNeverShowFakePrice() {
        var state by mutableStateOf(KarePlusUiState(BillingState(), EntitlementState.Pending(setOf("test.monthly"))))
        compose.setContent { KareTheme { KarePlusContent(state, {}, {}, {}, {}, {}) } }
        compose.onNodeWithTag("plus-purchase").performScrollTo().assertIsNotEnabled()
        compose.onNodeWithTag("plus-entitlement").performScrollTo().assertTextContains("Payment is pending", substring = true)
        compose.runOnIdle { state = KarePlusUiState(BillingState(productError = BillingError.NOT_CONFIGURED), EntitlementState.Free) }
        compose.onNodeWithText("Kare+ plans are not configured", substring = true).performScrollTo().assertIsDisplayed()
        compose.onNodeWithTag("plus-purchase").performScrollTo().assertIsNotEnabled()
    }
    @Test fun billingTranslationsHaveMatchingKeysAndFormatContracts() {
        fun strings(locale: String): Map<String, String> {
            val nodes = DocumentBuilderFactory.newInstance().newDocumentBuilder()
                .parse(File("src/main/res/$locale/strings_billing.xml")).getElementsByTagName("string")
            return (0 until nodes.length).associate { nodes.item(it).attributes.getNamedItem("name").nodeValue to nodes.item(it).textContent }
        }
        val en = strings("values"); val tr = strings("values-tr")
        assertEquals(en.keys, tr.keys)
        val format = Regex("%[0-9]+\\$[sd]")
        en.forEach { (key, value) ->
            assertTrue(tr.getValue(key).isNotBlank())
            assertEquals(key, format.findAll(value).map { it.value }.sorted().toList(), format.findAll(tr.getValue(key)).map { it.value }.sorted().toList())
        }
    }
}
