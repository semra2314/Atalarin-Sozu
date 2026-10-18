package com.example.kare.billing

import com.example.kare.core.billing.*
import com.example.kare.core.data.billing.*
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.test.*
import org.junit.Test
import org.junit.Assert.*

internal val specs = listOf(ProductSpec("test.monthly", PlayProductType.SUBSCRIPTION), ProductSpec("test.lifetime", PlayProductType.NON_CONSUMABLE))
internal val product = BillingProduct("monthly:base", "test.monthly", "Test plan", "Test description", PlayProductType.SUBSCRIPTION,
    listOf(PricingPhase("₺49,99", "P1M", 0, true)), "base")
internal fun owned(status: PurchaseStatus = PurchaseStatus.PURCHASED, ack: Boolean = true, id: String = "test.monthly", token: String = "obviously-fake-token", renewing: Boolean = true) =
    PlayPurchase(listOf(id), token, status, ack, renewing, 123)
internal class FakePlay : PlayBillingGateway {
    val updates = Channel<PurchaseEvent>(Channel.UNLIMITED)
    override val events = updates.receiveAsFlow()
    var available = listOf(product)
    var owned = emptyList<PlayPurchase>()
    var connectionError: BillingError? = null
    var queryError: BillingError? = null
    var queryDelay = 0L
    var productError: BillingError? = null
    var ackFails = false
    var launchResult = PlayResult.OK
    var launchError: BillingError? = null
    var acknowledged = mutableListOf<String>()
    var launches = 0
    var queries = 0
    override suspend fun connect() { connectionError?.let { throw BillingException(it) } }
    override suspend fun products(specs: List<ProductSpec>): List<BillingProduct> { productError?.let { throw BillingException(it) }; return available }
    override suspend fun purchases(): List<PlayPurchase> { queries++; delay(queryDelay); queryError?.let { throw BillingException(it) }; return owned }
    override suspend fun launch(host: PurchaseHost, offerKey: String): PlayResult { launches++; launchError?.let { throw BillingException(it) }; return launchResult }
    override suspend fun acknowledge(token: String) { if (ackFails) throw BillingException(BillingError.NETWORK); acknowledged += token }
    override fun close() {}
}
@OptIn(ExperimentalCoroutinesApi::class)
class BillingFoundationTest {
    private val host = object : PurchaseHost {}
    private fun TestScope.setup(gateway: FakePlay = FakePlay(), verifier: EntitlementVerifier = LocalPlayEntitlementVerifier(specs)): Triple<FakePlay, PlayEntitlementRepository, DefaultBillingRepository> {
        val entitlements = PlayEntitlementRepository(gateway, verifier, specs)
        return Triple(gateway, entitlements, DefaultBillingRepository(gateway, entitlements, specs, backgroundScope))
    }
    @Test fun productLoadingPreservesPlayPricingAndMissingProductsAreExplicit() = runTest {
        val (play, access, repo) = setup(); repo.refresh()
        assertEquals("₺49,99", repo.state.value.products.single().phases.single().formattedPrice)
        assertEquals(EntitlementState.Free, access.entitlement.value)
        play.available = emptyList(); repo.refresh(); assertEquals(BillingError.PRODUCT_UNAVAILABLE, repo.state.value.productError)
    }
    @Test fun unavailableConnectionNeverUnlocksOrBreaksRetry() = runTest {
        val (play, access, repo) = setup(); play.connectionError = BillingError.UNAVAILABLE; repo.refresh()
        assertEquals(EntitlementState.Error(BillingError.UNAVAILABLE), access.entitlement.value)
        assertFalse(repo.state.value.loading)
        play.connectionError = null; repo.refresh(); assertEquals(EntitlementState.Free, access.entitlement.value)
    }
    @Test fun acknowledgedPurchaseRestoresAndCancelledRenewalRemainsOwned() = runTest {
        val (play, access, repo) = setup(); play.owned = listOf(owned(renewing = false)); repo.refresh(true)
        val grant = (access.entitlement.value as EntitlementState.Premium).grants.single()
        assertFalse(grant.autoRenewing); assertEquals(VerificationLevel.LOCAL_PLAY, grant.verification)
        assertEquals(BillingAction.Restored, repo.state.value.action); assertTrue(play.acknowledged.isEmpty())
        play.owned = emptyList(); repo.refresh(true)
        assertEquals(EntitlementState.Free, access.entitlement.value); assertEquals(BillingAction.NothingToRestore, repo.state.value.action)
    }
    @Test fun acknowledgementIsVerifiedFirstDeduplicatedAndRetryable() = runTest {
        val (play, access, repo) = setup(); play.owned = listOf(owned(ack = false)); play.ackFails = true; repo.refresh()
        assertEquals(EntitlementState.Error(BillingError.ACKNOWLEDGEMENT_FAILED), access.entitlement.value)
        play.ackFails = false; repo.refresh(); repo.refresh()
        assertEquals(1, play.acknowledged.size); assertTrue(access.entitlement.value is EntitlementState.Premium)
    }
    @Test fun pendingIsNeverAcknowledgedOrGrantedAndLaterPurchaseCanComplete() = runTest {
        val (play, access, repo) = setup(); play.owned = listOf(owned(PurchaseStatus.PENDING, false)); repo.refresh(true)
        assertTrue(access.entitlement.value is EntitlementState.Pending); assertTrue(play.acknowledged.isEmpty())
        assertNotEquals(BillingAction.NothingToRestore, repo.state.value.action)
        play.owned = listOf(owned(ack = false)); play.updates.send(PurchaseEvent.Updated(PlayResult.OK)); runCurrent()
        assertTrue(access.entitlement.value is EntitlementState.Premium); assertEquals(BillingAction.Completed, repo.state.value.action)
    }
    @Test fun verifierRejectionDoesNotAcknowledgeOrUnlock() = runTest {
        val (play, access, repo) = setup(verifier = object : EntitlementVerifier { override suspend fun verify(purchase: PlayPurchase) = emptyList<EntitlementGrant>() })
        play.owned = listOf(owned(ack = false)); repo.refresh()
        assertEquals(EntitlementState.Error(BillingError.VERIFICATION_FAILED), access.entitlement.value); assertTrue(play.acknowledged.isEmpty())
    }
    @Test fun unknownProductsAndBlankTokensNeverUnlock() = runTest {
        val (play, access, repo) = setup(); play.owned = listOf(owned(id = "unknown")); repo.refresh()
        assertEquals(EntitlementState.Free, access.entitlement.value)
        play.owned = listOf(owned(token = "")); repo.refresh(); assertTrue(access.entitlement.value is EntitlementState.Error)
    }
    @Test fun launchingIsNotSuccessAndCancellationIsNotAnError() = runTest {
        val (play, access, repo) = setup(); repo.refresh(); repo.purchase(host, product.offerKey)
        assertEquals(BillingAction.Purchasing, repo.state.value.action); assertEquals(EntitlementState.Free, access.entitlement.value)
        repo.purchase(host, product.offerKey); assertEquals(1, play.launches)
        play.updates.send(PurchaseEvent.Updated(PlayResult.CANCELLED)); runCurrent()
        assertEquals(BillingAction.Cancelled, repo.state.value.action); assertEquals(EntitlementState.Free, access.entitlement.value)
    }
    @Test fun successAndDuplicateUpdatesRequeryFullOwnershipAndAcknowledgeOnce() = runTest {
        val (play, access, repo) = setup(); repo.refresh(); repo.purchase(host, product.offerKey)
        play.owned = listOf(owned(ack = false), owned(id = "test.lifetime", token = "fake-lifetime"))
        repeat(2) { play.updates.send(PurchaseEvent.Updated(PlayResult.OK)); runCurrent() }
        assertEquals(2, (access.entitlement.value as EntitlementState.Premium).grants.size)
        assertEquals(1, play.acknowledged.size); assertEquals(BillingAction.Completed, repo.state.value.action)
    }
    @Test fun alreadyOwnedQueriesAndErrorsAreRecoverable() = runTest {
        val (play, access, repo) = setup(); repo.refresh(); play.launchResult = PlayResult.ALREADY_OWNED; play.owned = listOf(owned())
        repo.purchase(host, product.offerKey); assertTrue(access.entitlement.value is EntitlementState.Premium)
        play.queryError = BillingError.NETWORK; repo.refresh(true)
        assertEquals(BillingAction.Failed(BillingError.RESTORE_FAILED), repo.state.value.action)
        assertTrue(access.entitlement.value is EntitlementState.Error)
        play.queryError = null; repo.refresh(true); assertTrue(access.entitlement.value is EntitlementState.Premium)
    }
    @Test fun processRecreationStartsUnknownAndMustQueryPlayAgain() = runTest {
        val (play, access, repo) = setup(); play.owned = listOf(owned()); repo.refresh()
        assertTrue(access.entitlement.value is EntitlementState.Premium)
        val fresh = PlayEntitlementRepository(play, LocalPlayEntitlementVerifier(specs), specs)
        assertEquals(EntitlementState.Unknown, fresh.entitlement.value)
        val next = DefaultBillingRepository(play, fresh, specs, backgroundScope)
        play.owned = emptyList(); next.refresh(); assertEquals(EntitlementState.Free, fresh.entitlement.value)
    }
    @Test fun productFailureDoesNotHideVerifiedOwnershipAndNoConfigDoesNotFakePlans() = runTest {
        val (play, access, repo) = setup(); play.owned = listOf(owned()); play.productError = BillingError.PRODUCT_UNAVAILABLE; repo.refresh()
        assertTrue(access.entitlement.value is EntitlementState.Premium)
        val emptyAccess = PlayEntitlementRepository(play, LocalPlayEntitlementVerifier(emptyList()), emptyList())
        val empty = DefaultBillingRepository(play, emptyAccess, emptyList(), backgroundScope); empty.refresh()
        assertEquals(BillingError.NOT_CONFIGURED, empty.state.value.productError); assertTrue(empty.state.value.products.isEmpty())
        assertEquals(EntitlementState.Free, emptyAccess.entitlement.value)
    }
    @Test fun purchaseFailureAndInvalidSelectionAreSemantic() = runTest {
        val (play, _, repo) = setup(); repo.refresh(); repo.purchase(host, "missing")
        assertEquals(0, play.launches); assertEquals(BillingAction.Failed(BillingError.PRODUCT_UNAVAILABLE), repo.state.value.action)
        play.launchError = BillingError.PURCHASE_FAILED; repo.purchase(host, product.offerKey)
        assertEquals(BillingAction.Failed(BillingError.PURCHASE_FAILED), repo.state.value.action)
    }
    @Test fun foregroundQueryResolvesLostPurchaseCallbackWithoutInventingSuccess() = runTest {
        val (play, access, repo) = setup(); repo.refresh(); repo.purchase(host, product.offerKey)
        repo.refresh()
        assertEquals(BillingAction.Idle, repo.state.value.action)
        assertEquals(EntitlementState.Free, access.entitlement.value)
        repo.purchase(host, product.offerKey); play.owned = listOf(owned()); repo.refresh()
        assertEquals(BillingAction.Completed, repo.state.value.action)
        assertTrue(access.entitlement.value is EntitlementState.Premium)
    }
    @Test fun leavingDuringRestoreDoesNotLeaveStaleProgressOnNextOpen() = runTest {
        val (play, access, repo) = setup(); play.queryDelay = 10_000
        val restore = launch { repo.refresh(true) }; runCurrent()
        assertEquals(BillingAction.Restoring, repo.state.value.action)
        restore.cancelAndJoin()
        assertEquals(BillingAction.Idle, repo.state.value.action)
        assertEquals(EntitlementState.Unknown, access.entitlement.value)
        assertFalse(repo.state.value.loading)
        play.queryDelay = 0; repo.refresh()
        assertEquals(EntitlementState.Free, access.entitlement.value)
        assertEquals(BillingAction.Idle, repo.state.value.action)
    }
    @Test fun verifierCancellationPropagatesAndPurchaseDebugStringHidesToken() = runTest {
        val (play, _, repo) = setup(verifier = object : EntitlementVerifier { override suspend fun verify(purchase: PlayPurchase): List<EntitlementGrant> = throw CancellationException() })
        play.owned = listOf(owned(ack = false))
        try { repo.refresh(); fail("Cancellation must propagate") } catch (_: CancellationException) {}
        assertTrue(play.acknowledged.isEmpty()); assertFalse(repo.state.value.loading)
        assertFalse(owned().toString().contains("obviously-fake-token"))
    }
}
