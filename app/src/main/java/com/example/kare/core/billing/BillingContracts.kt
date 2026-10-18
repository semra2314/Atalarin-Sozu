package com.example.kare.core.billing

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow

/** Short-lived platform host supplied only for the purchase sheet; never stored in state. */
interface PurchaseHost
interface PlayBillingGateway {
    val events: Flow<PurchaseEvent>
    suspend fun connect()
    suspend fun products(specs: List<ProductSpec>): List<BillingProduct>
    suspend fun purchases(): List<PlayPurchase>
    suspend fun launch(host: PurchaseHost, offerKey: String): PlayResult
    suspend fun acknowledge(token: String)
    fun close()
}
interface EntitlementVerifier {
    suspend fun verify(purchase: PlayPurchase): List<EntitlementGrant>
}
interface EntitlementRepository { val entitlement: StateFlow<EntitlementState> }
interface BillingRepository {
    val state: StateFlow<BillingState>
    suspend fun refresh(restore: Boolean = false)
    suspend fun purchase(host: PurchaseHost, offerKey: String)
}
