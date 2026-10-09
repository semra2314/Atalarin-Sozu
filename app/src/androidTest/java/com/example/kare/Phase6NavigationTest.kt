package com.example.kare

import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.test.espresso.Espresso.pressBack
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/** Exercises the real application container, bundled catalog and native back dispatch. */
@RunWith(AndroidJUnit4::class)
class Phase6NavigationTest {
    @get:Rule val compose = createAndroidComposeRule<MainActivity>()

    @Test fun searchDetailBackAndActivityRecreation() {
        compose.onNodeWithTag("nav-${R.string.discover_title}").assertIsSelected()
        compose.onNodeWithTag("nav-${R.string.search_title}").performClick()
        compose.onNodeWithTag("search-query").performTextInput("Aurora")
        compose.onNodeWithTag("search-query").performImeAction()
        compose.waitUntil(10_000) {
            compose.onAllNodesWithTag("template-t-aurora").fetchSemanticsNodes().isNotEmpty()
        }
        compose.onNodeWithTag("template-t-aurora").performScrollTo().performClick()
        compose.onNodeWithTag("detail-t-aurora").assertExists()
        pressBack()
        compose.onNodeWithTag("search-query").assertTextContains("Aurora")
        compose.activityRule.scenario.recreate()
        compose.onNodeWithTag("search-query").assertTextContains("Aurora")
        compose.onNodeWithTag("nav-${R.string.library_title}").performClick()
        compose.onNodeWithTag("nav-${R.string.library_title}").assertIsSelected()
        compose.onNodeWithTag("nav-${R.string.profile_title}").performClick()
        compose.onNodeWithText(compose.activity.getString(R.string.feature_pending)).assertExists()
        compose.onNodeWithTag("nav-${R.string.settings_title}").performClick()
        compose.onNodeWithTag("nav-${R.string.settings_title}").assertIsSelected()
        pressBack()
        compose.onNodeWithTag("nav-${R.string.discover_title}").assertIsSelected()
    }
    private fun detailNode(tag: String): SemanticsNodeInteraction {
        compose.onNodeWithTag("detail-t-aurora").performScrollToNode(hasTestTag(tag))
        return compose.onNodeWithTag(tag)
    }

    @Test fun discoverDetailInstallLibraryAndReopen() {
        compose.waitUntil(10_000) {
            compose.onAllNodesWithTag("template-t-aurora").fetchSemanticsNodes().isNotEmpty()
        }
        compose.onAllNodesWithTag("template-t-aurora")[0].performScrollTo().performClick()
        compose.waitUntil(10_000) {
            compose.onAllNodesWithText("Aurora Clock").fetchSemanticsNodes().isNotEmpty()
        }
        detailNode("size-small").performClick()
        detailNode("detail-install").performClick()
        compose.waitUntil(10_000) {
            compose.onAllNodesWithTag("detail-install").fetchSemanticsNodes().isEmpty()
        }
        detailNode("open-library").performClick()
        compose.waitUntil(10_000) {
            compose.onAllNodesWithTag("installed-t-aurora").fetchSemanticsNodes().isNotEmpty()
        }
        compose.onNodeWithTag("favorite-t-aurora").performScrollTo().performClick()
        compose.onNodeWithTag("installed-t-aurora").performScrollTo().performClick()
        compose.waitUntil(10_000) {
            compose.onAllNodesWithText("Aurora Clock").fetchSemanticsNodes().isNotEmpty()
        }
        detailNode("detail-installed").assertExists()
        detailNode("size-small").assertIsSelected()
        pressBack()
        compose.onNodeWithTag("remove-t-aurora").performScrollTo().performClick()
        compose.onNodeWithTag("confirm-remove").performClick()
        compose.waitUntil(10_000) {
            compose.onAllNodesWithTag("installed-t-aurora").fetchSemanticsNodes().isEmpty()
        }
    }

}
