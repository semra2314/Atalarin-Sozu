package com.example.kare.core.billing

import com.example.kare.core.model.WidgetTemplate

enum class PlayProductType { SUBSCRIPTION, NON_CONSUMABLE }
data class ProductSpec(val id: String, val type: PlayProductType)

/** Set only after Play Console provisioning. App Store identifiers are not Play IDs. */
object BillingProductCatalog {
    val monthlySubscriptionId: String? = null
    val yearlySubscriptionId: String? = null
    val lifetimeProductId: String? = null
    val products: List<ProductSpec> = listOfNotNull(
        yearlySubscriptionId?.let { ProductSpec(it, PlayProductType.SUBSCRIPTION) },
        monthlySubscriptionId?.let { ProductSpec(it, PlayProductType.SUBSCRIPTION) },
        lifetimeProductId?.let { ProductSpec(it, PlayProductType.NON_CONSUMABLE) },
    )
}

data class PricingPhase(val formattedPrice: String, val period: String, val cycles: Int, val recurring: Boolean)
data class BillingProduct(
    val offerKey: String, val productId: String, val title: String, val description: String,
    val type: PlayProductType, val phases: List<PricingPhase>, val basePlanId: String? = null,
    val offerId: String? = null,
)
enum class PurchaseStatus { PURCHASED, PENDING, UNSPECIFIED }
class PlayPurchase(
    val productIds: List<String>, val token: String, val status: PurchaseStatus,
    val acknowledged: Boolean, val autoRenewing: Boolean, val purchasedAtMillis: Long,
) {
    override fun toString() = "PlayPurchase(status=$status, acknowledged=$acknowledged)"
}
enum class BillingError { NOT_CONFIGURED, UNAVAILABLE, PRODUCT_UNAVAILABLE, DISCONNECTED, NETWORK, PURCHASE_FAILED, ACKNOWLEDGEMENT_FAILED, RESTORE_FAILED, VERIFICATION_FAILED }
class BillingException(val error: BillingError) : Exception(error.name)
enum class PlayResult { OK, CANCELLED, ALREADY_OWNED }
sealed interface PurchaseEvent {
    data class Updated(val result: PlayResult) : PurchaseEvent
    data class Failed(val error: BillingError) : PurchaseEvent
}
enum class VerificationLevel { LOCAL_PLAY, SERVER }
data class EntitlementGrant(
    val productId: String, val source: String = "GOOGLE_PLAY", val verification: VerificationLevel,
    val autoRenewing: Boolean, val checkedAtMillis: Long,
)
sealed interface EntitlementState {
    data object Unknown : EntitlementState
    data object Loading : EntitlementState
    data object Free : EntitlementState
    data class Premium(val grants: List<EntitlementGrant>) : EntitlementState
    data class Pending(val productIds: Set<String>) : EntitlementState
    data class Error(val reason: BillingError) : EntitlementState
}
object PremiumAccessPolicy {
    fun allows(template: WidgetTemplate, state: EntitlementState): Boolean =
        template.price.isFree || state is EntitlementState.Premium && state.grants.isNotEmpty()
}
sealed interface BillingAction {
    data object Idle : BillingAction
    data object Purchasing : BillingAction
    data object Cancelled : BillingAction
    data object Restoring : BillingAction
    data object Restored : BillingAction
    data object NothingToRestore : BillingAction
    data object Completed : BillingAction
    data class Failed(val error: BillingError) : BillingAction
}
data class BillingState(
    val loading: Boolean = false, val products: List<BillingProduct> = emptyList(),
    val productError: BillingError? = null, val action: BillingAction = BillingAction.Idle,
)
