package com.example.kare.ui

import androidx.compose.runtime.*
import androidx.compose.ui.test.*
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.navigation.compose.rememberNavController
import androidx.navigation.NavHostController
import androidx.navigation.toRoute
import com.example.kare.R
import com.example.kare.app.KareViewModelFactory
import com.example.kare.core.design.KareTheme
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import com.example.kare.feature.discover.DiscoverContent
import com.example.kare.feature.library.*
import com.example.kare.feature.search.*
import com.example.kare.navigation.*
import com.example.kare.presentation.*
import org.junit.Assert.*
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.LooperMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@LooperMode(LooperMode.Mode.PAUSED)
class ScreenNavigationTest {
    @get:Rule val compose = createComposeRule()

    @Test fun discoverLoadingErrorRetryLoadedAndSelection() {
        val state = mutableStateOf<LoadState<List<CatalogSection>>>(LoadState.Loading)
        var retry = 0; var selected: String? = null
        compose.setContent { KareTheme { DiscoverContent(state.value, { retry++ }, { selected = it }) } }
        compose.onNodeWithText("Loading widgets…").assertExists()
        compose.runOnIdle { state.value = LoadState.Failed(UiError.STORAGE) }
        compose.onNodeWithText("Try again").performClick()
        assertEquals(1, retry)
        compose.runOnIdle { state.value = LoadState.Loaded(listOf(section)) }
        compose.onNodeWithText("All widgets").assertExists()
        compose.onNodeWithTag("template-test").performScrollTo().performClick()
        assertEquals(template.id, selected)
    }

    @Test fun discoverEmptyCatalogShowsEmptyMessage() {
        compose.setContent { KareTheme { DiscoverContent(LoadState.Loaded(emptyList()), {}, {}) } }
        compose.onNodeWithText("No widgets available").assertExists()
    }

    @Test fun searchInputCategoriesAndResultSelection() {
        var query = ""; var category: WidgetCategory? = null; var selected: String? = null
        compose.setContent { KareTheme { SearchContent(SearchUiState(results = LoadState.Loaded(listOf(template))),
            { query = it }, { category = it }, {}, { selected = it }) } }
        compose.onNodeWithTag("search-query").performTextInput("focus")
        assertEquals("focus", query)
        compose.onNodeWithTag("category-productivity").performScrollTo().performClick()
        assertEquals(WidgetCategory.PRODUCTIVITY, category)
        compose.onNodeWithTag("template-test").performScrollTo().performClick()
        assertEquals(template.id, selected)
    }

    @Test fun searchEmptyFailureRetryAndLoading() {
        val state = mutableStateOf(SearchUiState(results = LoadState.Loaded(emptyList())))
        var retries = 0
        compose.setContent { KareTheme { SearchContent(state.value, {}, {}, { retries++ }, {}) } }
        compose.onNodeWithText("No results").assertExists()
        compose.runOnIdle { state.value = state.value.copy(results = LoadState.Failed(UiError.CONNECTION)) }
        compose.onNodeWithText("Try again").performScrollTo().performClick()
        assertEquals(1, retries)
        compose.runOnIdle { state.value = state.value.copy(results = LoadState.Loading) }
        compose.onNodeWithText("Loading widgets…").assertExists()
    }

    @Test fun libraryEmptyThenFavoritesRemoveAndSelect() {
        val state = mutableStateOf(LibraryUiState(widgets = LoadState.Loaded(emptyList())))
        var favorite: String? = null; var removed: String? = null; var selected: String? = null
        compose.setContent { KareTheme { LibraryContent(state.value, {}, {}, { favorite = it }, { removed = it }, {}, {}, { selected = it }) } }
        compose.onNodeWithText("Nothing here yet").assertExists()
        compose.runOnIdle { state.value = state.value.copy(widgets = LoadState.Loaded(listOf(installed()))) }
        compose.onNodeWithTag("installed-test").performScrollTo().performClick()
        assertEquals(template.id, selected)
        compose.onNodeWithTag("favorite-test").performScrollTo().performClick()
        assertEquals(template.id, favorite)
        compose.onNodeWithTag("remove-test").performScrollTo().performClick()
        assertNull(removed)
        compose.onNodeWithTag("confirm-remove").performClick()
        assertEquals(template.id, removed)
    }

    @Test fun libraryReorderingAndBusyState() {
        val state = mutableStateOf(LibraryUiState(widgets = LoadState.Loaded(listOf(installed(), installed("second")))))
        var reordered: List<String>? = null
        compose.setContent { KareTheme { LibraryContent(state.value, {}, {}, {}, {}, { reordered = it }, {}, {}) } }
        compose.onAllNodesWithText("Move down")[0].performScrollTo().performClick()
        assertEquals(listOf("second", "test"), reordered)
        compose.runOnIdle { state.value = state.value.copy(action = LibraryActionState.Running(LibraryAction(LibraryOperation.REMOVE))) }
        compose.onNodeWithTag("favorite-test").assertIsNotEnabled()
    }

    @Test fun tabsDetailIdAndBackStackPreserveSearch() {
        lateinit var nav: NavHostController
        val factory = KareViewModelFactory(CatalogFake(), LibraryFake(), ErrorReporter { _, _ -> })
        compose.setContent { KareTheme { nav = rememberNavController(); KareApp(factory, nav) } }
        compose.onNodeWithTag("nav-${R.string.discover_title}").assertIsSelected()
        compose.onNodeWithTag("nav-${R.string.library_title}").performClick()
        compose.onNodeWithText("Nothing here yet").assertExists()
        compose.onNodeWithTag("nav-${R.string.profile_title}").performClick()
        compose.onNodeWithText("This feature is not available yet.").assertExists()
        compose.onNodeWithTag("nav-${R.string.settings_title}").performClick()
        compose.onNodeWithTag("nav-${R.string.settings_title}").assertIsSelected()
        compose.onNodeWithTag("nav-${R.string.search_title}").performClick()
        compose.onNodeWithTag("search-query").performTextInput("test")
        compose.waitUntil(5_000) { compose.onAllNodesWithTag("template-test").fetchSemanticsNodes().isNotEmpty() }
        compose.onNodeWithTag("template-test").performScrollTo().performClick()
        compose.onNodeWithTag("detail-test").assertExists()
        compose.runOnIdle { assertEquals("test", nav.currentBackStackEntry!!.toRoute<KareDestination.Detail>().templateId) }
        compose.onNodeWithText("Back").performClick()
        compose.onNodeWithTag("search-query").assertTextContains("test")
        compose.onNodeWithTag("nav-${R.string.library_title}").performClick()
        compose.onNodeWithTag("nav-${R.string.search_title}").performClick()
        compose.onNodeWithTag("search-query").assertTextContains("test")
        compose.runOnIdle { nav.popBackStack() }
        compose.onNodeWithTag("nav-${R.string.discover_title}").assertIsSelected()
    }

    @Test fun typedDetailRoutePreservesReservedCharacters() {
        lateinit var nav: NavHostController
        val factory = KareViewModelFactory(CatalogFake(), LibraryFake(), ErrorReporter { _, _ -> })
        compose.setContent { KareTheme { nav = rememberNavController(); KareApp(factory, nav) } }
        val id = "a/b ?#% Türkçe"
        compose.runOnIdle { nav.navigate(KareDestination.Detail(id)) }
        compose.onNodeWithTag("detail-$id").assertExists()
        compose.runOnIdle { assertEquals(id, nav.currentBackStackEntry!!.toRoute<KareDestination.Detail>().templateId) }
    }
}
