package com.example.kare.feature.settings

import com.example.kare.core.data.auth.InMemoryAuthRepository
import com.example.kare.core.model.AppLanguage
import com.example.kare.core.model.UserProfile
import com.example.kare.core.repository.ProfileRepository
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
    private lateinit var fakePreferencesRepository: com.example.kare.preferences.FakePreferences
    private lateinit var fakeProfileRepository: FakeProfileRepository
    private lateinit var viewModel: SettingsViewModel

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
        authRepository = InMemoryAuthRepository()
        fakePreferencesRepository = com.example.kare.preferences.FakePreferences()
        fakeProfileRepository = FakeProfileRepository()
        viewModel = SettingsViewModel(authRepository, com.example.kare.core.presentation.ErrorReporter { _, _ -> }, fakeProfileRepository)
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    @Test
    fun profileIdentityRemainsReactiveWithoutOwningPreferences() = runTest {
        assertEquals("kare_tester", viewModel.identity.value.username)
        fakeProfileRepository.updateProfile("Ada", "ada", null)
        assertEquals("ada", viewModel.identity.value.username)
    }

    @Test
    fun signOut_triggersAuthSignOut() = runTest {
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) { viewModel.account.collect() }
        authRepository.register("Test User", "user@example.com", "validPass1")
        testDispatcher.scheduler.advanceUntilIdle()
        assertTrue(viewModel.account.value is com.example.kare.core.model.AuthState.Authenticated)

        viewModel.signOut()
        testDispatcher.scheduler.advanceUntilIdle()
        assertFalse(viewModel.account.value is com.example.kare.core.model.AuthState.Authenticated)
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
