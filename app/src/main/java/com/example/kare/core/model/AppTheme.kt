package com.example.kare.core.model

/**
 * Application visual theme preference.
 */
enum class AppTheme {
    SYSTEM,
    LIGHT,
    DARK;

    companion object {
        fun fromString(value: String?): AppTheme {
            return entries.firstOrNull { it.name.equals(value, ignoreCase = true) } ?: SYSTEM
        }
    }
}
