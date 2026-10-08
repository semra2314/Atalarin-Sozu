package com.example.kare.presentation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelStore
import com.example.kare.app.KareViewModelFactory
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import com.example.kare.core.repository.RepositoryException
import com.example.kare.feature.discover.DiscoverViewModel
import com.example.kare.feature.search.SearchViewModel
import com.example.kare.feature.library.*
import kotlinx.coroutines.*
import kotlinx.coroutines.test.*
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class ViewModelsTest {
    private val dispatcher = StandardTestDispatcher()
    private val store = ViewModelStore()
    private val catalog = CatalogFake()
    private val library = LibraryFake()
    private val reported = mutableListOf<Throwable>()
    private val reporter = ErrorReporter { _, error -> reported += error }
    @Before fun setup() { Dispatchers.setMain(dispatcher) }
    @After fun cleanup() { store.clear(); Dispatchers.resetMain() }
    private fun <T : ViewModel> keep(vm: T): T = vm.also { store.put(it.javaClass.name, it) }
    private fun discover() = keep(DiscoverViewModel(catalog, reporter))
    private fun search() = keep(SearchViewModel(catalog, reporter))
    private fun libraryVm() = keep(LibraryViewModel(library, catalog, reporter))

    @Test fun discoverStartsLoadingThenLoads() = runTest {
        val vm = discover()
        assertEquals(LoadState.Loading, vm.state.value)
        runCurrent()
        assertEquals(LoadState.Loaded(listOf(section)), vm.state.value)
    }
    @Test fun discoverFailureRetainsDiagnosticAndRetryWorks() = runTest {
        val error = RepositoryException.Persistence(IllegalStateException("diagnostic"))
        catalog.discover = { throw error }
        val vm = discover(); runCurrent()
        assertEquals(LoadState.Failed(UiError.STORAGE), vm.state.value)
        assertSame(error, reported.single())
        catalog.discover = { emptyList() }
        vm.reload(); runCurrent()
        assertEquals(LoadState.Loaded(emptyList<CatalogSection>()), vm.state.value)
    }
    @Test fun discoverReloadCancelsSupersededLoad() = runTest {
        var cancelled = false
        catalog.discover = { try { awaitCancellation() } finally { cancelled = true } }
        val vm = discover(); runCurrent()
        catalog.discover = { listOf(section) }
        vm.reload(); runCurrent()
        assertTrue(cancelled)
        assertEquals(LoadState.Loaded(listOf(section)), vm.state.value)
        assertTrue(reported.isEmpty())
    }
    @Test fun emptySearchLoadsCatalogImmediately() = runTest {
        val vm = search()
        assertEquals(LoadState.Loading, vm.state.value.results)
        runCurrent()
        assertEquals(listOf("" to null), catalog.searches)
        assertEquals(LoadState.Loaded(listOf(template)), vm.state.value.results)
    }
    @Test fun typingDebouncesAndNormalizesEquivalentQueries() = runTest {
        val vm = search(); runCurrent(); catalog.searches.clear()
        vm.setQuery("f"); advanceTimeBy(200)
        vm.setQuery("focus"); advanceTimeBy(279); runCurrent()
        assertTrue(catalog.searches.isEmpty())
        advanceTimeBy(1); runCurrent()
        assertEquals(listOf("focus" to null), catalog.searches)
        vm.setQuery(" FOCUS "); advanceUntilIdle()
        assertEquals(1, catalog.searches.size)
        assertEquals(" FOCUS ", vm.state.value.query)
    }
    @Test fun categoryIntersectsQueryAndClearsExplicitly() = runTest {
        val vm = search(); runCurrent()
        vm.setQuery("test"); vm.setCategory(WidgetCategory.MINIMAL); advanceUntilIdle()
        assertEquals("test" to WidgetCategory.MINIMAL, catalog.searches.last())
        val count = catalog.searches.size
        vm.setCategory(WidgetCategory.MINIMAL); advanceUntilIdle()
        assertEquals(count, catalog.searches.size)
        vm.setCategory(null); advanceUntilIdle()
        assertEquals("test" to null, catalog.searches.last())
    }
    @Test fun searchFailureEmptyResultsAndRetry() = runTest {
        catalog.searchBlock = { _, _ -> throw RepositoryException.Transport(Exception()) }
        val vm = search(); runCurrent()
        assertEquals(LoadState.Failed(UiError.CONNECTION), vm.state.value.results)
        assertFalse(vm.state.value.isEmpty)
        catalog.searchBlock = { _, _ -> emptyList() }
        vm.retry(); runCurrent()
        assertTrue(vm.state.value.isEmpty)
    }
    @Test fun newQueryCancelsInFlightRequestBeforeDebounceEnds() = runTest {
        var cancelled = false
        catalog.searchBlock = { _, _ -> try { awaitCancellation() } finally { cancelled = true } }
        val vm = search(); runCurrent()
        catalog.searchBlock = { _, _ -> listOf(template) }
        vm.setQuery("new"); runCurrent()
        assertTrue(cancelled)
        assertEquals(1, catalog.searches.size)
        advanceUntilIdle()
        assertEquals(LoadState.Loaded(listOf(template)), vm.state.value.results)
        assertTrue(reported.isEmpty())
    }
    @Test fun uncooperativeOldSearchCannotOverwriteNewResults() = runTest {
        val old = CompletableDeferred<List<WidgetTemplate>>()
        catalog.searchBlock = { _, _ -> withContext(NonCancellable) { old.await() } }
        val vm = search(); runCurrent()
        catalog.searchBlock = { _, _ -> emptyList() }
        vm.setQuery("none"); advanceTimeBy(280); runCurrent()
        old.complete(listOf(template)); runCurrent()
        assertTrue(vm.state.value.isEmpty)
        assertTrue(reported.isEmpty())
    }
    @Test fun libraryObservesReactiveWidgetsAndFavorites() = runTest {
        val vm = libraryVm()
        assertEquals(LoadState.Loading, vm.state.value.widgets)
        runCurrent()
        assertEquals(LoadState.Loaded(emptyList<InstalledWidget>()), vm.state.value.widgets)
        library.rows.value = listOf(installed(), installed("favorite").copy(isFavorite = true)); runCurrent()
        assertEquals(2, vm.state.value.visibleWidgets.size)
        vm.setFavoritesOnly(true)
        assertEquals(listOf("favorite"), vm.state.value.visibleWidgets.map { it.templateId })
    }
    @Test fun libraryInstallsAndRemovesThroughRepositories() = runTest {
        val vm = libraryVm(); runCurrent()
        assertTrue(vm.install(template.id, WidgetSize.SMALL))
        assertTrue(vm.state.value.action is LibraryActionState.Running)
        runCurrent()
        assertEquals(template.id, vm.state.value.visibleWidgets.single().templateId)
        assertTrue(vm.state.value.action is LibraryActionState.Succeeded)
        vm.remove(template.id); runCurrent()
        assertTrue(vm.state.value.visibleWidgets.isEmpty())
    }
    @Test fun favoriteToggleReadsLatestStoredState() = runTest {
        library.rows.value = listOf(installed())
        val vm = libraryVm(); runCurrent()
        vm.toggleFavorite(template.id); runCurrent()
        assertTrue(vm.state.value.visibleWidgets.single().isFavorite)
        vm.toggleFavorite(template.id); runCurrent()
        assertFalse(vm.state.value.visibleWidgets.single().isFavorite)
    }
    @Test fun reorderAndContentUpdatePropagateReactiveSnapshots() = runTest {
        library.rows.value = listOf(installed(), installed("second"))
        val vm = libraryVm(); runCurrent()
        val ids = mutableListOf("second", template.id)
        vm.reorder(ids); ids.clear(); runCurrent()
        assertEquals(listOf("second", template.id), vm.state.value.visibleWidgets.map { it.templateId })
        val content = WidgetContent(text = "Saved")
        vm.updateContent(template.id, content); runCurrent()
        assertEquals(content, vm.state.value.visibleWidgets.last().content)
    }
    @Test fun actionFailureKeepsLibraryDataAndCanBeCleared() = runTest {
        library.rows.value = listOf(installed())
        library.mutation = { throw RepositoryException.InvalidData("order") }
        val vm = libraryVm(); runCurrent()
        vm.remove(template.id); runCurrent()
        assertEquals(1, vm.state.value.visibleWidgets.size)
        assertEquals(UiError.INVALID_DATA, (vm.state.value.action as LibraryActionState.Failed).error)
        vm.clearAction()
        assertEquals(LibraryActionState.Idle, vm.state.value.action)
        library.mutation = {}
        vm.remove(template.id); runCurrent()
        assertTrue(vm.state.value.visibleWidgets.isEmpty())
    }
    @Test fun observationFailureCanResubscribe() = runTest {
        library.observationFailure = RepositoryException.Persistence(Exception())
        val vm = libraryVm(); runCurrent()
        assertEquals(LoadState.Failed(UiError.STORAGE), vm.state.value.widgets)
        library.observationFailure = null
        vm.retryObservation(); runCurrent()
        library.rows.value = listOf(installed()); runCurrent()
        assertEquals(1, vm.state.value.visibleWidgets.size)
    }
    @Test fun busyCommandsAreRejectedAndCancellationIsNotFailure() = runTest {
        library.mutation = { awaitCancellation() }
        val vm = libraryVm(); runCurrent()
        assertTrue(vm.install(template.id, WidgetSize.SMALL)); runCurrent()
        assertFalse(vm.remove(template.id))
        vm.clearAction()
        assertTrue(vm.state.value.action is LibraryActionState.Running)
        store.clear(); runCurrent()
        assertTrue(reported.isEmpty())
        assertTrue(library.rows.value.isEmpty())
    }
    @Test fun missingCatalogEntryFailsInstallWithoutWritingLibrary() = runTest {
        val vm = libraryVm(); runCurrent()
        vm.install("missing", WidgetSize.SMALL); runCurrent()
        assertEquals(UiError.NOT_FOUND, (vm.state.value.action as LibraryActionState.Failed).error)
        assertTrue(library.rows.value.isEmpty())
    }
    @Test fun factoryCreatesAllSupportedViewModelsAndRejectsUnknownTypes() = runTest {
        val factory = KareViewModelFactory(catalog, library, reporter)
        keep(factory.create(DiscoverViewModel::class.java))
        keep(factory.create(SearchViewModel::class.java))
        keep(factory.create(LibraryViewModel::class.java))
        runCurrent()
        try { factory.create(ViewModel::class.java); fail("Unknown model accepted") }
        catch (_: IllegalArgumentException) { }
    }
    @Test fun everyRepositoryErrorMapsWithoutExposingExceptions() {
        val mappings = listOf(
            RepositoryException.NotFound("id") to UiError.NOT_FOUND,
            RepositoryException.Unavailable("op") to UiError.UNAVAILABLE,
            RepositoryException.Unauthenticated() to UiError.SIGN_IN_REQUIRED,
            RepositoryException.InvalidData("field") to UiError.INVALID_DATA,
            RepositoryException.Transport(Exception()) to UiError.CONNECTION,
            RepositoryException.Persistence(Exception()) to UiError.STORAGE,
            IllegalStateException("private details") to UiError.UNEXPECTED,
        )
        mappings.forEach { (error, expected) -> assertEquals(expected, error.toUiError("test", reporter)) }
        assertEquals(mappings.map { it.first }, reported)
        try { CancellationException().toUiError("test", reporter); fail("Cancellation swallowed") }
        catch (_: CancellationException) { }
        assertEquals(mappings.size, reported.size)
    }
}
