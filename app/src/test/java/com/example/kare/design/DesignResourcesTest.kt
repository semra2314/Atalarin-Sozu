package com.example.kare.design

import android.content.res.Configuration
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.font.ResourceFont
import androidx.compose.ui.unit.sp
import com.example.kare.R
import com.example.kare.core.design.*
import com.example.kare.core.localization.*
import com.example.kare.core.model.WidgetCategory
import com.example.kare.core.presentation.UiError
import java.util.Locale
import kotlinx.serialization.json.*
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class DesignResourcesTest {
    private fun resources(language: String) = RuntimeEnvironment.getApplication().let { app ->
        val config = Configuration(app.resources.configuration).apply { setLocale(Locale.forLanguageTag(language)) }
        app.createConfigurationContext(config).resources
    }

    @Test fun englishAndTurkishCompiledResourcesPreserveSourceAndFormatting() {
        val input = javaClass.getResourceAsStream("/localization/source-mapping.json")!!.bufferedReader().use { it.readText() }
        val entries = Json.parseToJsonElement(input).jsonObject
        for (lang in listOf("en", "tr")) {
            val res = resources(lang)
            for ((name, entry) in entries) {
                val id = R.string::class.java.getField(name).getInt(null)
                assertEquals("$lang/$name", entry.jsonObject.getValue(lang).jsonPrimitive.content, res.getString(id))
            }
            assertTrue(res.getString(R.string.author_by, "Ada").contains("Ada"))
            assertTrue(res.getString(R.string.starter_greeting, "Android").contains("Android"))
        }
        assertEquals("Keşfet", resources("tr").getString(R.string.discover_title))
        assertEquals("Discover", resources("de").getString(R.string.discover_title))
    }

    @Test fun resourceLanguagesHaveMatchingPlaceholderContracts() {
        val input = javaClass.getResourceAsStream("/localization/source-mapping.json")!!.bufferedReader().use { it.readText() }
        val placeholders = Regex("%[0-9]+\\$[sd]")
        Json.parseToJsonElement(input).jsonObject.values.forEach { entry ->
            val e = entry.jsonObject
            assertEquals(placeholders.findAll(e.getValue("en").jsonPrimitive.content).map { it.value }.toList(),
                placeholders.findAll(e.getValue("tr").jsonPrimitive.content).map { it.value }.toList())
        }
    }

    @Test fun everyErrorAndCategoryHasLocalizedUiMapping() {
        for (lang in listOf("en", "tr")) {
            val res = resources(lang)
            UiError.entries.forEach { assertTrue(res.getString(it.stringResource()).isNotBlank()) }
            WidgetCategory.entries.forEach { assertTrue(res.getString(it.stringResource()).isNotBlank()) }
            listOf("spotlight", "count", "all", "minimal", "plus", "free").forEach {
                val strings = requireNotNull(catalogSectionStrings(it))
                assertTrue(res.getString(strings.title).isNotBlank())
                strings.subtitle?.let { id -> assertTrue(res.getString(id).isNotBlank()) }
            }
        }
        assertEquals(UiError.entries.size, UiError.entries.map { it.stringResource() }.toSet().size)
        assertNull(catalogSectionStrings("future-remote-section"))
    }

    @Test fun countsUseAndroidPluralRules() {
        assertEquals("1 widget", resources("en").getQuantityString(R.plurals.widget_count, 1, 1))
        assertEquals("3 widgets", resources("en").getQuantityString(R.plurals.widget_count, 3, 3))
        assertEquals("3 widget", resources("tr").getQuantityString(R.plurals.widget_count, 3, 3))
    }

    @Test fun allBundledFontsLoadAndMatchHeadingWeights() {
        val res = resources("tr")
        val expected = mapOf(FontWeight.SemiBold to R.font.fraunces_soft_semibold,
            FontWeight.Bold to R.font.fraunces_soft_bold, FontWeight.Black to R.font.fraunces_soft_black)
        val fonts = KareSerif as androidx.compose.ui.text.font.FontListFontFamily
        assertEquals(expected.size, fonts.fonts.size)
        fonts.fonts.forEach { font ->
            assertEquals(expected[font.weight], (font as ResourceFont).resId)
            assertNotNull(res.getFont(font.resId))
        }
        assertEquals(KareSerif, KareTypography.displayLarge.fontFamily)
        assertEquals(FontWeight.Black, KareTypography.displayLarge.fontWeight)
        assertEquals(34.sp, KareTypography.displayLarge.fontSize)
        assertEquals(KareTextStyles.bodyLarge, KareTypography.bodyLarge)
        assertTrue(RuntimeEnvironment.getApplication().assets.open("licenses/fraunces_ofl.txt")
            .bufferedReader().use { it.readText() }.contains("SIL OPEN FONT LICENSE"))
    }

    @Test fun lightAndDarkMaterialRolesUseKareTokensAndReadableContrast() {
        for (dark in listOf(false, true)) {
            val c = if (dark) KareDarkColors else KareLightColors
            val material = kareColorScheme(dark)
            assertEquals(c.background, material.background)
            assertEquals(c.surface, material.surface)
            assertEquals(c.textPrimary, material.onSurface)
            assertEquals(c.border, material.outlineVariant)
            assertTrue(contrast(material.onPrimary, material.primary) >= 4.5)
            assertTrue(contrast(material.onSurface, material.surface) >= 4.5)
            assertTrue(contrast(material.onSurfaceVariant, material.surface) >= 4.5)
            assertEquals(1f, material.primaryContainer.alpha)
        }
        assertEquals(31f / 255, KareLightColors.accentTint.alpha, .001f)
        assertEquals(46f / 255, KareDarkColors.accentTint.alpha, .001f)
        assertEquals(KareShapes.card, KareShapes.material.medium)
        assertEquals(KareShapes.sheet, KareShapes.material.extraLarge)
    }

    private fun contrast(a: Color, b: Color): Double =
        (maxOf(a.luminance(), b.luminance()) + .05) / (minOf(a.luminance(), b.luminance()) + .05)
}
