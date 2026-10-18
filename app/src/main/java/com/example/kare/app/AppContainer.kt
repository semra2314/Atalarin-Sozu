package com.example.kare.app

import com.example.kare.core.data.widget.*
import com.example.kare.widget.ProverbWidget
import com.example.kare.widget.HushWidget
import java.io.File
import kotlinx.coroutines.launch
import kotlinx.coroutines.cancel
import com.example.kare.core.preferences.DataStorePreferencesRepository
import com.example.kare.core.repository.PreferencesRepository
import com.example.kare.feature.settings.*
import com.example.kare.feature.onboarding.OnboardingViewModel
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
    val editableInstances by lazy {
        EditableWidgetRepository(EditableBindingStore(File(applicationContext.noBackupFilesDir, "editable-instances")), localLibrary, errors)
    }
    private val editableSync by lazy {
        EditableWidgetSyncCoordinator(editableInstances,
            { android.appwidget.AppWidgetManager.getInstance(applicationContext).getAppWidgetIds(
                android.content.ComponentName(applicationContext, com.example.kare.widget.EditableReceiver::class.java)) },
            { com.example.kare.widget.EditableWidget.refresh(applicationContext, it) }, errors)
    }
    val library: LibraryRepository by lazy {
        WidgetRefreshingLibraryRepository(localLibrary, { ProverbWidget.refreshAll(applicationContext); HushWidget.refreshAll(applicationContext) }, errors, editableSync::sync)
    }
    private val billingScope = kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.SupervisorJob() + kotlinx.coroutines.Dispatchers.Main.immediate)
    private val playGatewayDelegate = lazy { com.example.kare.core.data.billing.AndroidPlayBillingGateway(applicationContext) }
    private val playGateway get() = playGatewayDelegate.value
    val entitlements by lazy { com.example.kare.core.data.billing.PlayEntitlementRepository(playGateway,
        com.example.kare.core.data.billing.LocalPlayEntitlementVerifier(com.example.kare.core.billing.BillingProductCatalog.products),
        com.example.kare.core.billing.BillingProductCatalog.products) }
    val billing by lazy { com.example.kare.core.data.billing.DefaultBillingRepository(playGateway, entitlements,
        com.example.kare.core.billing.BillingProductCatalog.products, billingScope) }
    private var billingRefresh: kotlinx.coroutines.Job? = null
    fun refreshBilling() {
        if (billingRefresh?.isActive == true) return
        billingRefresh = billingScope.launch { billing.refresh() }
    }
    val preferences: PreferencesRepository by lazy { DataStorePreferencesRepository(applicationContext) }
    val auth: AuthRepository by lazy { InMemoryAuthRepository() }
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
    val viewModelFactory: ViewModelProvider.Factory by lazy { KareViewModelFactory(widgets, library, errors, auth, preferences, profile, reviews, billing, entitlements) }

    /** Test teardown only. Android process death owns production cleanup; no onTerminate assumption. */
    internal fun close() {
        billingScope.cancel()
        if (playGatewayDelegate.isInitialized()) playGateway.close()
        if (databaseDelegate.isInitialized()) database.close()
    }
}

class KareViewModelFactory(
    private val widgets: WidgetRepository,
    private val library: LibraryRepository,
    private val errors: ErrorReporter,
    private val auth: AuthRepository = InMemoryAuthRepository(),
    private val preferences: PreferencesRepository? = null,
    private val profile: com.example.kare.core.repository.ProfileRepository? = null,
    private val reviews: com.example.kare.core.repository.ReviewRepository? = null,
    private val billing: com.example.kare.core.billing.BillingRepository? = null,
    private val entitlements: com.example.kare.core.billing.EntitlementRepository? = null,
) : ViewModelProvider.Factory {
    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        return createModel(modelClass, SavedStateHandle())
    }

    override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T =
        createModel(modelClass, extras.createSavedStateHandle())

    private fun <T : ViewModel> createModel(modelClass: Class<T>, savedState: SavedStateHandle): T {
        val model = when (modelClass) {
            com.example.kare.feature.plus.KarePlusViewModel::class.java -> com.example.kare.feature.plus.KarePlusViewModel(requireNotNull(billing), requireNotNull(entitlements))
            PreferencesViewModel::class.java -> PreferencesViewModel(requireNotNull(preferences), errors)
            OnboardingViewModel::class.java -> OnboardingViewModel(savedState)
            SettingsViewModel::class.java -> SettingsViewModel(auth, errors, profile)
            com.example.kare.feature.editor.EditorViewModel::class.java ->
                com.example.kare.feature.editor.EditorViewModel(savedState["templateId"] ?: "", library, errors)
            DetailViewModel::class.java -> DetailViewModel(savedState["templateId"] ?: "", widgets, library, errors, savedState, entitlements)
            DiscoverViewModel::class.java -> DiscoverViewModel(widgets, errors)
            SearchViewModel::class.java -> SearchViewModel(widgets, errors, savedState)
            LibraryViewModel::class.java -> LibraryViewModel(library, widgets, errors, entitlements)
            AuthViewModel::class.java -> AuthViewModel(auth, errors)
            com.example.kare.feature.profile.ProfileViewModel::class.java ->
                com.example.kare.feature.profile.ProfileViewModel(
                    profile ?: throw IllegalStateException("ProfileRepository not provided"),
                    library,
                    auth,
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
