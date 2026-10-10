package com.example.kare.app

import com.example.kare.core.data.widget.*
import com.example.kare.widget.ProverbWidget
import java.io.File
import android.content.Context
import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.createSavedStateHandle
import androidx.lifecycle.viewmodel.CreationExtras
import androidx.lifecycle.ViewModelProvider
import com.example.kare.core.data.auth.InMemoryAuthRepository
import com.example.kare.core.data.catalog.BundledWidgetRepository
import com.example.kare.core.data.catalog.LocalCatalogDataSource
import com.example.kare.core.data.library.RoomLibraryRepository
import com.example.kare.core.database.KareDatabase
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.AuthRepository
import com.example.kare.core.repository.LibraryRepository
import com.example.kare.core.repository.WidgetRepository
import com.example.kare.feature.auth.AuthViewModel
import com.example.kare.feature.detail.DetailViewModel
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
    private val localLibrary by lazy { RoomLibraryRepository(database, catalog) }
    private val widgetStore by lazy { WidgetInstanceStore(File(applicationContext.noBackupFilesDir, "widget-instances")) }
    val widgetInstances by lazy { ProverbWidgetRepository(widgetStore, localLibrary, widgets, errors) }
    val library: LibraryRepository by lazy {
        WidgetRefreshingLibraryRepository(localLibrary, { ProverbWidget.refreshAll(applicationContext) }, errors)
    }
    val auth: AuthRepository by lazy { InMemoryAuthRepository() }
    private val errors = ErrorReporter { operation, error -> Log.e("Kare", operation, error); Unit }
    val viewModelFactory: ViewModelProvider.Factory by lazy { KareViewModelFactory(widgets, library, errors, auth) }

    /** Test teardown only. Android process death owns production cleanup; no onTerminate assumption. */
    internal fun close() { if (databaseDelegate.isInitialized()) database.close() }
}

class KareViewModelFactory(
    private val widgets: WidgetRepository,
    private val library: LibraryRepository,
    private val errors: ErrorReporter,
    private val auth: AuthRepository = InMemoryAuthRepository(),
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return createModel(modelClass, SavedStateHandle())
    }

    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T =
        createModel(modelClass, extras.createSavedStateHandle())

    private fun <T : ViewModel> createModel(modelClass: Class<T>, savedState: SavedStateHandle): T {
        val model = when (modelClass) {
            DetailViewModel::class.java -> DetailViewModel(savedState["templateId"] ?: "", widgets, library, errors, savedState)
            DiscoverViewModel::class.java -> DiscoverViewModel(widgets, errors)
            SearchViewModel::class.java -> SearchViewModel(widgets, errors, savedState)
            LibraryViewModel::class.java -> LibraryViewModel(library, widgets, errors)
            AuthViewModel::class.java -> AuthViewModel(auth, errors)
            else -> throw IllegalArgumentException("Unsupported ViewModel: ${modelClass.name}")
        }
        return modelClass.cast(model)!!
    }
}
