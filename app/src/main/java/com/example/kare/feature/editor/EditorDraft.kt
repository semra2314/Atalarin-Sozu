package com.example.kare.feature.editor

import com.example.kare.core.model.*

typealias EditorCapability = com.example.kare.core.model.InstalledEditorCapability
typealias EditorCapabilities = com.example.kare.core.model.InstalledEditorCapabilities

data class EditorDraft(val content: WidgetContent) {
    val primary: WidgetContent.TextElement get() = content.texts.single()
    fun text(value: String) = primary { copy(text = value) }
    fun primary(change: WidgetContent.TextElement.() -> WidgetContent.TextElement) =
        copy(content = content.copy(texts = listOf(primary.change())))
    fun background(hex: String) = copy(content = content.copy(background = WidgetContent.Background.Color(listOf(hex))))
    fun validate(): EditorDraft {
        EditableContentValidation.validate(content)
        return this
    }
    companion object {
        fun from(widget: InstalledWidget) = EditorDraft(requireNotNull(widget.content)).validate()
        fun validHex(hex: String) = EditableContentValidation.validHex(hex)
    }
}
