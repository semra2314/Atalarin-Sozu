package com.example.kare

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.kare.feature.settings.*
import com.example.kare.feature.onboarding.OnboardingRoute
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.example.kare.navigation.KareApp

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val factory = (application as KareApplication).container.viewModelFactory
        setContent {
            val preferences: PreferencesViewModel = viewModel(factory = factory)
            PreferencesHost(preferences) { value ->
                if (value.onboardingCompleted) KareApp(factory, preferencesViewModel = preferences)
                else OnboardingRoute(viewModel(factory = factory), preferences, value)
            }
        }
    }
}
