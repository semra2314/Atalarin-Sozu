package com.example.kare.core.data.widget

import com.example.kare.core.model.*
import java.io.File
import kotlinx.serialization.json.*

/** Same atomic store, separate typed codec. Never decodes another widget type as Hush. */
class HushInstanceStore(directory: File) : AtomicWidgetStateStore<HushConfiguration>(directory, { encode(it) }, { decode(it) }) {
    companion object {
        fun encode(value: HushConfiguration) = buildJsonObject {
            put("version", 1)
            put("templateId", "t-hush")
            put("language", value.language.name.lowercase())
        }.toString()
        fun decode(value: String): HushConfiguration {
            val root = Json.parseToJsonElement(value).jsonObject
            require(root.getValue("version").jsonPrimitive.int == 1)
            require(root.getValue("templateId").jsonPrimitive.content == "t-hush")
            return HushConfiguration(HushLanguage.entries.first {
                it.name.lowercase() == root.getValue("language").jsonPrimitive.content
            })
        }
    }
}
