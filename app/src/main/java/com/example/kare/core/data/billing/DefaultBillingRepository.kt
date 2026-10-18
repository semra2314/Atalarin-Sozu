package com.example.kare.core.data.billing

import com.example.kare.core.billing.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

class DefaultBillingRepository(
    private val gateway: PlayBillingGateway, private val entitlements: PlayEntitlementRepository,
    private val catalog: List<ProductSpec>, scope: CoroutineScope,
) : BillingRepository {
    private val mutable = MutableStateFlow(BillingState())
    override val state = mutable.asStateFlow()
    private val mutex = Mutex()
    init {
        scope.launch {
            gateway.events.collect { event ->
                when (event) {
                    is PurchaseEvent.Failed -> mutable.update { it.copy(action = BillingAction.Failed(event.error)) }
                    is PurchaseEvent.Updated -> if (event.result == PlayResult.CANCELLED) {
                        mutable.update { it.copy(action = BillingAction.Cancelled) }
                    } else {
                        // A callback is a delta, so always query the complete active ownership set.
                        refresh()
                        mutable.update { it.copy(action = when (val value = entitlements.entitlement.value) {
                            is EntitlementState.Premium -> BillingAction.Completed
                            is EntitlementState.Error -> BillingAction.Failed(value.reason)
                            else -> BillingAction.Idle
                        }) }
                    }
                }
            }
        }
    }
    override suspend fun refresh(restore: Boolean) = mutex.withLock {
        mutable.update { it.copy(loading = true, action = if (restore) BillingAction.Restoring else it.action) }
        entitlements.loading()
        try {
            gateway.connect()
            entitlements.reconcile(gateway.purchases())
            try {
                val products = if (catalog.isEmpty()) emptyList() else gateway.products(catalog)
                mutable.update { it.copy(products = products, productError = when {
                    catalog.isEmpty() -> BillingError.NOT_CONFIGURED
                    products.isEmpty() -> BillingError.PRODUCT_UNAVAILABLE
                    else -> null
                }) }
            } catch (e: Exception) {
                if (e is CancellationException) throw e
                mutable.update { it.copy(products = emptyList(), productError = semantic(e)) }
            }
            // Foreground re-query also resolves a flow whose callback was lost during recreation.
            if (!restore && mutable.value.action == BillingAction.Purchasing) mutable.update {
                it.copy(action = when (val value = entitlements.entitlement.value) {
                    is EntitlementState.Premium -> BillingAction.Completed
                    is EntitlementState.Error -> BillingAction.Failed(value.reason)
                    else -> BillingAction.Idle
                })
            }
            if (restore) mutable.update { it.copy(action = when (val value = entitlements.entitlement.value) {
                is EntitlementState.Premium -> BillingAction.Restored
                is EntitlementState.Error -> BillingAction.Failed(value.reason)
                is EntitlementState.Pending -> BillingAction.Idle
                else -> BillingAction.NothingToRestore
            }) }
        } catch (e: Exception) {
            if (e is CancellationException) {
                entitlements.interrupted()
                mutable.update { it.copy(action = BillingAction.Idle) }
                throw e
            }
            val error = semantic(e)
            entitlements.failed(error)
            mutable.update { it.copy(products = emptyList(), productError = error,
                action = if (restore) BillingAction.Failed(BillingError.RESTORE_FAILED)
                    else if (it.action == BillingAction.Purchasing) BillingAction.Failed(error) else it.action) }
        } finally { mutable.update { it.copy(loading = false) } }
    }
    override suspend fun purchase(host: PurchaseHost, offerKey: String) {
        if (state.value.loading || state.value.action == BillingAction.Purchasing) return
        if (state.value.products.none { it.offerKey == offerKey }) {
            mutable.update { it.copy(action = BillingAction.Failed(BillingError.PRODUCT_UNAVAILABLE)) }; return
        }
        mutable.update { it.copy(action = BillingAction.Purchasing) }
        try {
            when (gateway.launch(host, offerKey)) {
                PlayResult.OK -> Unit // Only the update/query can establish ownership.
                PlayResult.CANCELLED -> mutable.update { it.copy(action = BillingAction.Cancelled) }
                PlayResult.ALREADY_OWNED -> { refresh(restore = true) }
            }
        } catch (e: Exception) {
            if (e is CancellationException) { mutable.update { it.copy(action = BillingAction.Idle) }; throw e }
            mutable.update { it.copy(action = BillingAction.Failed(semantic(e))) }
        }
    }
    private fun semantic(error: Exception) = (error as? BillingException)?.error ?: BillingError.UNAVAILABLE
}
