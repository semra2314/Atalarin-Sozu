package com.example.kare.core.data.widget

import com.example.kare.core.model.*
import java.io.File
import kotlinx.serialization.json.*

/** Same atomic store, separate typed codec. Never decodes another widget type as Daily. */
class DailyInstanceStore(directory: File) : AtomicWidgetStateStore<DailyConfiguration>(directory, { encode(it) }, { decode(it) }) {
    companion object {
        fun encode(value: DailyConfiguration) = buildJsonObject {
            put("version", 1)
            put("templateId", "t-daily")
            put("source", value.source.name.lowercase())
        }.toString()
        fun decode(value: String): DailyConfiguration {
            val root = Json.parseToJsonElement(value).jsonObject
            require(root.getValue("version").jsonPrimitive.int == 1)
            require(root.getValue("templateId").jsonPrimitive.content == "t-daily")
            return DailyConfiguration(DailySource.entries.first {
                it.name.lowercase() == root.getValue("source").jsonPrimitive.content
            })
        }
    }
}
