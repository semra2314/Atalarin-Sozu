package com.example.kare.core.data

import com.example.kare.core.data.catalog.BundledWidgetRepository
import com.example.kare.core.data.catalog.LocalCatalogDataSource
import com.example.kare.core.model.*
import com.example.kare.core.repository.RepositoryException
import java.io.IOException
import java.math.BigDecimal
import java.util.Locale
import kotlinx.coroutines.*
import kotlinx.serialization.json.*
import org.junit.Assert.*
import org.junit.Test

class CatalogTest {
    @Test fun packagedCatalogLoadsAndPreservesIosIdentities() = runBlocking {
        val catalog = LocalCatalogDataSource().load()
        val expected = resource("ios-source-manifest.json").jsonObject["orderedTemplateIds"]!!.jsonArray.map { it.jsonPrimitive.content }
        assertEquals(expected, catalog.templates.map { it.id })
        assertEquals(20, catalog.templates.size)
        assertEquals(20, catalog.templates.map { it.id }.toSet().size)
        assertTrue(catalog.templates.all { it.supportedSizes.isNotEmpty() && it.author.id == "a-kare" })
        assertEquals(listOf("t-exhale", "t-countdown", "t-progress"), catalog.liveKarePlusIds)
        assertEquals(setOf("t-focus", "t-frame", "t-daily", "t-exhale", "t-countdown", "t-progress"), catalog.setupTemplateIds)
        assertTrue(catalog.templates.filter { it.id.startsWith("p-") }.all { it.isEditable && it.content != null && it.galleryName == "Kare" })
        assertTrue(catalog.templates.filter { it.id.startsWith("t-") && it.id != "t-custom" }.all { !it.isEditable && it.content == null })
        assertEquals(7, catalog.templates.count { !it.price.isFree })
        assertEquals(BigDecimal("1.99"), (catalog.templates.first { it.id == "t-exhale" }.price as WidgetTemplate.Price.Paid).amount)
    }

    @Test fun lookupAndMissingIdUseDomainContract() = runBlocking {
        val repo = BundledWidgetRepository()
        assertEquals("Aurora Clock", repo.template("t-aurora").name)
        assertEquals("Söz", repo.template("t-proverb").name)
        assertEquals("Custom Widget", repo.template("t-custom").name)
        try { repo.template("missing"); fail("Expected NotFound") }
        catch (error: RepositoryException.NotFound) { assertEquals("missing", error.id) }
    }

    @Test fun everyCategoryMatchesCatalogOrderIncludingEmptyCategories() = runBlocking {
        val repo = BundledWidgetRepository()
        val all = repo.search("")
        for (category in WidgetCategory.entries) {
            assertEquals(all.filter { it.category == category }, repo.templates(category))
            assertEquals(repo.templates(category), repo.search("  ", category))
        }
        assertTrue(repo.templates(WidgetCategory.FINANCE).isEmpty())
    }

    @Test fun searchMatchesNameSummaryTagsAndAuthorAndIntersectsCategory() = runBlocking {
        val repo = BundledWidgetRepository()
        assertEquals(listOf("t-aurora"), repo.search("  AURORA CLOCK\n").map { it.id })
        assertTrue(repo.search("a wedding").any { it.id == "t-countdown" })
        assertTrue(repo.search("gradient").any { it.id == "p-sunset" })
        assertEquals(repo.search(""), repo.search("Kare"))
        assertEquals(listOf("t-proverb"), repo.search("atasözü").map { it.id })
        assertTrue(repo.search("aurora", WidgetCategory.HEALTH).isEmpty())
        assertTrue(repo.search("no-such-widget-xyz").isEmpty())
    }

    @Test fun searchDoesNotChangeWithDeviceLocale() = runBlocking {
        val previous = Locale.getDefault()
        try {
            Locale.setDefault(Locale.forLanguageTag("tr-TR"))
            assertTrue(BundledWidgetRepository().search("MINIMAL").isNotEmpty())
        } finally { Locale.setDefault(previous) }
    }

    @Test fun sectionsKeepIosCurationAndPaidShelfPolicy() = runBlocking {
        val repo = BundledWidgetRepository()
        val sections = repo.discoverSections()
        assertEquals(listOf("spotlight", "count", "all", "minimal", "plus", "free"), sections.map { it.id })
        assertTrue(sections.all { it.templates.isNotEmpty() })
        assertEquals(listOf("t-aurora", "t-focus", "t-frame"), sections.first().templates.map { it.id })
        assertEquals(listOf("t-exhale", "t-countdown", "t-progress"), sections[1].templates.map { it.id })
        assertEquals(repo.search(""), sections.first { it.id == "all" }.templates)
        assertTrue(sections.first { it.id == "plus" }.templates.all { !it.price.isFree })
        assertTrue(sections.first { it.id == "free" }.templates.all { it.price.isFree })
        assertTrue(sections.first { it.id == "minimal" }.templates.all { it.category == WidgetCategory.MINIMAL })
        val withoutPaid = BundledWidgetRepository(includePaidSection = false)
        assertFalse(withoutPaid.discoverSections().any { it.id == "plus" })
        assertEquals(repo.search(""), withoutPaid.search(""))
    }

    @Test fun reviewsFailExplicitlyInsteadOfPretendingToPublish() = runBlocking {
        val repo = BundledWidgetRepository()
        try { repo.reviews("t-focus"); fail("Reviews should be unavailable") }
        catch (_: RepositoryException.Unavailable) { }
        try { repo.submitReview(Review("t-focus", "Fixture", 5, "Example")); fail("Writes should be unavailable") }
        catch (_: RepositoryException.Unavailable) { }
    }

    @Test fun concurrentLoadsCacheOneValidatedSnapshotAndDoNotExposeMutableLists() = runBlocking {
        var reads = 0
        val json = bundledText()
        val source = LocalCatalogDataSource(readCatalog = { reads++; json })
        val snapshots = (1..10).map { async { source.load() } }.awaitAll()
        assertEquals(1, reads)
        assertTrue(snapshots.all { it === snapshots.first() })
        try { (snapshots.first().templates as MutableList).clear(); fail("Mutable catalog") }
        catch (_: UnsupportedOperationException) { }
        try { (snapshots.first().templates.first().tags as MutableList).clear(); fail("Mutable nested data") }
        catch (_: UnsupportedOperationException) { }
    }

    @Test fun invalidCatalogIsNotCachedAndErrorsAreMapped() = runBlocking {
        var attempts = 0
        val valid = bundledText()
        val repo = BundledWidgetRepository(LocalCatalogDataSource(readCatalog = { if (++attempts == 1) "{}" else valid }))
        try { repo.search(""); fail("Expected invalid catalog") }
        catch (error: RepositoryException.InvalidData) { assertTrue(error.suppressed.single() is kotlinx.serialization.SerializationException) }
        assertEquals(20, repo.search("").size)
        val broken = BundledWidgetRepository(LocalCatalogDataSource(readCatalog = { throw IOException("missing") }))
        try { broken.search(""); fail("Expected persistence failure") }
        catch (error: RepositoryException.Persistence) { assertTrue(generateSequence<Throwable>(error) { it.cause }.any { it is IOException }) }
    }

    @Test fun duplicatesDanglingReferencesAndUnsupportedVersionsAreRejected() = runBlocking {
        val original = Json.parseToJsonElement(bundledText()).jsonObject
        val templates = original.getValue("templates").jsonArray
        val badInputs = listOf(
            JsonObject(original + ("templates" to JsonArray(templates + templates.first()))),
            JsonObject(original + ("schemaVersion" to JsonPrimitive(99))),
            JsonObject(original + ("setupTemplateIds" to JsonArray(listOf(JsonPrimitive("missing"))))),
            JsonObject(original + ("templates" to JsonArray(templates.drop(1)))),
        )
        for (bad in badInputs) {
            try { BundledWidgetRepository(LocalCatalogDataSource(readCatalog = { bad.toString() })).search(""); fail("Invalid bundle accepted") }
            catch (_: RepositoryException.InvalidData) { }
        }
    }

    @Test fun cancellationIsNeverTranslatedToRepositoryFailure() = runBlocking {
        val repo = BundledWidgetRepository(LocalCatalogDataSource(readCatalog = { throw CancellationException("cancel") }))
        try { repo.search(""); fail("Cancellation expected") }
        catch (error: CancellationException) { assertEquals("cancel", error.message) }
    }
}

internal fun resource(name: String): JsonElement = Json.parseToJsonElement(
    requireNotNull(CatalogTest::class.java.getResourceAsStream("/catalog/$name")).bufferedReader().use { it.readText() },
)
internal fun bundledText(): String = requireNotNull(
    CatalogTest::class.java.getResourceAsStream("/catalog/kare-catalog-v1.json"),
).bufferedReader().use { it.readText() }
