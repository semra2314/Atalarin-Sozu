package com.example.kare.app

import android.content.Context
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.example.kare.core.data.catalog.BundledWidgetRepository
import com.example.kare.core.data.catalog.LocalCatalogDataSource
import com.example.kare.core.data.library.RoomLibraryRepository
import com.example.kare.core.database.KareDatabase
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.LibraryRepository
import com.example.kare.core.repository.WidgetRepository
import com.example.kare.feature.discover.DiscoverViewModel
import com.example.kare.feature.library.LibraryViewModel
import com.example.kare.feature.search.SearchViewModel

/** Application-owned composition root. Stateless codecs/mappers remain inside their data boundaries. */
class AppContainer(context: Context) {
    private val applicationContext = context.applicationContext
    private val catalog by lazy { LocalCatalogDataSource() }
    private val databaseDelegate = lazy { KareDatabase.open(applicationContext) }
    internal val database: KareDatabase get() = databaseDelegate.value
    val widgets: WidgetRepository by lazy { BundledWidgetRepository(catalog) }
    val library: LibraryRepository by lazy { RoomLibraryRepository(database, catalog) }
    private val errors = ErrorReporter { operation, error -> Log.e("Kare", operation, error); Unit }
    val viewModelFactory: ViewModelProvider.Factory by lazy { KareViewModelFactory(widgets, library, errors) }

    /** Test teardown only. Android process death owns production cleanup; no onTerminate assumption. */
    internal fun close() { if (databaseDelegate.isInitialized()) database.close() }
}

class KareViewModelFactory(
    private val widgets: WidgetRepository,
    private val library: LibraryRepository,
    private val errors: ErrorReporter,
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        val model = when (modelClass) {
            DiscoverViewModel::class.java -> DiscoverViewModel(widgets, errors)
            SearchViewModel::class.java -> SearchViewModel(widgets, errors)
            LibraryViewModel::class.java -> LibraryViewModel(library, widgets, errors)
            else -> throw IllegalArgumentException("Unsupported ViewModel: ${modelClass.name}")
        }
        return modelClass.cast(model)!!
    }
}
