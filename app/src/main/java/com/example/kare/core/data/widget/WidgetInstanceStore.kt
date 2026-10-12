package com.example.kare.core.data.widget

import com.example.kare.core.model.*
import java.io.File
import kotlinx.serialization.json.*

/** Preserves the original version-1 Proverb format and file location. */
class WidgetInstanceStore(directory: File) : AtomicWidgetStateStore<WidgetInstance>(directory, { encode(it) }, { decode(it) }) {
    companion object {
        fun encode(value: WidgetInstance): String {
            require(value.templateId == "t-proverb")
            return buildJsonObject {
                put("version", 1); put("templateId", value.templateId)
                put("selection", value.selection.name.lowercase())
            }.toString()
        }
        fun decode(json: String): WidgetInstance {
            val root = Json.parseToJsonElement(json).jsonObject
            require(root.getValue("version").jsonPrimitive.int == 1)
            require(root.getValue("templateId").jsonPrimitive.content == "t-proverb")
            val mode = ProverbSelection.entries.first { it.name.lowercase() == root.getValue("selection").jsonPrimitive.content }
            return WidgetInstance(selection = mode)
        }
    }
}
