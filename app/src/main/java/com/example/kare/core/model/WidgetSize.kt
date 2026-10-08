package com.example.kare.core.model

/** Catalog sizes, not Android launcher cell dimensions or a platform support guarantee. */
enum class WidgetSize(val rawValue: String) {
    SMALL("small"),
    MEDIUM("medium"),
    LARGE("large"),
    ACCESSORY_CIRCULAR("accessoryCircular"),
    ACCESSORY_RECTANGULAR("accessoryRectangular"),
}
