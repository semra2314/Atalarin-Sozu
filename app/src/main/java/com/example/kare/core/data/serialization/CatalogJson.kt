package com.example.kare.core.data.serialization

import kotlinx.serialization.DeserializationStrategy
import kotlinx.serialization.SerializationStrategy
import kotlinx.serialization.json.Json

/**
 * Explicit JSON entry point. Unknown object fields are ignored for additive compatibility;
 * known fields retain strict types and unknown enum/associated-value cases are rejected.
 * Decoding errors are SerializationException; no malformed payload becomes an empty model.
 */
object CatalogJson {
    private val json = Json {
        isLenient = false
        allowSpecialFloatingPointValues = false
    }

    fun <T> decode(serializer: DeserializationStrategy<T>, value: String): T =
        json.decodeFromString(serializer, value)

    fun <T> encode(serializer: SerializationStrategy<T>, value: T): String =
        json.encodeToString(serializer, value)
}
