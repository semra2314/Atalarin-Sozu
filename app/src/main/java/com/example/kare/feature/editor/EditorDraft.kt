package com.example.kare.feature.editor

import com.example.kare.core.model.*
import com.example.kare.core.repository.RepositoryException

/** Payload capability, not a second launcher registry or an entitlement grant. */
enum class EditorCapability { GENERIC, LIMITED, UNSUPPORTED }
object EditorCapabilities {
    fun forWidget(widget: InstalledWidget): EditorCapability {
        if (!widget.isCustomizable || LauncherWidgetType.forTemplate(widget.templateId) != null) return EditorCapability.UNSUPPORTED
        val c = widget.content ?: return EditorCapability.UNSUPPORTED
        if (c.photos.isNotEmpty() || c.stickers.isNotEmpty() || c.texts.size != 1 ||
            c.background !is WidgetContent.Background.Color || c.textScrim ||
            c.texts.single().hasBackground || c.texts.single().rotation != 0.0) return EditorCapability.UNSUPPORTED
        return EditorCapability.LIMITED // One existing layer; position and advanced controls are deliberately fixed.
    }
}

data class EditorDraft(val content: WidgetContent) {
    val primary: WidgetContent.TextElement get() = content.texts.single()
    fun text(value: String) = primary { copy(text = value) }
    fun primary(change: WidgetContent.TextElement.() -> WidgetContent.TextElement) =
        copy(content = content.copy(texts = listOf(primary.change())))
    fun background(hex: String) = copy(content = content.copy(background = WidgetContent.Background.Color(listOf(hex))))
    fun validate(): EditorDraft {
        val t = primary
        val colors = (content.background as WidgetContent.Background.Color).hexes
        if (colors.isEmpty() || colors.any { !validHex(it) } || !validHex(t.colorHex) ||
            !t.fontSize.isFinite() || t.fontSize !in 8.0..60.0 ||
            !t.x.isFinite() || t.x !in 0.0..1.0 || !t.y.isFinite() || t.y !in 0.0..1.0 ||
            !t.widthFraction.isFinite() || t.widthFraction !in 0.01..1.0 ||
            !t.lineSpacing.isFinite() || t.lineSpacing < 0) throw RepositoryException.InvalidData("editor payload")
        return this
    }
    companion object {
        fun from(widget: InstalledWidget) = EditorDraft(requireNotNull(widget.content)).validate()
        fun validHex(hex: String) = Regex("[0-9a-fA-F]{6}").matches(hex)
    }
}
