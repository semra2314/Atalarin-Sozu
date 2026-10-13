package com.example.kare.feature.settings

import com.example.kare.core.data.auth.InMemoryAuthRepository
import com.example.kare.core.model.AppLanguage
import com.example.kare.core.model.AppTheme
import com.example.kare.core.model.UserProfile
import com.example.kare.core.repository.ProfileRepository
import com.example.kare.core.repository.UserPreferencesRepository
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class SettingsViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private lateinit var authRepository: InMemoryAuthRepository
    private lateinit var fakePreferencesRepository: FakeUserPreferencesRepository
    private lateinit var fakeProfileRepository: FakeProfileRepository
    private lateinit var viewModel: SettingsViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        authRepository = InMemoryAuthRepository()
        fakePreferencesRepository = FakeUserPreferencesRepository()
        fakeProfileRepository = FakeProfileRepository()
        viewModel = SettingsViewModel(fakePreferencesRepository, authRepository, fakeProfileRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun setTheme_updatesUiState() = runTest {
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { viewModel.uiState.collect() }
        viewModel.setTheme(AppTheme.DARK)
        testDispatcher.scheduler.advanceUntilIdle()
        assertEquals(AppTheme.DARK, viewModel.uiState.value.currentTheme)
    }

    @Test
    fun setLanguage_updatesUiState() = runTest {
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { viewModel.uiState.collect() }
        viewModel.setLanguage(AppLanguage.TR)
        testDispatcher.scheduler.advanceUntilIdle()
        assertEquals(AppLanguage.TR, viewModel.uiState.value.currentLanguage)
    }

    @Test
    fun signOut_triggersAuthSignOut() = runTest {
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { viewModel.uiState.collect() }
        authRepository.register("Test User", "user@example.com", "validPass1")
        testDispatcher.scheduler.advanceUntilIdle()
        assertTrue(viewModel.uiState.value.hasAccount)

        viewModel.signOut()
        testDispatcher.scheduler.advanceUntilIdle()
        assertFalse(viewModel.uiState.value.hasAccount)
    }

    private class FakeUserPreferencesRepository : UserPreferencesRepository {
        private val _theme = MutableStateFlow(AppTheme.SYSTEM)
        override val theme: StateFlow<AppTheme> = _theme

        private val _language = MutableStateFlow(AppLanguage.SYSTEM)
        override val language: StateFlow<AppLanguage> = _language

        override suspend fun setTheme(theme: AppTheme) {
            _theme.value = theme
        }

        override suspend fun setLanguage(language: AppLanguage) {
            _language.value = language
        }
    }

    private class FakeProfileRepository : ProfileRepository {
        private val _profile = MutableStateFlow(UserProfile(username = "kare_tester"))
        override val profile: StateFlow<UserProfile> = _profile

        override suspend fun updateProfile(
            displayName: String,
            username: String,
            avatarPath: String?,
        ): Result<Unit> {
            _profile.value = _profile.value.copy(
                displayName = displayName,
                username = username,
                avatarPath = avatarPath,
            )
            return Result.success(Unit)
        }

        override suspend fun refresh() {}
    }
}
