package com.example.kare.preferences

import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModelStore
import com.example.kare.core.model.*
import com.example.kare.core.preferences.DataStorePreferencesRepository
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.PreferencesRepository
import com.example.kare.feature.settings.*
import com.example.kare.feature.onboarding.OnboardingViewModel
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.test.*
import org.junit.*
import org.junit.Assert.*
import org.junit.rules.TemporaryFolder

class FakePreferences(initial: AppPreferences = AppPreferences()) : PreferencesRepository {
    val value = MutableStateFlow(initial)
    var failure: Exception? = null
    override val preferences: Flow<AppPreferences> get() = flow { failure?.let { throw it }; emitAll(value) }
    override suspend fun setNotificationsEnabled(enabled: Boolean) { failure?.let { throw it }; value.value = value.value.copy(notificationsEnabled = enabled) }
    override suspend fun completeOnboarding() { failure?.let { throw it }; value.value = value.value.copy(onboardingCompleted = true) }
    override suspend fun setLanguage(language: AppLanguage) { failure?.let { throw it }; value.value = value.value.copy(language = language) }
    override suspend fun setAppearance(appearance: AppAppearance) { failure?.let { throw it }; value.value = value.value.copy(appearance = appearance) }
}

@OptIn(ExperimentalCoroutinesApi::class)
class PreferencesTest {
    @get:Rule val temporary = TemporaryFolder()
    private val dispatcher = StandardTestDispatcher()
    private val models = ViewModelStore()
    private val reported = mutableListOf<Throwable>()
    private val errors = ErrorReporter { _, error -> reported += error }
    @Before fun before() { Dispatchers.setMain(dispatcher) }
    @After fun after() { models.clear(); Dispatchers.resetMain() }
    private fun vm(repo: PreferencesRepository) = PreferencesViewModel(repo, errors).also { models.put("preferences", it) }

    @Test fun datastoreDefaultsAndAllPreferencesSurviveReopening() = runTest {
        val file = temporary.root.resolve("preferences.preferences_pb")
        var scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
        fun open() = DataStorePreferencesRepository(PreferenceDataStoreFactory.create(scope = scope, produceFile = { file }))
        val repository = open()
        assertEquals(AppPreferences(), repository.preferences.first())
        repository.setLanguage(AppLanguage.TURKISH)
        repository.setAppearance(AppAppearance.DARK)
        repository.setNotificationsEnabled(false)
        repository.completeOnboarding()
        val expected = AppPreferences(true, AppLanguage.TURKISH, AppAppearance.DARK, false)
        assertEquals(expected, repository.preferences.first())
        scope.coroutineContext[Job]!!.cancelAndJoin()
        scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
        try { assertEquals(expected, open().preferences.first()) }
        finally { scope.coroutineContext[Job]!!.cancelAndJoin() }
    }

    @Test fun startupIsUnknownUntilLoadedAndCompletionTransitionsToMain() = runTest {
        val repo = FakePreferences(); val model = vm(repo)
        assertEquals(StartupState.Loading, model.state.value.startup)
        runCurrent()
        assertEquals(StartupState.Loaded(AppPreferences()), model.state.value.startup)
        model.completeOnboarding(); runCurrent()
        assertTrue((model.state.value.startup as StartupState.Loaded).preferences.onboardingCompleted)
        val recreated = vm(repo); runCurrent()
        assertTrue((recreated.state.value.startup as StartupState.Loaded).preferences.onboardingCompleted)
    }
    @Test fun changesAreReactiveAndNotOptimisticallyPersistedOnFailure() = runTest {
        val repo = FakePreferences(); val model = vm(repo); runCurrent()
        model.language(AppLanguage.TURKISH); runCurrent()
        model.appearance(AppAppearance.DARK); runCurrent()
        assertEquals(AppPreferences(false, AppLanguage.TURKISH, AppAppearance.DARK), (model.state.value.startup as StartupState.Loaded).preferences)
        repo.failure = java.io.IOException("disk")
        model.completeOnboarding(); runCurrent()
        assertEquals(PreferenceError.WRITE, model.state.value.error)
        assertFalse(repo.value.value.onboardingCompleted)
        assertEquals(1, reported.size)
    }
    @Test fun readFailureAllowsExplicitSessionAccessAndRetryWithoutInventingPersistence() = runTest {
        val repo = FakePreferences().apply { failure = java.io.IOException() }
        val model = vm(repo); runCurrent()
        assertEquals(StartupState.Unavailable, model.state.value.startup)
        model.continueForSession()
        assertTrue(model.state.value.sessionOnly)
        assertTrue((model.state.value.startup as StartupState.Loaded).preferences.onboardingCompleted)
        assertFalse(repo.value.value.onboardingCompleted)
        repo.failure = null; model.retry(); runCurrent()
        assertFalse(model.state.value.sessionOnly)
        assertEquals(StartupState.Loaded(AppPreferences()), model.state.value.startup)
    }
    @Test fun cancellationIsNotAUserFacingWriteError() = runTest {
        val repo = FakePreferences(); val model = vm(repo); runCurrent()
        repo.failure = CancellationException()
        model.completeOnboarding(); runCurrent()
        assertNull(model.state.value.error)
        assertTrue(reported.isEmpty())
        assertFalse(model.state.value.saving)
    }
    @Test fun settingsObservesExistingAuthContractAndReportsSignOutFailure() = runTest {
        val user = AuthUser("user", "person@example.com", "Ada")
        val auth = com.example.kare.core.repository.FakeAuthRepository(user)
        val model = SettingsViewModel(auth, errors).also { models.put("settings", it) }
        val collector = backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { model.account.collect() }
        runCurrent()
        assertEquals(AuthState.Authenticated(user), model.account.value)
        auth.nextSignOutFailure = java.io.IOException("session")
        model.signOut(); runCurrent()
        assertTrue(model.signOutFailed.value)
        assertEquals(AuthState.Authenticated(user), model.account.value)
        model.signOut(); runCurrent()
        assertEquals(AuthState.Unauthenticated, model.account.value)
        assertFalse(model.signOutFailed.value)
        collector.cancel()
    }
    @Test fun onboardingPageSurvivesSavedStateRecreationAndDoesNotGoOutOfBounds() {
        val handle = SavedStateHandle(); val model = OnboardingViewModel(handle)
        assertEquals(0, model.page.value)
        model.next(); model.next(); model.previous()
        val recreated = OnboardingViewModel(SavedStateHandle(mapOf("onboarding_page" to model.page.value)))
        assertEquals(1, recreated.page.value)
        repeat(8) { recreated.next() }; assertEquals(3, recreated.page.value)
        repeat(8) { recreated.previous() }; assertEquals(0, recreated.page.value)
    }
}
