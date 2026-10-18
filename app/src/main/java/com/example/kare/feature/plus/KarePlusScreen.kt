package com.example.kare.feature.plus

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.*
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.kare.R
import com.example.kare.core.billing.*
import com.example.kare.core.data.billing.ActivityPurchaseHost
import com.example.kare.core.design.*
import com.example.kare.core.ui.ScreenTitle

@Composable
fun KarePlusRoute(viewModel: KarePlusViewModel, onBack: () -> Unit) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    KarePlusContent(state, onBack, viewModel::select, {
        context.activity()?.let { viewModel.purchase(ActivityPurchaseHost(it)) }
    }, viewModel::restore, viewModel::reload)
}
private fun Context.activity(): Activity? = when(this) {
    is Activity -> this
    is ContextWrapper -> baseContext.activity()
    else -> null
}

@Composable
fun KarePlusContent(state: KarePlusUiState, onBack: () -> Unit, onSelect: (String) -> Unit,
    onPurchase: () -> Unit, onRestore: () -> Unit, onRetry: () -> Unit) {
    val busy = state.billing.loading || state.billing.action == BillingAction.Purchasing
    val active = state.entitlement is EntitlementState.Premium
    Column(Modifier.fillMaxSize().safeDrawingPadding().widthIn(max = KareLayout.readableWidth)
        .verticalScroll(rememberScrollState()).padding(KareSpacing.lg).testTag("kare-plus"),
        verticalArrangement = Arrangement.spacedBy(KareSpacing.md)) {
        TextButton(onClick = onBack) { Text(stringResource(R.string.action_back)) }
        ScreenTitle(stringResource(R.string.section_plus_title))
        Text(stringResource(R.string.plus_benefits))
        Text(stringResource(R.string.plus_platform_scope), style = MaterialTheme.typography.bodySmall)
        Text(stringResource(when(state.entitlement) {
            EntitlementState.Unknown, EntitlementState.Loading -> R.string.plus_checking
            EntitlementState.Free -> R.string.plus_free
            is EntitlementState.Premium -> R.string.plus_active
            is EntitlementState.Pending -> R.string.plus_pending
            is EntitlementState.Error -> R.string.plus_access_unavailable
        }), Modifier.testTag("plus-entitlement").semantics { liveRegion = LiveRegionMode.Polite })
        if (state.billing.loading) CircularProgressIndicator()
        state.billing.productError?.let { BillingErrorText(it) }
        Column(Modifier.selectableGroup(), verticalArrangement = Arrangement.spacedBy(KareSpacing.sm)) {
            state.billing.products.forEach { product ->
                FilterChip(selected = state.selected == product.offerKey, enabled = !busy && !active,
                    onClick = { onSelect(product.offerKey) }, modifier = Modifier.fillMaxWidth().heightIn(min = 48.dp),
                    label = { Column(Modifier.padding(vertical = KareSpacing.sm)) {
                        Text(product.title)
                        if (product.description.isNotBlank()) Text(product.description)
                        product.phases.forEach { phase ->
                            val period = when(phase.period) {
                                "P1M" -> stringResource(R.string.plus_month)
                                "P1Y" -> stringResource(R.string.plus_year)
                                "P1W" -> stringResource(R.string.plus_week)
                                else -> phase.period
                            }
                            Text(when {
                                product.type == PlayProductType.NON_CONSUMABLE -> stringResource(R.string.plus_once_price, phase.formattedPrice)
                                phase.recurring -> stringResource(R.string.plus_recurring_price, phase.formattedPrice, period)
                                phase.cycles > 0 -> stringResource(R.string.plus_finite_price, phase.formattedPrice, period, phase.cycles)
                                else -> stringResource(R.string.plus_prepaid_price, phase.formattedPrice, period)
                            })
                        }
                    } })
            }
        }
        if (!active) Button(onClick = onPurchase, enabled = !busy && state.selected != null && state.entitlement !is EntitlementState.Pending,
            modifier = Modifier.fillMaxWidth().heightIn(min = 48.dp).testTag("plus-purchase")) { Text(stringResource(R.string.plus_purchase)) }
        TextButton(onClick = onRestore, enabled = !busy, modifier = Modifier.heightIn(min = 48.dp).testTag("plus-restore")) {
            Text(stringResource(R.string.plus_restore))
        }
        TextButton(onClick = onRetry, enabled = !busy, modifier = Modifier.heightIn(min = 48.dp)) { Text(stringResource(R.string.action_retry)) }
        when(val action = state.billing.action) {
            is BillingAction.Failed -> BillingErrorText(action.error)
            BillingAction.Idle -> Unit
            else -> Text(stringResource(when(action) {
                BillingAction.Purchasing -> R.string.plus_purchasing
                BillingAction.Cancelled -> R.string.plus_cancelled
                BillingAction.Restoring -> R.string.plus_restoring
                BillingAction.Restored -> R.string.plus_restored
                BillingAction.NothingToRestore -> R.string.plus_nothing
                BillingAction.Completed -> R.string.plus_success
                else -> R.string.plus_checking
            }), Modifier.semantics { liveRegion = LiveRegionMode.Polite })
        }
        Text(stringResource(R.string.plus_terms), style = MaterialTheme.typography.bodySmall)
        Text(stringResource(R.string.plus_manage), style = MaterialTheme.typography.bodySmall)
    }
}
@Composable private fun BillingErrorText(error: BillingError) {
    Text(stringResource(when(error) {
        BillingError.NOT_CONFIGURED -> R.string.plus_not_configured
        BillingError.UNAVAILABLE -> R.string.plus_unavailable
        BillingError.PRODUCT_UNAVAILABLE -> R.string.plus_product_missing
        BillingError.DISCONNECTED, BillingError.NETWORK -> R.string.plus_network
        BillingError.PURCHASE_FAILED -> R.string.plus_purchase_failed
        BillingError.ACKNOWLEDGEMENT_FAILED -> R.string.plus_ack_failed
        BillingError.RESTORE_FAILED -> R.string.plus_restore_failed
        BillingError.VERIFICATION_FAILED -> R.string.plus_verification_failed
    }), color = MaterialTheme.colorScheme.error, modifier = Modifier.semantics { liveRegion = LiveRegionMode.Polite })
}
