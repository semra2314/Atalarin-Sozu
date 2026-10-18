package com.example.kare

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.espresso.Espresso.pressBack
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.*
import org.junit.runner.RunWith

/** Exercises the real unprovisioned Play adapter; never simulates a successful transaction. */
@RunWith(AndroidJUnit4::class)
class Phase18BillingTest {
    @get:Rule(order = 0) val onboarding = CompletedOnboardingRule()
    @get:Rule(order = 1) val compose = createAndroidComposeRule<MainActivity>()

    @Test fun unconfiguredBillingIsReachableRecoverableAndDoesNotBlockFreeNavigation() {
        compose.waitUntil(10_000) { compose.onAllNodesWithTag("nav-${R.string.settings_title}").fetchSemanticsNodes().isNotEmpty() }
        compose.onNodeWithTag("nav-${R.string.settings_title}").performClick()
        compose.onNodeWithTag("settings-kare-plus").performScrollTo().performClick()
        compose.onNodeWithTag("kare-plus").assertExists()
        compose.onNodeWithTag("plus-purchase").performScrollTo().assertIsNotEnabled()
        compose.waitUntil(60_000) {
            compose.onAllNodesWithTag("plus-restore").fetchSemanticsNodes().any {
                !it.config.contains(androidx.compose.ui.semantics.SemanticsProperties.Disabled)
            }
        }
        compose.onNodeWithTag("plus-restore").performScrollTo().performClick()
        compose.onNodeWithTag("plus-purchase").performScrollTo().assertIsNotEnabled()
        pressBack()
        compose.onNodeWithTag("nav-${R.string.library_title}").performClick().assertIsSelected()
        compose.onNodeWithTag("nav-${R.string.search_title}").performClick()
        compose.onNodeWithTag("search-query").assertExists()
    }
}
