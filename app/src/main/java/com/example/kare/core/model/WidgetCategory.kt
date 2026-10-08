package com.example.kare.core.model

/** Stable iOS catalog values. Persist [rawValue], never the enum name or ordinal. */
enum class WidgetCategory(val rawValue: String) {
    PRODUCTIVITY("productivity"),
    HEALTH("health"),
    FINANCE("finance"),
    WEATHER("weather"),
    PHOTOS("photos"),
    MINIMAL("minimal"),
    SOCIAL("social"),
    FUN("fun"),
}
