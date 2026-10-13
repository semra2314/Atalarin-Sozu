package com.example.kare.app

import com.example.kare.core.data.widget.*
import com.example.kare.widget.ProverbWidget
import com.example.kare.widget.HushWidget
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
    private val hushStore by lazy { HushInstanceStore(File(applicationContext.noBackupFilesDir, "widget-instances")) }
    val hushInstances by lazy { HushWidgetRepository(hushStore, localLibrary, widgets, errors) }
    val library: LibraryRepository by lazy {
        WidgetRefreshingLibraryRepository(localLibrary, { ProverbWidget.refreshAll(applicationContext); HushWidget.refreshAll(applicationContext) }, errors)
    }
    val auth: AuthRepository by lazy { InMemoryAuthRepository() }
    val preferences: com.example.kare.core.repository.UserPreferencesRepository by lazy {
        com.example.kare.core.data.preferences.SharedPreferencesUserPreferencesRepository(applicationContext)
    }
    val publicProfile: com.example.kare.core.repository.PublicProfileRepository by lazy {
        com.example.kare.core.data.profile.InMemoryPublicProfileRepository()
    }
    val profile: com.example.kare.core.repository.ProfileRepository by lazy {
        com.example.kare.core.data.profile.LocalProfileRepository(applicationContext, auth, publicProfile)
    }
    val reviews: com.example.kare.core.repository.ReviewRepository by lazy {
        com.example.kare.core.data.review.InMemoryReviewRepository(auth)
    }
    val avatarStore: com.example.kare.core.data.profile.ProfileAvatarStore by lazy {
        com.example.kare.core.data.profile.ProfileAvatarStore(applicationContext)
    }
    private val errors = ErrorReporter { operation, error -> Log.e("Kare", operation, error); Unit }
    val viewModelFactory: ViewModelProvider.Factory by lazy {
        KareViewModelFactory(widgets, library, errors, auth, profile, preferences, reviews)
    }

    /** Test teardown only. Android process death owns production cleanup; no onTerminate assumption. */
    internal fun close() { if (databaseDelegate.isInitialized()) database.close() }
}

class KareViewModelFactory(
    private val widgets: WidgetRepository,
    private val library: LibraryRepository,
    private val errors: ErrorReporter,
    private val auth: AuthRepository = InMemoryAuthRepository(),
    private val profile: com.example.kare.core.repository.ProfileRepository? = null,
    private val preferences: com.example.kare.core.repository.UserPreferencesRepository? = null,
    private val reviews: com.example.kare.core.repository.ReviewRepository? = null,
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
            com.example.kare.feature.profile.ProfileViewModel::class.java ->
                com.example.kare.feature.profile.ProfileViewModel(
                    profile ?: throw IllegalStateException("ProfileRepository not provided"),
                    library,
                    auth,
                )
            com.example.kare.feature.settings.SettingsViewModel::class.java ->
                com.example.kare.feature.settings.SettingsViewModel(
                    preferences ?: throw IllegalStateException("UserPreferencesRepository not provided"),
                    auth,
                    profile ?: throw IllegalStateException("ProfileRepository not provided"),
                )
            com.example.kare.feature.review.ReviewViewModel::class.java ->
                com.example.kare.feature.review.ReviewViewModel(
                    reviews ?: throw IllegalStateException("ReviewRepository not provided"),
                    auth,
                )
            else -> throw IllegalArgumentException("Unsupported ViewModel: ${modelClass.name}")
        }
        return modelClass.cast(model)!!
    }
}
