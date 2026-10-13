package com.example.kare.core.data.widget

import com.example.kare.core.model.*
import java.time.Instant
import kotlinx.serialization.json.*

class ProverbSource {
    // Loaded only by repository calls on Dispatchers.IO, including widget rendering.
    val entries: List<Proverb> by lazy {
        val source = checkNotNull(javaClass.getResourceAsStream("/proverb/proverbs-v1.json"))
            .bufferedReader().use { it.readText() }
        Json.parseToJsonElement(source).jsonArray.map { element ->
            val o = element.jsonObject
            Proverb(o.getValue("id").jsonPrimitive.int, o.getValue("isProverb").jsonPrimitive.boolean,
                o.getValue("title").jsonPrimitive.content, o.getValue("meaning").jsonPrimitive.content,
                o.getValue("example").jsonPrimitive.content)
        }.also { rows ->
            require(rows.isNotEmpty() && rows.map { it.id }.distinct().size == rows.size)
            require(rows.all { it.title.isNotBlank() && it.meaning.isNotBlank() })
        }
    }
    fun entry(time: Instant, selection: ProverbSelection): Proverb {
        val choices = when (selection) {
            ProverbSelection.ALL -> entries
            ProverbSelection.PROVERBS -> entries.filter { it.isProverb }
            ProverbSelection.IDIOMS -> entries.filterNot { it.isProverb }
        }
        // Match Swift's integer division for the source's Unix epoch four-hour slots.
        val slot = time.epochSecond / (4 * 3600)
        return choices[Math.floorMod(slot, choices.size.toLong()).toInt()]
    }
}
