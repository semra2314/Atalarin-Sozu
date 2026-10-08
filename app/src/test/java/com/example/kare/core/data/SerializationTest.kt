package com.example.kare.core.data

import com.example.kare.core.data.serialization.*
import com.example.kare.core.model.*
import java.math.BigDecimal
import java.time.Instant
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.*
import org.junit.Assert.*
import org.junit.Test

class SerializationTest {
    private val fixtures = resource("ios-wire-fixtures.json").jsonObject

    @Test fun allSwiftExportedTemplatesRoundTripWithoutDroppingAnyFields() {
        val templates = Json.parseToJsonElement(bundledText()).jsonObject.getValue("templates").jsonArray
        for (json in templates) {
            val value = CatalogJson.decode(WidgetTemplateSerializer, json.toString())
            val encoded = CatalogJson.encode(WidgetTemplateSerializer, value)
            assertJsonEqual(json, Json.parseToJsonElement(encoded))
            assertEquals(value, CatalogJson.decode(WidgetTemplateSerializer, encoded))
        }
    }

    @Test fun swiftFixturesRoundTripForAuthorReviewThemeAndFullEditorPayload() {
        roundTrip("author", AuthorSerializer)
        roundTrip("review", ReviewSerializer)
        roundTrip("theme", WidgetThemeSerializer)
        roundTrip("content", WidgetContentSerializer)
        roundTrip("freePrice", WidgetPriceSerializer)
        roundTrip("paidPrice", WidgetPriceSerializer)
    }

    @Test fun associatedValuesRetainSwiftCasesAndExactDecimalNumbers() {
        val price = WidgetTemplate.Price.Paid(BigDecimal("123456789.123456789"), "TRY")
        val encoded = CatalogJson.encode(WidgetPriceSerializer, price)
        assertEquals(price, CatalogJson.decode(WidgetPriceSerializer, encoded))
        assertFalse(Json.parseToJsonElement(encoded).jsonObject.getValue("paid").jsonObject.getValue("amount").jsonPrimitive.isString)
        assertEquals("{\"free\":{}}", CatalogJson.encode(WidgetPriceSerializer, WidgetTemplate.Price.Free))
        val backgrounds = listOf(
            WidgetContent.Background.Color(listOf("123456", "ABCDEF88")),
            WidgetContent.Background.Photo(ImageData(byteArrayOf(0, 1, -2, -1))),
        )
        for (value in backgrounds) {
            val result = CatalogJson.encode(WidgetBackgroundSerializer, value)
            assertEquals(value, CatalogJson.decode(WidgetBackgroundSerializer, result))
            assertTrue(Json.parseToJsonElement(result).jsonObject.values.single().jsonObject.containsKey("_0"))
            assertFalse(result.contains("type"))
        }
    }

    @Test fun swiftDateEpochAndNegativeFractionArePreserved() {
        val review = CatalogJson.decode(ReviewSerializer, fixtures.getValue("review").toString())
        assertEquals(Instant.parse("2000-12-31T23:59:59.750Z"), review.createdAt)
        for (instant in listOf(Instant.EPOCH, Instant.parse("2026-10-08T00:00:00.123456789Z"))) {
            val changed = review.copy(createdAt = instant)
            assertEquals(changed, CatalogJson.decode(ReviewSerializer, CatalogJson.encode(ReviewSerializer, changed)))
        }
    }

    @Test fun legacyTextMigratesOnlyWhenTextsAreMissingOrNull() {
        val base = fixtures.getValue("content").jsonObject
        for (json in listOf(JsonObject(base - "texts"), JsonObject(base + ("texts" to JsonNull)))) {
            val content = CatalogJson.decode(WidgetContentSerializer, json.toString())
            val text = content.texts.single()
            assertEquals(content.text, text.text)
            assertEquals(0.66, text.x, 0.0)
            assertEquals(0.76, text.y, 0.0)
            assertEquals(content.fontStyle, text.fontStyle)
            assertEquals(content.fontWeight, text.fontWeight)
            assertEquals(content.lineSpacing, text.lineSpacing, 0.0)
        }
        val empty = JsonObject(base + ("texts" to JsonArray(emptyList())))
        assertTrue(CatalogJson.decode(WidgetContentSerializer, empty.toString()).texts.isEmpty())
        val blank = JsonObject(base - "texts" + ("text" to JsonPrimitive(" \n\t")))
        assertTrue(CatalogJson.decode(WidgetContentSerializer, blank.toString()).texts.isEmpty())
    }

    @Test fun legacyOptionalFieldsAndElementDefaultsMatchSwift() {
        val legacy = """{"text":"hello","fontStyle":"serif","fontSize":22,"textColorHex":"FFFFFF","alignment":"leading","background":{"color":{"_0":[]}},"photos":null,"stickers":[{}],"texts":[{"text":"placed"}]}"""
        val decoded = CatalogJson.decode(WidgetContentSerializer, legacy)
        assertEquals(WidgetContent.TextElement(text = "placed", id = decoded.texts.single().id), decoded.texts.single())
        assertEquals(WidgetContent.Sticker(id = decoded.stickers.single().id), decoded.stickers.single())
        assertEquals(WidgetContent.GradientDirection.TOP_LEADING, decoded.gradientDirection)
        assertEquals(WidgetContent.Weight.BOLD, decoded.fontWeight)
        assertTrue(decoded.photos.isEmpty())
        val lifted = CatalogJson.decode(WidgetContentSerializer, JsonObject(Json.parseToJsonElement(legacy).jsonObject - "texts").toString()).texts.single()
        assertEquals(0.34, lifted.x, 0.0)
        assertEquals(0.24, lifted.y, 0.0)
    }

    @Test fun unknownFieldsAreAdditiveButUnknownCasesAndWrongTypesFail() {
        val original = fixtures.getValue("content").jsonObject
        val extra = JsonObject(original + ("futureField" to JsonPrimitive("okay")))
        assertEquals(CatalogJson.decode(WidgetContentSerializer, original.toString()), CatalogJson.decode(WidgetContentSerializer, extra.toString()))
        for ((field, value) in listOf(
            "fontStyle" to JsonPrimitive("unknown"), "fontSize" to JsonPrimitive("22"),
            "textScrim" to JsonPrimitive("true"), "texts" to JsonPrimitive("not-an-array"),
            "background" to Json.parseToJsonElement("""{"video":{"_0":"x"}}"""),
        )) reject(WidgetContentSerializer, JsonObject(original + (field to value)).toString())
        reject(WidgetContentSerializer, JsonObject(original - "text").toString())
        reject(WidgetPriceSerializer, """{"free":{},"paid":{"amount":1,"currencyCode":"USD"}}""")
        reject(WidgetPriceSerializer, """{"paid":{"amount":"1.99","currencyCode":"USD"}}""")
        reject(WidgetPriceSerializer, """{"subscription":{}}""")
        reject(WidgetBackgroundSerializer, """{"photo":{"_0":"not base64"}}""")
        reject(WidgetBackgroundSerializer, """{"color":[],"photo":{}}""")
        reject(ReviewSerializer, JsonObject(fixtures.getValue("review").jsonObject + ("stars" to JsonPrimitive(6))).toString())
    }

    @Test fun rejectsInvalidUuidNonFiniteValuesAndOutOfRangeDates() {
        val content = fixtures.getValue("content").jsonObject
        val text = content.getValue("texts").jsonArray.first().jsonObject
        reject(WidgetContentSerializer, JsonObject(content + ("texts" to JsonArray(listOf(JsonObject(text + ("id" to JsonPrimitive("1-1-1-1-1"))))))).toString())
        reject(WidgetContentSerializer, JsonObject(content + ("fontSize" to JsonPrimitive(BigDecimal("1e999")))).toString())
        reject(ReviewSerializer, JsonObject(fixtures.getValue("review").jsonObject + ("createdAt" to JsonPrimitive(BigDecimal("1e100")))).toString())
        try { CatalogJson.encode(WidgetContentSerializer, WidgetContent(fontSize = Double.NaN)); fail("Non-finite encoding accepted") }
        catch (_: SerializationException) { }
    }

    @Test fun resolvedSectionRoundTripUsesExplicitAndroidShape() {
        val template = CatalogJson.decode(WidgetTemplateSerializer, Json.parseToJsonElement(bundledText()).jsonObject.getValue("templates").jsonArray.first().toString())
        val section = CatalogSection("fixture", "Title", CatalogSection.Style.COMPACT_LIST, listOf(template))
        assertEquals(section, CatalogJson.decode(CatalogSectionSerializer, CatalogJson.encode(CatalogSectionSerializer, section)))
    }

    private fun <T> roundTrip(key: String, serializer: JsonModelSerializer<T>) {
        val json = fixtures.getValue(key)
        val model = CatalogJson.decode(serializer, json.toString())
        val encoded = CatalogJson.encode(serializer, model)
        assertJsonEqual(json, Json.parseToJsonElement(encoded))
        assertEquals(model, CatalogJson.decode(serializer, encoded))
    }

    private fun <T> reject(serializer: JsonModelSerializer<T>, json: String) {
        try { CatalogJson.decode(serializer, json); fail("Malformed payload accepted: $json") }
        catch (_: SerializationException) { }
    }
}

/** JSON numbers can differ in spelling (22 vs 22.0), but no field, type or value may be lost. */
private fun assertJsonEqual(expected: JsonElement, actual: JsonElement) {
    when {
        expected is JsonObject && actual is JsonObject -> {
            assertEquals(expected.keys, actual.keys)
            expected.forEach { (key, value) -> assertJsonEqual(value, actual.getValue(key)) }
        }
        expected is JsonArray && actual is JsonArray -> {
            assertEquals(expected.size, actual.size)
            expected.zip(actual).forEach { (a, b) -> assertJsonEqual(a, b) }
        }
        expected is JsonPrimitive && actual is JsonPrimitive && !expected.isString && !actual.isString -> {
            val a = expected.content.toBigDecimalOrNull()
            val b = actual.content.toBigDecimalOrNull()
            if (a != null && b != null) assertEquals(0, a.compareTo(b)) else assertEquals(expected, actual)
        }
        else -> assertEquals(expected, actual)
    }
}
