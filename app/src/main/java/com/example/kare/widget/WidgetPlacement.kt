package com.example.kare.widget

import android.app.ActivityOptions
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.core.net.toUri
import kotlinx.coroutines.CancellationException
import android.os.Build
import android.util.Log
import java.util.UUID

/** Transient launcher requests, never Library membership or persisted placement claims. */
enum class PlacementResult { REQUESTED, UNSUPPORTED, UNAVAILABLE }

interface WidgetPlacementManager {
    fun supportsPinning(): Boolean
    fun requestProverb(): Boolean
}

class WidgetPlacementCoordinator(private val manager: WidgetPlacementManager) {
    fun hasWidget(templateId: String) = templateId == "t-proverb"

    fun request(templateId: String): PlacementResult {
        if (!hasWidget(templateId)) return PlacementResult.UNAVAILABLE
        return try {
            if (!manager.supportsPinning()) PlacementResult.UNSUPPORTED
            else if (manager.requestProverb()) PlacementResult.REQUESTED
            else PlacementResult.UNAVAILABLE
        } catch (error: RuntimeException) {
            if (error is CancellationException) throw error
            Log.e("KareWidget", "widget.placement", error)
            PlacementResult.UNAVAILABLE
        }
    }
}

/** API 26 is also the application's minimum SDK. No launcher positioning or ID allocation. */
class AndroidWidgetPlacementManager(context: Context) : WidgetPlacementManager {
    private val context = context.applicationContext
    private val manager = AppWidgetManager.getInstance(this.context)
    override fun supportsPinning() = manager.isRequestPinAppWidgetSupported

    override fun requestProverb(): Boolean {
        // Pinning skips android:configure. The success callback supplies the real appWidgetId.
        // Unique, explicit, one-shot intents keep simultaneous requests independent. Mutability
        // is required for the system-supplied ID; the Activity validates its provider before use.
        val intent = Intent(context, ProverbConfigurationActivity::class.java)
            .setAction(AppWidgetManager.ACTION_APPWIDGET_CONFIGURE)
            .setData("kare-widget-placement:${UUID.randomUUID()}".toUri())
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        val flags = PendingIntent.FLAG_ONE_SHOT or
            (if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0)
        val options = if (Build.VERSION.SDK_INT >= 34) ActivityOptions.makeBasic()
            .setPendingIntentCreatorBackgroundActivityStartMode(ActivityOptions.MODE_BACKGROUND_ACTIVITY_START_ALLOWED)
            .toBundle() else null
        val callback = PendingIntent.getActivity(context, 0, intent, flags, options)
        return try {
            manager.requestPinAppWidget(ComponentName(context, ProverbReceiver::class.java), null, callback)
                .also { accepted -> if (!accepted) callback.cancel() }
        } catch (error: RuntimeException) {
            callback.cancel()
            throw error
        }
    }
}
