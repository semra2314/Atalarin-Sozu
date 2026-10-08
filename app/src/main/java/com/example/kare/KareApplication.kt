package com.example.kare

import android.app.Application
import com.example.kare.app.AppContainer

class KareApplication : Application() {
    val container: AppContainer by lazy { AppContainer(this) }
}
