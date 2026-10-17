package com.example.kare.core.model

import com.example.kare.core.repository.RepositoryException

/** Payload capability, not a second launcher registry or an entitlement grant. */
enum class InstalledEditorCapability { GENERIC, LIMITED, UNSUPPORTED }
object InstalledEditorCapabilities {
    fun forWidget(widget: InstalledWidget): InstalledEditorCapability {
        if (!widget.isCustomizable || LauncherWidgetType.forTemplate(widget.templateId) != null) return InstalledEditorCapability.UNSUPPORTED
        val c = widget.content ?: return InstalledEditorCapability.UNSUPPORTED
        if (c.photos.isNotEmpty() || c.stickers.isNotEmpty() || c.texts.size != 1 ||
            c.background !is WidgetContent.Background.Color || c.textScrim ||
            c.texts.single().hasBackground || c.texts.single().rotation != 0.0) return InstalledEditorCapability.UNSUPPORTED
        return InstalledEditorCapability.LIMITED // One existing layer; position and advanced controls are deliberately fixed.
    }
}

object EditableContentValidation {
    fun validHex(hex: String) = Regex("[0-9a-fA-F]{6}").matches(hex)
    fun validate(content: WidgetContent) {
        val t = content.texts.single()
        val colors = (content.background as WidgetContent.Background.Color).hexes
        if (colors.isEmpty() || colors.any { !validHex(it) } || !validHex(t.colorHex) ||
            !t.fontSize.isFinite() || t.fontSize !in 8.0..60.0 ||
            !t.x.isFinite() || t.x !in 0.0..1.0 || !t.y.isFinite() || t.y !in 0.0..1.0 ||
            !t.widthFraction.isFinite() || t.widthFraction !in 0.01..1.0 ||
            !t.lineSpacing.isFinite() || t.lineSpacing < 0) throw RepositoryException.InvalidData("editor payload")
    }
}
