package com.example.kare.billing

import androidx.lifecycle.*
import com.example.kare.core.billing.*
import com.example.kare.core.model.WidgetTemplate
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.WidgetRepository
import com.example.kare.feature.detail.DetailViewModel
import com.example.kare.feature.library.LibraryViewModel
import com.example.kare.feature.plus.KarePlusViewModel
import com.example.kare.presentation.*
import java.math.BigDecimal
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.*
import org.junit.*
import org.junit.Assert.*

@OptIn(ExperimentalCoroutinesApi::class)
class BillingGatingTest {
    private val dispatcher = StandardTestDispatcher()
    private val store = ViewModelStore()
    private val access = object : EntitlementRepository { override val entitlement = MutableStateFlow<EntitlementState>(EntitlementState.Free) }
    private val premium = EntitlementState.Premium(listOf(EntitlementGrant("test.monthly", verification = VerificationLevel.LOCAL_PLAY, autoRenewing = true, checkedAtMillis = 1)))
    @Before fun before() { Dispatchers.setMain(dispatcher) }
    @After fun after() { store.clear(); Dispatchers.resetMain() }
    @Test fun paidDetailUnlocksReactivelyAndExpiryPreservesInstalledContent() = runTest {
        val paid = template.copy(price = WidgetTemplate.Price.Paid(BigDecimal.ONE, "USD"))
        val catalog = object : WidgetRepository by CatalogFake() { override suspend fun template(id: String) = paid }
        val library = LibraryFake()
        val vm = DetailViewModel(paid.id, catalog, library, ErrorReporter { _, _ -> }, entitlements = access).also { store.put("detail", it) }
        runCurrent(); assertFalse(vm.state.value.canInstall); vm.install(); runCurrent(); assertTrue(library.rows.value.isEmpty())
        access.entitlement.value = premium; runCurrent(); assertTrue(vm.state.value.canInstall)
        vm.install(); runCurrent(); assertEquals(1, library.rows.value.size)
        access.entitlement.value = EntitlementState.Free; runCurrent(); assertEquals(1, library.rows.value.size)
        assertFalse(vm.state.value.canInstall)
    }
    @Test fun libraryInstallUsesSamePolicyAndFreeContentNeverNeedsBilling() = runTest {
        val library = LibraryFake()
        val vm = LibraryViewModel(library, CatalogFake(), ErrorReporter { _, _ -> }, access).also { store.put("library", it) }
        access.entitlement.value = EntitlementState.Error(BillingError.NETWORK)
        vm.install(template.id, template.primarySize); runCurrent(); assertEquals(1, library.rows.value.size)
        val paid = template.copy(price = WidgetTemplate.Price.Paid(BigDecimal.ONE, "USD"))
        assertFalse(PremiumAccessPolicy.allows(paid, access.entitlement.value))
        assertFalse(PremiumAccessPolicy.allows(paid, EntitlementState.Pending(setOf("test.monthly"))))
        assertTrue(PremiumAccessPolicy.allows(paid, premium))
    }
    @Test fun viewModelExposesPlansSelectionAndRestoreWithoutAuth() = runTest {
        val play = FakePlay()
        val entitlement = com.example.kare.core.data.billing.PlayEntitlementRepository(play, com.example.kare.core.data.billing.LocalPlayEntitlementVerifier(specs), specs)
        val repo = com.example.kare.core.data.billing.DefaultBillingRepository(play, entitlement, specs, backgroundScope)
        val vm = KarePlusViewModel(repo, entitlement).also { store.put("plus", it) }
        runCurrent(); assertEquals(product.offerKey, vm.state.value.selected)
        play.owned = listOf(owned()); vm.restore(); runCurrent()
        assertTrue(vm.state.value.entitlement is EntitlementState.Premium)
        assertEquals(BillingAction.Restored, vm.state.value.billing.action)
    }
}
