package com.example.kare

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.example.kare.core.design.KareTheme
import com.example.kare.navigation.KareApp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val factory = (application as KareApplication).container.viewModelFactory
        setContent { KareTheme { KareApp(factory) } }
    }
}
