package com.example.kare.core.data.billing

import com.example.kare.core.billing.*
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** Client interpretation, NOT cryptographic/server purchase-token verification. */
class LocalPlayEntitlementVerifier(private val catalog: List<ProductSpec>, private val now: () -> Long = System::currentTimeMillis) : EntitlementVerifier {
    override suspend fun verify(purchase: PlayPurchase): List<EntitlementGrant> {
        if (purchase.status != PurchaseStatus.PURCHASED || purchase.token.isBlank()) return emptyList()
        return purchase.productIds.filter { id -> catalog.any { it.id == id } }.map {
            EntitlementGrant(it, verification = VerificationLevel.LOCAL_PLAY, autoRenewing = purchase.autoRenewing, checkedAtMillis = now())
        }
    }
}

class PlayEntitlementRepository(
    private val gateway: PlayBillingGateway, private val verifier: EntitlementVerifier,
    private val catalog: List<ProductSpec>,
) : EntitlementRepository {
    private val mutable = MutableStateFlow<EntitlementState>(EntitlementState.Unknown)
    override val entitlement = mutable.asStateFlow()
    private val mutex = Mutex()
    private val acknowledged = mutableSetOf<String>()
    fun interrupted() { mutable.value = EntitlementState.Unknown }
    fun loading() { mutable.value = EntitlementState.Loading }
    fun failed(error: BillingError) { mutable.value = EntitlementState.Error(error) }
    suspend fun reconcile(purchases: List<PlayPurchase>) = mutex.withLock {
        val grants = mutableListOf<EntitlementGrant>()
        val pending = mutableSetOf<String>()
        var failure: BillingError? = null
        purchases.distinctBy { it.token }.forEach { purchase ->
            val eligible = purchase.productIds.filter { id -> catalog.any { it.id == id } }
            if (eligible.isEmpty()) return@forEach
            if (purchase.status == PurchaseStatus.PENDING) { pending += eligible; return@forEach }
            if (purchase.status != PurchaseStatus.PURCHASED) return@forEach
            try {
                val verified = verifier.verify(purchase)
                if (verified.isEmpty()) { failure = BillingError.VERIFICATION_FAILED; return@forEach }
                if (!purchase.acknowledged && purchase.token !in acknowledged) {
                    try { gateway.acknowledge(purchase.token); acknowledged += purchase.token }
                    catch (e: Exception) {
                        if (e is CancellationException) throw e
                        failure = BillingError.ACKNOWLEDGEMENT_FAILED; return@forEach
                    }
                }
                grants += verified
            } catch (e: Exception) {
                if (e is CancellationException) throw e
                failure = BillingError.VERIFICATION_FAILED
            }
        }
        mutable.value = when {
            grants.isNotEmpty() -> EntitlementState.Premium(grants.distinctBy { it.productId })
            failure != null -> EntitlementState.Error(failure!!)
            pending.isNotEmpty() -> EntitlementState.Pending(pending)
            else -> EntitlementState.Free
        }
    }
}
