package com.example.kare.core.data.widget

import com.example.kare.core.model.*
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.*
import java.time.Clock
import java.time.LocalDate
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

class DailyWidgetRepository(
    private val store: DailyInstanceStore,
    private val library: LibraryRepository,
    private val catalog: WidgetRepository,
    private val errors: ErrorReporter,
    // Resolve the device date on each render; a running process may survive a timezone change.
    private val today: () -> LocalDate = { LocalDate.now(Clock.systemDefaultZone()) },
) {
    suspend fun configuration(id: Int) = store.read(id)
    suspend fun configure(id: Int, source: DailySource) {
        require(id > 0)
        val template = catalog.template("t-daily")
        require(template.price.isFree)
        library.install(template, WidgetSize.SMALL.takeIf { it in template.supportedSizes } ?: template.supportedSizes.first())
        store.save(id, DailyConfiguration(source))
    }
    fun invalidate() = store.invalidate()
    suspend fun delete(id: Int) = store.delete(id)

    @OptIn(ExperimentalCoroutinesApi::class)
    fun observe(id: Int): Flow<DailySnapshot> = store.changes.flatMapLatest {
        library.observeWidgets().map<List<InstalledWidget>, DailySnapshot> { widgets ->
            val config = store.read(id)
            when {
                config == null -> DailySnapshot.NeedsConfiguration
                widgets.none { it.templateId == "t-daily" } -> DailySnapshot.LibraryMissing
                else -> DailySnapshot.Ready(dailyPassage(today(), config.source))
            }
        }.catch { error ->
            if (error is CancellationException) throw error
            errors.report("daily.snapshot", error)
            emit(DailySnapshot.Unavailable)
        }
    }.flowOn(Dispatchers.IO)
}
