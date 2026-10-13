package com.example.kare.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import com.example.kare.core.model.LauncherWidgetType
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class WidgetPlacementTest {
    private class Fake : WidgetPlacementManager {
        var supported = true
        var accepted = true
        var calls = 0
        var failure: RuntimeException? = null
        override fun supportsPinning(): Boolean { failure?.let { throw it }; return supported }
        override fun request(type: LauncherWidgetType): Boolean { calls++; return accepted }
    }
    @Test fun availabilityIsLimitedToImplementedProvider() {
        val fake = Fake(); val coordinator = WidgetPlacementCoordinator(fake)
        assertTrue(coordinator.hasWidget("t-proverb"))
        assertTrue(coordinator.hasWidget("t-hush"))
        assertFalse(coordinator.hasWidget("t-focus"))
        assertEquals(PlacementResult.UNAVAILABLE, coordinator.request("t-focus"))
        assertEquals(0, fake.calls)
    }
    @Test fun supportedRequestIsDelegatedButNotReportedAsPlacementSuccess() {
        val fake = Fake()
        assertEquals(PlacementResult.REQUESTED, WidgetPlacementCoordinator(fake).request("t-proverb"))
        assertEquals(1, fake.calls)
    }
    @Test fun unsupportedLauncherDoesNotReceiveRequest() {
        val fake = Fake().apply { supported = false }
        assertEquals(PlacementResult.UNSUPPORTED, WidgetPlacementCoordinator(fake).request("t-proverb"))
        assertEquals(0, fake.calls)
    }
    @Test fun platformRejectionAndExceptionAreRecoverable() {
        val fake = Fake().apply { accepted = false }
        val coordinator = WidgetPlacementCoordinator(fake)
        assertEquals(PlacementResult.UNAVAILABLE, coordinator.request("t-proverb"))
        fake.failure = IllegalStateException("No foreground activity")
        assertEquals(PlacementResult.UNAVAILABLE, coordinator.request("t-proverb"))
    }
    @Test(expected = kotlinx.coroutines.CancellationException::class)
    fun cancellationIsNotReportedAsAPlacementFailure() {
        val fake = Fake().apply { failure = kotlinx.coroutines.CancellationException() }
        WidgetPlacementCoordinator(fake).request("t-proverb")
    }
    @Test fun placementMessagesHaveEnglishAndTurkishResources() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val ids = listOf(com.example.kare.R.string.widget_add_home,
            com.example.kare.R.string.widget_placement_requested, com.example.kare.R.string.widget_placement_unsupported,
            com.example.kare.R.string.widget_placement_unavailable, com.example.kare.R.string.widget_placement_manual)
        fun resources(locale: String) = context.createConfigurationContext(
            android.content.res.Configuration(context.resources.configuration).apply {
                setLocale(java.util.Locale.forLanguageTag(locale))
            }).resources
        ids.forEach { id ->
            val english = resources("en").getString(id)
            val turkish = resources("tr").getString(id)
            assertTrue(english.isNotBlank()); assertTrue(turkish.isNotBlank())
            assertNotEquals(english, turkish)
        }
    }
    @Test fun nativeManagerUsesProverbProviderAndCallbackPassesRealIdsToExistingConfiguration() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val platform = AppWidgetManager.getInstance(context)
        LauncherWidgetType.entries.forEach { type ->
            shadowOf(platform).addInstalledProvider(android.appwidget.AppWidgetProviderInfo().apply {
                provider = ComponentName(context, WidgetCapability.forType(type).receiver)
            })
        }
        shadowOf(platform).setRequestPinAppWidgetSupported(false)
        val manager = AndroidWidgetPlacementManager(context)
        assertFalse(manager.supportsPinning())
        shadowOf(platform).setRequestPinAppWidgetSupported(true)
        assertTrue(manager.supportsPinning())
        val ids = mutableSetOf<Int>()
        LauncherWidgetType.entries.forEach { type ->
            assertTrue(manager.request(type))
            val intent = shadowOf(context as android.app.Application).nextStartedActivity
            assertEquals(ComponentName(context, WidgetCapability.forType(type).configuration), intent.component)
            val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
            assertTrue(id > 0)
            assertTrue(ids.add(id))
            assertEquals(ComponentName(context, WidgetCapability.forType(type).receiver), platform.getAppWidgetInfo(id).provider)
        }
    }
}
