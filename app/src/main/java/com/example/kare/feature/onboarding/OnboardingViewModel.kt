package com.example.kare.feature.onboarding

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel

/** Language plus three product pages. Only transient page position uses saved state. */
class OnboardingViewModel(private val savedState: SavedStateHandle) : ViewModel() {
    val page = savedState.getStateFlow("onboarding_page", 0)
    fun next() { savedState["onboarding_page"] = (page.value + 1).coerceAtMost(3) }
    fun previous() { savedState["onboarding_page"] = (page.value - 1).coerceAtLeast(0) }
}
