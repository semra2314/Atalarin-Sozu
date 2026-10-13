package com.example.kare.core.data.widget

import com.example.kare.core.model.*
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.*
import java.time.Clock
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

/** Resolves instance configuration to domain text without exposing Room or launcher APIs. */
class ProverbWidgetRepository(
    private val store: WidgetInstanceStore,
    private val library: LibraryRepository,
    private val catalog: WidgetRepository,
    private val errors: ErrorReporter,
    private val source: ProverbSource = ProverbSource(),
    private val clock: Clock = Clock.systemUTC(),
) {
    suspend fun configuration(id: Int) = store.read(id)
    suspend fun configure(id: Int, selection: ProverbSelection) {
        require(id > 0)
        val template = catalog.template("t-proverb")
        require(template.price.isFree)
        val size = WidgetSize.MEDIUM.takeIf { it in template.supportedSizes } ?: template.supportedSizes.first()
        library.install(template, size) // Same idempotent library transaction; no second template store.
        store.save(id, WidgetInstance(selection = selection))
    }
    fun invalidate() = store.invalidate()
    suspend fun delete(id: Int) = store.delete(id) // Never removes Library membership.

    @OptIn(ExperimentalCoroutinesApi::class)
    fun observe(id: Int): Flow<ProverbSnapshot> = store.changes.flatMapLatest {
        library.observeWidgets().map<List<InstalledWidget>, ProverbSnapshot> { widgets ->
            val config = store.read(id)
            when {
                config == null -> ProverbSnapshot.NeedsConfiguration
                widgets.none { it.templateId == config.templateId } -> ProverbSnapshot.LibraryMissing
                else -> ProverbSnapshot.Ready(source.entry(clock.instant(), config.selection))
            }
        }.catch { error ->
            if (error is CancellationException) throw error
            errors.report("widget.snapshot", error)
            emit(ProverbSnapshot.Unavailable)
        }
    }.flowOn(Dispatchers.IO)
}
