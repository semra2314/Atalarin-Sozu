package com.example.kare.core.data.serialization

import com.example.kare.core.model.ImageData
import com.example.kare.core.model.WidgetContent
import com.example.kare.core.model.WidgetTemplate
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.DateTimeException
import java.time.Instant
import java.util.Base64
import kotlinx.serialization.json.*

internal fun instantFromJson(value: JsonElement): Instant {
    val seconds = value.decimalValue().add(BigDecimal("978307200"))
    val whole = seconds.setScale(0, RoundingMode.FLOOR)
    return try {
        val nanos = seconds.subtract(whole).movePointRight(9).setScale(0, RoundingMode.HALF_EVEN)
        Instant.ofEpochSecond(whole.longValueExact(), nanos.longValueExact())
    } catch (_: ArithmeticException) {
        invalid("Date range")
    } catch (_: DateTimeException) {
        invalid("Date range")
    }
}

internal fun instantToJson(value: Instant): JsonPrimitive = decimalToJson(
    BigDecimal.valueOf(value.epochSecond).subtract(BigDecimal("978307200"))
        .add(BigDecimal.valueOf(value.nano.toLong(), 9)).stripTrailingZeros(),
)

internal fun imageFromJson(value: JsonElement): ImageData = try {
    val encoded = value.stringValue()
    val bytes = Base64.getDecoder().decode(encoded)
    // Swift JSONEncoder writes standard padded base64, not URL-safe or partial values.
    if (Base64.getEncoder().encodeToString(bytes) != encoded) invalid("base64")
    ImageData(bytes)
} catch (_: IllegalArgumentException) {
    invalid("base64")
}

internal fun imageToJson(value: ImageData): JsonPrimitive =
    JsonPrimitive(Base64.getEncoder().encodeToString(value.toByteArray()))

/** Swift's synthesized associated-value shape, without a Kotlin class discriminator. */
object WidgetPriceSerializer : JsonModelSerializer<WidgetTemplate.Price>("WidgetTemplate.Price") {
    override fun fromJson(value: JsonElement): WidgetTemplate.Price {
        val cases = value.objectValue()
        if (cases.size != 1) invalid("Price case")
        val entry = cases.entries.single()
        return when (entry.key) {
                "free" -> {
                    entry.value.objectValue()
                    WidgetTemplate.Price.Free
                }
                "paid" -> entry.value.objectValue().let {
                    WidgetTemplate.Price.Paid(it.required("amount").decimalValue(), it.string("currencyCode"))
                }
                else -> invalid("Price case: ${entry.key}")
        }
    }

    override fun toJson(value: WidgetTemplate.Price): JsonElement = buildJsonObject {
        when (value) {
            WidgetTemplate.Price.Free -> put("free", buildJsonObject {})
            is WidgetTemplate.Price.Paid -> put("paid", buildJsonObject {
                // Emit the decimal token directly; JsonPrimitive(Number) can round through Double.
                put("amount", decimalToJson(value.amount))
                put("currencyCode", value.currencyCode)
            })
        }
    }
}

object WidgetBackgroundSerializer : JsonModelSerializer<WidgetContent.Background>("WidgetContent.Background") {
    override fun fromJson(value: JsonElement): WidgetContent.Background {
        val cases = value.objectValue()
        if (cases.size != 1) invalid("Background case")
        val (kind, body) = cases.entries.single()
        val payload = body.objectValue().required("_0")
        return when (kind) {
            "color" -> WidgetContent.Background.Color(payload.arrayValues { it.stringValue() })
            "photo" -> WidgetContent.Background.Photo(imageFromJson(payload))
            else -> invalid("Background case: $kind")
        }
    }

    override fun toJson(value: WidgetContent.Background): JsonElement = buildJsonObject {
        when (value) {
            is WidgetContent.Background.Color -> put("color", buildJsonObject { put("_0", strings(value.hexes)) })
            is WidgetContent.Background.Photo -> put("photo", buildJsonObject { put("_0", imageToJson(value.imageData)) })
        }
    }
}
