package com.example.kare.core.presentation

import com.example.kare.core.model.WidgetTemplate

/** Current catalog-only policy. Library membership never represents a paid entitlement. */
enum class InstallationAccess { FREE, PURCHASE_UNAVAILABLE }

fun WidgetTemplate.installationAccess(): InstallationAccess =
    if (price.isFree) InstallationAccess.FREE else InstallationAccess.PURCHASE_UNAVAILABLE
