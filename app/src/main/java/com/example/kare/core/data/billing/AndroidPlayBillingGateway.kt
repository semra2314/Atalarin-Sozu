package com.example.kare.core.data.billing

import android.app.Activity
import android.content.Context
import android.util.Log
import com.android.billingclient.api.*
import com.example.kare.core.billing.*
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class ActivityPurchaseHost(val activity: Activity) : PurchaseHost

/** The only layer that imports the Google Play SDK. Tokens never enter logs. */
class AndroidPlayBillingGateway(context: Context) : PlayBillingGateway {
    private val updates = Channel<PurchaseEvent>(Channel.UNLIMITED)
    override val events = updates.receiveAsFlow()
    private val connection = Mutex()
    private data class NativeOffer(val details: ProductDetails, val token: String?, val model: BillingProduct)
    private val offers = mutableMapOf<String, NativeOffer>()
    private val client = BillingClient.newBuilder(context.applicationContext)
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().enablePrepaidPlans().build())
        .enableAutoServiceReconnection()
        .setListener { result, _ ->
            updates.trySend(when (result.responseCode) {
                BillingClient.BillingResponseCode.OK -> PurchaseEvent.Updated(PlayResult.OK)
                BillingClient.BillingResponseCode.USER_CANCELED -> PurchaseEvent.Updated(PlayResult.CANCELLED)
                BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED -> PurchaseEvent.Updated(PlayResult.ALREADY_OWNED)
                else -> PurchaseEvent.Failed(error(result))
            })
        }.build()

    override suspend fun connect() = withContext(Dispatchers.Main.immediate) {
        connection.withLock {
            if (!client.isReady) bounded<Unit> { continuation ->
                client.startConnection(object : BillingClientStateListener {
                    override fun onBillingSetupFinished(result: BillingResult) = complete(continuation, result, Unit)
                    override fun onBillingServiceDisconnected() { /* Reconnect on the next API call, never a retry loop. */ }
                })
            }
        }
    }
    override suspend fun products(specs: List<ProductSpec>): List<BillingProduct> = withContext(Dispatchers.Main.immediate) {
        if (specs.isEmpty()) return@withContext emptyList()
        val details = specs.groupBy { it.type }.values.flatMap { group ->
            bounded<List<ProductDetails>> { c ->
            client.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(group.map {
                QueryProductDetailsParams.Product.newBuilder().setProductId(it.id).setProductType(it.type.native()).build()
            }).build()) { result, response -> complete(c, result, response.productDetailsList) }
            }
        }
        val mapped = details.flatMap { detail ->
            if (detail.productType == BillingClient.ProductType.SUBS) {
                detail.subscriptionOfferDetails.orEmpty().filter { it.installmentPlanDetails == null }.map { offer ->
                    val key = "${detail.productId}:${offer.basePlanId}:${offer.offerId.orEmpty()}"
                    val model = BillingProduct(key, detail.productId, detail.name, detail.description,
                        PlayProductType.SUBSCRIPTION, offer.pricingPhases.pricingPhaseList.map {
                            PricingPhase(it.formattedPrice, it.billingPeriod, it.billingCycleCount,
                                it.recurrenceMode == ProductDetails.RecurrenceMode.INFINITE_RECURRING)
                        }, offer.basePlanId, offer.offerId)
                    NativeOffer(detail, offer.offerToken, model)
                }
            } else detail.oneTimePurchaseOfferDetailsList.orEmpty()
                .filter { it.rentalDetails == null && it.preorderDetails == null }.map { offer ->
                    val key = "${detail.productId}:${offer.purchaseOptionId}:${offer.offerId.orEmpty()}"
                    NativeOffer(detail, offer.offerToken, BillingProduct(key, detail.productId, detail.name,
                        detail.description, PlayProductType.NON_CONSUMABLE,
                        listOf(PricingPhase(offer.formattedPrice, "", 0, false))))
                }
        }
        // Refresh only the queried products; retain other displayed offers after a cancelled flow.
        val queriedIds = specs.map { it.id }.toSet()
        offers.entries.removeAll { it.value.model.productId in queriedIds }
        mapped.forEach { offers[it.model.offerKey] = it }
        mapped.map { it.model }
    }
    override suspend fun purchases(): List<PlayPurchase> = withContext(Dispatchers.Main.immediate) {
        listOf(BillingClient.ProductType.SUBS, BillingClient.ProductType.INAPP).flatMap { type ->
            bounded<List<Purchase>> { c ->
                client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(type).build()) { result, values -> complete(c, result, values) }
            }.map { purchase ->
                PlayPurchase(purchase.products.toList(), purchase.purchaseToken, when {
                    purchase.isSuspended -> PurchaseStatus.UNSPECIFIED
                    purchase.purchaseState == Purchase.PurchaseState.PURCHASED -> PurchaseStatus.PURCHASED
                    purchase.purchaseState == Purchase.PurchaseState.PENDING -> PurchaseStatus.PENDING
                    else -> PurchaseStatus.UNSPECIFIED
                }, purchase.isAcknowledged, purchase.isAutoRenewing, purchase.purchaseTime)
            }
        }
    }
    override suspend fun launch(host: PurchaseHost, offerKey: String): PlayResult = withContext(Dispatchers.Main.immediate) {
        val activity = (host as? ActivityPurchaseHost)?.activity ?: throw BillingException(BillingError.UNAVAILABLE)
        if (activity.isFinishing || activity.isDestroyed) throw BillingException(BillingError.UNAVAILABLE)
        val previous = offers[offerKey] ?: throw BillingException(BillingError.PRODUCT_UNAVAILABLE)
        connect()
        products(listOf(ProductSpec(previous.model.productId, previous.model.type)))
        val offer = offers[offerKey]?.takeIf { it.model == previous.model } ?: throw BillingException(BillingError.PRODUCT_UNAVAILABLE)
        val details = BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(offer.details)
        offer.token?.let { details.setOfferToken(it) }
        val result = client.launchBillingFlow(activity, BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(details.build())).build())
        when(result.responseCode) {
            BillingClient.BillingResponseCode.OK -> PlayResult.OK
            BillingClient.BillingResponseCode.USER_CANCELED -> PlayResult.CANCELLED
            BillingClient.BillingResponseCode.ITEM_ALREADY_OWNED -> PlayResult.ALREADY_OWNED
            else -> throw BillingException(error(result))
        }
    }
    override suspend fun acknowledge(token: String) = withContext(Dispatchers.Main.immediate) {
        bounded<Unit> { c -> client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(token).build()) { complete(c, it, Unit) } }
    }
    override fun close() { client.endConnection(); updates.close(); offers.clear() }
    private fun PlayProductType.native() = if (this == PlayProductType.SUBSCRIPTION) BillingClient.ProductType.SUBS else BillingClient.ProductType.INAPP
    private suspend fun <T> bounded(block: (CancellableContinuation<T>) -> Unit): T =
        withTimeoutOrNull(20_000) { suspendCancellableCoroutine(block) } ?: throw BillingException(BillingError.DISCONNECTED)
    private fun <T> complete(c: CancellableContinuation<T>, result: BillingResult, value: T) {
        if (!c.isActive) return
        if (result.responseCode == BillingClient.BillingResponseCode.OK) c.resume(value)
        else c.resumeWithException(BillingException(error(result)))
    }
    private fun error(result: BillingResult): BillingError {
        // Response codes provide useful diagnostics without logging purchases/debug payloads.
        Log.w("KareBilling", "Play response code=${result.responseCode}")
        return when(result.responseCode) {
            BillingClient.BillingResponseCode.BILLING_UNAVAILABLE, BillingClient.BillingResponseCode.FEATURE_NOT_SUPPORTED -> BillingError.UNAVAILABLE
            BillingClient.BillingResponseCode.SERVICE_DISCONNECTED -> BillingError.DISCONNECTED
            BillingClient.BillingResponseCode.NETWORK_ERROR, BillingClient.BillingResponseCode.SERVICE_UNAVAILABLE -> BillingError.NETWORK
            BillingClient.BillingResponseCode.ITEM_UNAVAILABLE -> BillingError.PRODUCT_UNAVAILABLE
            else -> BillingError.PURCHASE_FAILED
        }
    }
}
