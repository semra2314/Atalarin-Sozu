package com.example.kare.feature.detail

import androidx.lifecycle.*
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import com.example.kare.core.repository.*
import com.example.kare.feature.library.LibraryViewModel
import com.example.kare.presentation.*
import java.math.BigDecimal
import kotlinx.coroutines.*
import kotlinx.coroutines.test.*
import org.junit.*
import org.junit.Assert.*

@OptIn(ExperimentalCoroutinesApi::class)
class DetailViewModelTest {
    private val dispatcher = StandardTestDispatcher()
    private val store = ViewModelStore()
    private val library = LibraryFake()
    private val reports = mutableListOf<Throwable>()
    private val errors = ErrorReporter { _, error -> reports += error }
    private var value = template
    private var failure: Exception? = null
    private val catalog = object : WidgetRepository by CatalogFake() {
        override suspend fun template(id: String): WidgetTemplate {
            failure?.let { throw it }
            return value
        }
    }
    private fun vm(handle: SavedStateHandle = SavedStateHandle()) = DetailViewModel(value.id, catalog, library, errors, handle)
        .also { store.put("detail", it) }
    @Before fun before() { Dispatchers.setMain(dispatcher) }
    @After fun after() { store.clear(); Dispatchers.resetMain() }

    @Test fun loadsSingleSizeAndFreeInstallUpdatesMembershipWithoutDuplicate() = runTest {
        val vm = vm(); assertEquals(LoadState.Loading, vm.state.value.template); runCurrent()
        assertEquals(value, (vm.state.value.template as LoadState.Loaded).value)
        assertEquals(WidgetSize.SMALL, vm.state.value.selectedSize)
        vm.install(); vm.install(); runCurrent()
        assertNotNull((vm.state.value.installed as LoadState.Loaded).value)
        vm.install(); runCurrent(); assertEquals(1, library.rows.value.size)
    }
    @Test fun notFoundAndLoadFailureMapAndRetry() = runTest {
        failure = RepositoryException.NotFound("missing")
        val vm = vm(); runCurrent(); assertEquals(LoadState.Failed(UiError.NOT_FOUND), vm.state.value.template)
        failure = RepositoryException.Transport(IllegalStateException())
        vm.reload(); runCurrent(); assertEquals(LoadState.Failed(UiError.CONNECTION), vm.state.value.template)
        failure = null; vm.reload(); runCurrent(); assertTrue(vm.state.value.template is LoadState.Loaded)
        assertEquals(2, reports.size)
    }
    @Test fun multipleSizesRequireExplicitValidSelectionAndRestoreOnlySize() = runTest {
        value = value.copy(supportedSizes = listOf(WidgetSize.SMALL, WidgetSize.MEDIUM))
        val handle = SavedStateHandle(); val vm = vm(handle); runCurrent()
        assertNull(vm.state.value.selectedSize); assertFalse(vm.state.value.canInstall)
        vm.install(); assertEquals(InstallState.Failed(UiError.INVALID_DATA), vm.state.value.action)
        vm.selectSize(WidgetSize.LARGE); assertFalse(vm.state.value.canInstall)
        vm.selectSize(WidgetSize.MEDIUM); assertTrue(vm.state.value.canInstall)
        assertEquals(setOf("detail.size"), handle.keys())
        val restored = vm(SavedStateHandle(mapOf("detail.size" to handle.get<String>("detail.size")))); runCurrent()
        assertEquals(WidgetSize.MEDIUM, restored.state.value.selectedSize)
        restored.install(); runCurrent(); assertEquals(WidgetSize.MEDIUM, library.rows.value.single().size)
    }
    @Test fun retiredSavedSizeDoesNotInventUnsupportedChoice() = runTest {
        value = value.copy(supportedSizes = listOf(WidgetSize.SMALL, WidgetSize.MEDIUM))
        val vm = vm(SavedStateHandle(mapOf("detail.size" to "accessoryCircular"))); runCurrent()
        assertNull(vm.state.value.selectedSize)
    }
    @Test fun persistenceAndSerializationFailuresPreserveDiagnosticsAndCanRetry() = runTest {
        val vm = vm(); runCurrent()
        for ((error, key) in listOf(RepositoryException.Persistence(IllegalStateException()) to UiError.STORAGE,
            RepositoryException.InvalidData("library JSON") to UiError.INVALID_DATA)) {
            library.mutation = { throw error }; vm.install(); runCurrent()
            assertEquals(InstallState.Failed(key), vm.state.value.action); assertSame(error, reports.last())
            assertTrue(library.rows.value.isEmpty())
        }
        library.mutation = {}; vm.install(); runCurrent(); assertEquals(1, library.rows.value.size)
    }
    @Test fun existingRowIsPreservedAndRemovalIsObserved() = runTest {
        library.rows.value = listOf(installed().copy(isFavorite = true, size = WidgetSize.MEDIUM))
        val vm = vm(); runCurrent(); vm.install(); runCurrent()
        assertFalse(vm.state.value.canInstall); assertTrue(library.rows.value.single().isFavorite)
        library.remove(value.id); runCurrent(); assertTrue(vm.state.value.canInstall)
    }
    @Test fun paidTemplateCannotInstallThroughEitherApplicationEntryPoint() = runTest {
        value = value.copy(price = WidgetTemplate.Price.Paid(BigDecimal("1.99"), "USD"))
        val vm = vm(); runCurrent(); vm.install(); runCurrent()
        assertFalse(vm.state.value.canInstall)
        assertEquals(InstallState.Failed(UiError.UNAVAILABLE), vm.state.value.action)
        val list = LibraryViewModel(library, catalog, errors).also { store.put("library", it) }
        list.install(value.id, WidgetSize.SMALL); runCurrent()
        assertTrue(library.rows.value.isEmpty())
    }
    @Test fun observationFailureBlocksInstallUntilRetry() = runTest {
        library.observationFailure = RepositoryException.Persistence(IllegalStateException())
        val vm = vm(); runCurrent(); assertFalse(vm.state.value.canInstall)
        vm.install(); runCurrent(); assertTrue(library.rows.value.isEmpty())
        library.observationFailure = null; vm.retryLibrary(); runCurrent(); assertTrue(vm.state.value.canInstall)
    }
    @Test fun racingDuplicateReturnsExistingSnapshot() = runTest {
        val gate = CompletableDeferred<Unit>(); library.mutation = { gate.await() }
        val vm = vm(); runCurrent(); vm.install(); runCurrent()
        library.rows.value = listOf(installed().copy(isFavorite = true))
        gate.complete(Unit); runCurrent()
        assertEquals(1, library.rows.value.size)
        assertTrue((vm.state.value.installed as LoadState.Loaded).value!!.isFavorite)
    }
    @Test fun cancellationIsNotReportedAsFailure() = runTest {
        library.mutation = { awaitCancellation() }
        val vm = vm(); runCurrent(); vm.install(); runCurrent(); store.clear(); runCurrent()
        assertTrue(reports.isEmpty()); assertTrue(library.rows.value.isEmpty())
    }
}
