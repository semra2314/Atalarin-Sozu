package com.example.kare.widget

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModelStore
import com.example.kare.core.data.widget.*
import com.example.kare.core.model.*
import com.example.kare.core.presentation.*
import com.example.kare.core.repository.WidgetRepository
import com.example.kare.presentation.*
import java.io.File
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.*
import org.junit.*
import org.junit.Assert.*
import org.junit.rules.TemporaryFolder
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
@OptIn(ExperimentalCoroutinesApi::class)
class ProverbHardeningTest {
    @get:Rule val temp = TemporaryFolder()
    @Test fun smallStandardWideAndTallLayoutsPrioritizeReadableContent() {
        assertFalse(ProverbLayout.forSize(180f, 180f, 1f).showKind)
        assertFalse(ProverbLayout.forSize(250f, 220f, 1f).showExample)
        assertFalse(ProverbLayout.forSize(600f, 180f, 1f).showExample)
        assertTrue(ProverbLayout.forSize(300f, 400f, 1f).showExample)
        assertEquals(12, ProverbLayout.forSize(180f, 600f, 1f).padding)
    }
    @Test fun largerFontsRemoveSecondaryContentBeforeShrinkingText() {
        assertTrue(ProverbLayout.forSize(300f, 400f, 1f).showExample)
        assertFalse(ProverbLayout.forSize(300f, 400f, 2f).showExample)
        assertFalse(ProverbLayout.forSize(180f, 300f, 2f).showKind)
        assertTrue(ProverbLayout.forSize(600f, 600f, 2f).showExample)
    }
    @Test fun corruptConfigurationCanBeExplicitlyRepairedWithoutTouchingOtherInstances() = runBlocking {
        val dispatcher = UnconfinedTestDispatcher()
        Dispatchers.setMain(dispatcher)
        val vms = ViewModelStore()
        try {
            val dir = temp.newFolder()
            val storage = WidgetInstanceStore(dir)
            val library = LibraryFake()
            val catalog = object : WidgetRepository by CatalogFake() {
                override suspend fun template(id: String) = template.copy(id = id)
            }
            val reported = mutableListOf<Throwable>()
            val repo = ProverbWidgetRepository(storage, library, catalog, ErrorReporter { _, e -> reported += e })
            repo.configure(2, ProverbSelection.IDIOMS)
            File(dir, "1.json").writeText("broken")
            var refreshes = 0
            val vm = WidgetConfigurationViewModel(1, repo, { refreshes++ }, ErrorReporter { _, e -> reported += e }, SavedStateHandle())
            vms.put("config", vm)
            withTimeout(5000) { vm.state.first { it.recovering } }
            assertEquals("broken", File(dir, "1.json").readText())
            assertEquals(ProverbSelection.IDIOMS, repo.configuration(2)!!.selection)
            vm.select(ProverbSelection.PROVERBS); vm.save()
            withTimeout(5000) { vm.state.first { it.saved } }
            assertEquals(ProverbSelection.PROVERBS, repo.configuration(1)!!.selection)
            assertEquals(ProverbSelection.IDIOMS, repo.configuration(2)!!.selection)
            assertEquals(1, library.rows.value.size)
            assertEquals(1, refreshes)
            assertEquals(1, reported.size)
            repo.delete(1)
            val missing = WidgetConfigurationViewModel(1, repo, {}, ErrorReporter { _, _ -> }, SavedStateHandle())
            vms.put("missing", missing)
            withTimeout(5000) { missing.state.first { it.selection is LoadState.Loaded } }
            assertFalse(missing.state.value.recovering)
            missing.select(ProverbSelection.IDIOMS); missing.save()
            withTimeout(5000) { missing.state.first { it.saved } }
            assertEquals(ProverbSelection.IDIOMS, repo.configuration(1)!!.selection)
        } finally { vms.clear(); Dispatchers.resetMain() }
    }
}
