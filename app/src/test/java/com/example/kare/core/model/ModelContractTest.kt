package com.example.kare.core.model

import java.math.BigDecimal
import java.time.Instant
import java.util.UUID
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** Pins cross-platform values that must not change when UI names or platform APIs change. */
class ModelContractTest {
    @Test
    fun catalogRawValuesMatchIosContracts() {
        assertEquals(
            listOf("small", "medium", "large", "accessoryCircular", "accessoryRectangular"),
            WidgetSize.entries.map { it.rawValue },
        )
        assertEquals(
            listOf("productivity", "health", "finance", "weather", "photos", "minimal", "social", "fun"),
            WidgetCategory.entries.map { it.rawValue },
        )
        assertEquals(
            listOf("spotlight", "carousel", "compactList"),
            CatalogSection.Style.entries.map { it.rawValue },
        )
    }

    @Test
    fun editorRawValuesMatchIosContracts() {
        assertEquals(listOf("serif", "rounded", "monospaced", "standard"), WidgetContent.FontStyle.entries.map { it.rawValue })
        assertEquals(listOf("regular", "semibold", "bold", "heavy"), WidgetContent.Weight.entries.map { it.rawValue })
        assertEquals(listOf("leading", "center", "trailing"), WidgetContent.TextAlign.entries.map { it.rawValue })
        assertEquals(listOf("top", "middle", "bottom"), WidgetContent.VerticalAlign.entries.map { it.rawValue })
        assertEquals(listOf("topLeading", "top", "topTrailing", "leading"), WidgetContent.GradientDirection.entries.map { it.rawValue })
    }

    @Test
    fun imageValuesAreEqualByContentAndCannotBeMutatedThroughArrays() {
        val source = byteArrayOf(1, 2, 3)
        val data = ImageData(source)
        val same = ImageData(byteArrayOf(1, 2, 3))
        val originalHash = data.hashCode()
        source[0] = 9
        data.toByteArray()[1] = 9
        assertEquals(same, data)
        assertEquals(originalHash, data.hashCode())
        assertEquals(same.hashCode(), data.hashCode())
        assertNotEquals(ImageData(byteArrayOf(1, 2)), data)
    }

    @Test
    fun independentlyLoadedPhotosKeepWidgetContentValueEquality() {
        val id = UUID.fromString("4a0795ad-43e5-4aab-af90-1f028be3ce08")
        fun content() = WidgetContent(
            background = WidgetContent.Background.Photo(ImageData(byteArrayOf(1, 2))),
            photos = listOf(WidgetContent.PhotoElement(id = id, imageData = ImageData(byteArrayOf(3, 4)))),
        )
        assertEquals(content(), content())
        assertEquals(content().hashCode(), content().hashCode())
    }

    @Test
    fun onlySymbolStickersCanBeTinted() {
        val symbol = WidgetContent.Sticker()
        assertTrue(symbol.isTintable)
        assertFalse(symbol.copy(emoji = "⭐").isTintable)
        assertFalse(symbol.copy(imageData = ImageData(byteArrayOf(1))).isTintable)
        assertTrue(symbol.copy(emoji = "⭐").isEmoji)
        assertTrue(symbol.copy(imageData = ImageData(byteArrayOf(1))).isImage)
    }

    @Test
    fun pricePreservesDecimalPrecisionAndFreeIsAnExplicitCase() {
        val amount = BigDecimal("123456789.123456789")
        val price = WidgetTemplate.Price.Paid(amount, "TRY")
        assertEquals("123456789.123456789", price.amount.toPlainString())
        assertFalse(price.isFree)
        assertFalse(WidgetTemplate.Price.Paid(BigDecimal.ZERO, "USD").isFree)
        assertTrue(WidgetTemplate.Price.Free.isFree)
    }

    @Test
    fun templateUsesFirstSupportedSizeAndSmallFallback() {
        val template = template(listOf(WidgetSize.MEDIUM, WidgetSize.SMALL))
        assertEquals(WidgetSize.MEDIUM, template.primarySize)
        assertEquals(WidgetSize.SMALL, template.copy(supportedSizes = emptyList()).primarySize)
        assertFalse(template.isEditable)
    }

    @Test
    fun invalidReviewRatingIsRejectedIncludingOnCopy() {
        for (stars in listOf(Int.MIN_VALUE, 0, 6, Int.MAX_VALUE)) {
            assertRejected { Review(templateId = "t-focus", authorName = "A", stars = stars, text = "Review") }
        }
        val valid = Review(templateId = "t-focus", authorName = "A", stars = 1, text = "Review")
        assertEquals(5, valid.copy(stars = 5).stars)
        assertRejected { valid.copy(stars = 0) }
    }

    private fun assertRejected(block: () -> Unit) {
        var rejected = false
        try {
            block()
        } catch (_: IllegalArgumentException) {
            rejected = true
        }
        assertTrue("Expected invalid rating to be rejected", rejected)
    }

    private fun template(sizes: List<WidgetSize>) = WidgetTemplate(
        id = "fixture",
        name = "Fixture",
        summary = "Model contract fixture",
        author = Author(id = "kare", displayName = "Kare", handle = "@kare"),
        category = WidgetCategory.MINIMAL,
        supportedSizes = sizes,
        theme = WidgetTheme(backgroundHexes = listOf("1D1D1F")),
        tags = emptyList(),
        installCount = 0,
        rating = 0.0,
        ratingCount = 0,
        price = WidgetTemplate.Price.Free,
        publishedAt = Instant.parse("2026-01-01T00:00:00Z"),
    )
}
