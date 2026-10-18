package com.example.kare.feature.plus

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.kare.core.billing.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class KarePlusUiState(val billing: BillingState = BillingState(), val entitlement: EntitlementState = EntitlementState.Unknown, val selected: String? = null)
class KarePlusViewModel(private val billing: BillingRepository, entitlements: EntitlementRepository) : ViewModel() {
    private val selected = MutableStateFlow<String?>(null)
    val state = combine(billing.state, entitlements.entitlement, selected) { value, access, choice ->
        KarePlusUiState(value, access, choice?.takeIf { id -> value.products.any { it.offerKey == id } } ?: value.products.firstOrNull()?.offerKey)
    }.stateIn(viewModelScope, SharingStarted.Eagerly, KarePlusUiState())
    init { reload() }
    fun select(key: String) { selected.value = key }
    fun reload() { viewModelScope.launch { billing.refresh() } }
    fun restore() { if (!state.value.billing.loading) viewModelScope.launch { billing.refresh(restore = true) } }
    fun purchase(host: PurchaseHost) { state.value.selected?.let { key -> viewModelScope.launch { billing.purchase(host, key) } } }
}
