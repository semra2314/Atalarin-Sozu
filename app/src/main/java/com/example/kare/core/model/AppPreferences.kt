package com.example.kare.core.model

enum class AppLanguage(val tag: String) { SYSTEM(""), ENGLISH("en"), TURKISH("tr") }
enum class AppAppearance { SYSTEM, LIGHT, DARK }

data class AppPreferences(
    val onboardingCompleted: Boolean = false,
    val language: AppLanguage = AppLanguage.SYSTEM,
    val appearance: AppAppearance = AppAppearance.SYSTEM,
)
