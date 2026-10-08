package com.example.kare.core.data.serialization

import java.math.BigDecimal
import java.util.Collections
import java.util.UUID
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.buildClassSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.*

/** JSON-only adapters keep the Swift wire contract outside the domain model. */
abstract class JsonModelSerializer<T>(private val name: String) : KSerializer<T> {
    final override val descriptor = buildClassSerialDescriptor(name)

    abstract fun fromJson(value: JsonElement): T
    abstract fun toJson(value: T): JsonElement

    final override fun deserialize(decoder: Decoder): T {
        val input = decoder as? JsonDecoder ?: throw SerializationException("$name requires JSON")
        return try {
            fromJson(input.decodeJsonElement())
        } catch (error: SerializationException) {
            throw error
        } catch (error: IllegalArgumentException) {
            throw SerializationException("Invalid $name", error)
        }
    }

    final override fun serialize(encoder: Encoder, value: T) {
        val output = encoder as? JsonEncoder ?: throw SerializationException("$name requires JSON")
        output.encodeJsonElement(toJson(value))
    }
}

internal fun invalid(field: String): Nothing = throw SerializationException("Invalid or missing $field")
internal fun JsonElement.objectValue(): JsonObject = this as? JsonObject ?: invalid("object")
internal fun JsonElement.stringValue(): String =
    (this as? JsonPrimitive)?.takeIf { it.isString }?.content ?: invalid("string")

internal fun JsonElement.decimalValue(): BigDecimal {
    val primitive = this as? JsonPrimitive ?: invalid("number")
    if (primitive.isString || primitive.content.length > 128) invalid("number")
    val number = primitive.content.toBigDecimalOrNull() ?: invalid("number")
    // Bound expansion of hostile scientific notation before date/decimal conversions.
    if (number.scale() !in -1000..1000) invalid("number exponent")
    return number
}

internal fun JsonElement.intValue(): Int = try {
    decimalValue().intValueExact()
} catch (_: ArithmeticException) {
    invalid("integer")
}

internal fun JsonElement.doubleValue(): Double = decimalValue().toDouble().also {
    if (!it.isFinite()) invalid("finite number")
}

internal fun JsonElement.booleanValue(): Boolean =
    (this as? JsonPrimitive)?.takeUnless { it.isString }?.booleanOrNull ?: invalid("boolean")

internal fun JsonObject.required(key: String): JsonElement = optional(key) ?: invalid(key)
internal fun JsonObject.optional(key: String): JsonElement? = get(key)?.takeUnless { it is JsonNull }
internal fun JsonObject.string(key: String): String = required(key).stringValue()
internal fun JsonObject.string(key: String, default: String): String = optional(key)?.stringValue() ?: default
internal fun JsonObject.double(key: String, default: Double): Double = optional(key)?.doubleValue() ?: default
internal fun JsonObject.boolean(key: String, default: Boolean): Boolean = optional(key)?.booleanValue() ?: default
internal fun JsonObject.uuid(key: String): UUID = optional(key)?.stringValue()?.let { raw ->
    val value = try { UUID.fromString(raw) } catch (_: IllegalArgumentException) { invalid(key) }
    if (!value.toString().equals(raw, ignoreCase = true)) invalid(key)
    value
} ?: UUID.randomUUID()

internal fun <T> JsonElement.arrayValues(transform: (JsonElement) -> T): List<T> =
    frozen((this as? JsonArray ?: invalid("array")).map(transform))

internal fun <T> JsonObject.arrayOrEmpty(key: String, transform: (JsonElement) -> T): List<T> =
    optional(key)?.arrayValues(transform) ?: emptyList()

internal fun <T> frozen(values: List<T>): List<T> = Collections.unmodifiableList(ArrayList(values))
internal fun <T> rawEnum(value: String, values: List<T>, raw: (T) -> String): T =
    values.firstOrNull { raw(it) == value } ?: invalid("enum value: $value")

internal fun strings(values: List<String>): JsonArray = JsonArray(values.map(::JsonPrimitive))
internal fun number(value: Double): JsonPrimitive {
    if (!value.isFinite()) invalid("finite number")
    return JsonPrimitive(value)
}
internal fun JsonObjectBuilder.optional(key: String, value: String?) {
    if (value != null) put(key, value)
}

/** Raw numeric literals preserve decimal and nanosecond precision in JsonEncoder. */
@OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)
internal fun decimalToJson(value: BigDecimal): JsonPrimitive {
    val token = value.toString()
    if (token.length > 128 || value.scale() !in -1000..1000) invalid("number range")
    return JsonUnquotedLiteral(token)
}
