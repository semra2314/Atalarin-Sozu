package com.example.kare.core.data.library

import com.example.kare.core.data.catalog.LocalCatalogDataSource
import com.example.kare.core.model.*
import com.example.kare.core.repository.RepositoryException
import java.time.Instant
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test

class InstalledWidgetMapperTest {
    @Test fun everyCatalogTemplateRoundTripsBothDirections() = runBlocking {
        for (template in LocalCatalogDataSource().load().templates) {
            val model = InstalledWidget(template.id, template.name, template.author.displayName,
                template.category, template.primarySize, template.theme, template.content,
                Instant.parse("1969-12-31T23:59:59.123456789Z"), true, 7, template.isEditable, template.previewImageName)
            val entity = InstalledWidgetMapper.toEntity(model)
            assertEquals(model, InstalledWidgetMapper.toDomain(entity))
            assertEquals(entity, InstalledWidgetMapper.toEntity(InstalledWidgetMapper.toDomain(entity)))
            assertEquals(template.category.rawValue, entity.categoryRaw)
            assertEquals(-1L, entity.addedAtSeconds)
            assertEquals(123456789, entity.addedAtNanos)
        }
    }

    @Test fun nullablePayloadAndBinaryImageRoundTrip() {
        val model = InstalledWidget("offline", "Offline", "Creator", WidgetCategory.MINIMAL, WidgetSize.SMALL,
            addedAt = Instant.EPOCH)
        assertEquals(model, InstalledWidgetMapper.toDomain(InstalledWidgetMapper.toEntity(model)))
        val photo = model.copy(content = WidgetContent(background = WidgetContent.Background.Photo(ImageData(byteArrayOf(0, -1, 42)))))
        assertEquals(photo, InstalledWidgetMapper.toDomain(InstalledWidgetMapper.toEntity(photo)))
    }

    @Test fun unknownVersionEnumsAndInvalidTimestampAreRejected() {
        val entity = InstalledWidgetMapper.toEntity(InstalledWidget("offline", "Offline", "Creator",
            WidgetCategory.MINIMAL, WidgetSize.SMALL))
        for (bad in listOf(entity.copy(payloadVersion = 2), entity.copy(categoryRaw = "future"),
            entity.copy(sizeRaw = "future"), entity.copy(addedAtNanos = -1), entity.copy(sortIndex = -1))) {
            try { InstalledWidgetMapper.toDomain(bad); fail("Invalid persistence accepted") }
            catch (_: RepositoryException.InvalidData) { }
        }
    }
}
