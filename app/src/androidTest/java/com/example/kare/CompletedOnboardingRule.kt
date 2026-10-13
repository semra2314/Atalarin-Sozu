package com.example.kare

import androidx.test.platform.app.InstrumentationRegistry
import kotlinx.coroutines.runBlocking
import org.junit.rules.ExternalResource

/** Navigation tests explicitly start as a returning user; no Library/widget data is cleared. */
class CompletedOnboardingRule : ExternalResource() {
    override fun before() {
        val app = InstrumentationRegistry.getInstrumentation().targetContext.applicationContext as KareApplication
        runBlocking { app.container.preferences.completeOnboarding() }
    }
}
