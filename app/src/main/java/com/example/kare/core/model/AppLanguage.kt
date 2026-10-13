package com.example.kare.core.model

/**
 * Application locale/language preference.
 */
enum class AppLanguage(val code: String) {
    SYSTEM("system"),
    EN("en"),
    TR("tr");

    companion object {
        fun fromString(value: String?): AppLanguage {
            return entries.firstOrNull { it.name.equals(value, ignoreCase = true) || it.code.equals(value, ignoreCase = true) } ?: SYSTEM
        }
    }
}
