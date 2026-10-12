package com.example.kare.core.data.widget

import com.example.kare.core.model.*
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.*
import java.time.Clock
import java.time.ZonedDateTime
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

/** Stateless iOS hour + day-of-year rotation; no random content or persisted clock. */
fun hushEntry(now: ZonedDateTime, language: HushLanguage): HushEntry = HushEntry(
    HushPrompt.entries[(now.hour + now.dayOfYear) % HushPrompt.entries.size],
    when (now.hour) { in 5..10 -> HushPalette.DAWN; in 11..19 -> HushPalette.STILL; else -> HushPalette.NIGHT },
    language,
)

class HushWidgetRepository(
    private val store: HushInstanceStore,
    private val library: LibraryRepository,
    private val catalog: WidgetRepository,
    private val errors: ErrorReporter,
    // Resolve the device zone on each render; a running process may survive a timezone change.
    private val now: () -> ZonedDateTime = { ZonedDateTime.now(Clock.systemDefaultZone()) },
) {
    suspend fun configuration(id: Int) = store.read(id)
    suspend fun configure(id: Int, language: HushLanguage) {
        require(id > 0)
        val template = catalog.template("t-hush")
        require(template.price.isFree)
        library.install(template, WidgetSize.SMALL.takeIf { it in template.supportedSizes } ?: template.supportedSizes.first())
        store.save(id, HushConfiguration(language))
    }
    fun invalidate() = store.invalidate()
    suspend fun delete(id: Int) = store.delete(id)

    @OptIn(ExperimentalCoroutinesApi::class)
    fun observe(id: Int): Flow<HushSnapshot> = store.changes.flatMapLatest {
        library.observeWidgets().map<List<InstalledWidget>, HushSnapshot> { widgets ->
            val config = store.read(id)
            when {
                config == null -> HushSnapshot.NeedsConfiguration
                widgets.none { it.templateId == "t-hush" } -> HushSnapshot.LibraryMissing
                else -> HushSnapshot.Ready(hushEntry(now(), config.language))
            }
        }.catch { error ->
            if (error is CancellationException) throw error
            errors.report("hush.snapshot", error)
            emit(HushSnapshot.Unavailable)
        }
    }.flowOn(Dispatchers.IO)
}
