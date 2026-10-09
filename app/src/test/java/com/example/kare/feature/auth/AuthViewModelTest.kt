package com.example.kare.feature.auth

import androidx.lifecycle.ViewModelStore
import com.example.kare.core.model.AuthState
import com.example.kare.core.model.AuthUser
import com.example.kare.core.presentation.ErrorReporter
import com.example.kare.core.repository.AuthException
import com.example.kare.core.repository.FakeAuthRepository
import com.example.kare.core.repository.RepositoryException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class AuthViewModelTest {

    private val testDispatcher = StandardTestDispatcher()
    private val viewModelStore = ViewModelStore()
    private val reportedErrors = mutableListOf<Pair<String, Throwable>>()
    private val testErrorReporter = ErrorReporter { op, error -> reportedErrors += op to error }

    private val testUser = AuthUser(
        id = "user-abc",
        email = "alice@example.com",
        displayName = "Alice Wonderland",
    )

    @Before
    fun setUp() {
        Dispatchers.setMain(testDispatcher)
    }

    @After
    fun tearDown() {
        viewModelStore.clear()
        Dispatchers.resetMain()
    }

    private fun createViewModel(
        repository: FakeAuthRepository,
        reporter: ErrorReporter? = testErrorReporter,
    ): AuthViewModel {
        return AuthViewModel(repository, reporter).also {
            viewModelStore.put("authViewModel", it)
        }
    }

    @Test
    fun initialStateIsUnauthenticatedWhenNoUserExists() = runTest {
        val repository = FakeAuthRepository()
        val viewModel = createViewModel(repository)
        runCurrent()

        val state = viewModel.uiState.value
        assertEquals(AuthState.Unauthenticated, state.session)
        assertEquals(AuthActionState.Idle, state.actionState)
        assertFalse(state.isAuthenticated)
        assertNull(state.currentUser)
        assertFalse(state.isLoading)
        assertNull(state.lastError)
    }

    @Test
    fun initialStateReflectsAuthenticatedSessionIfUserAlreadyPresent() = runTest {
        val repository = FakeAuthRepository(initialUser = testUser)
        val viewModel = createViewModel(repository)
        runCurrent()

        val state = viewModel.uiState.value
        assertEquals(AuthState.Authenticated(testUser), state.session)
        assertTrue(state.isAuthenticated)
        assertEquals(testUser, state.currentUser)
    }

    @Test
    fun successfulSignInTransitionsThroughLoadingAndSetsSuccess() = runTest {
        val repository = FakeAuthRepository()
        repository.seedUser("alice@example.com", "secret123", testUser)
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.signIn("alice@example.com", "secret123")
        assertTrue(viewModel.uiState.value.isLoading)
        assertEquals(AuthActionState.Loading, viewModel.uiState.value.actionState)

        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertFalse(state.isLoading)
        assertEquals(AuthActionState.Success(AuthSuccessType.SIGN_IN, testUser), state.actionState)
        assertTrue(state.isAuthenticated)
        assertEquals(testUser, state.currentUser)
        assertEquals(1, repository.signInCalls.size)
    }

    @Test
    fun signInWithEmptyFieldsFailsFastWithInvalidInput() = runTest {
        val repository = FakeAuthRepository()
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.signIn("   ", "")
        assertEquals(AuthActionState.Error(AuthError.INVALID_INPUT), viewModel.uiState.value.actionState)
        assertEquals(0, repository.signInCalls.size)
    }

    @Test
    fun signInWithInvalidCredentialsMapsToSemanticError() = runTest {
        val repository = FakeAuthRepository()
        repository.seedUser("alice@example.com", "correctPass", testUser)
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.signIn("alice@example.com", "wrongPass")
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertFalse(state.isLoading)
        assertEquals(AuthActionState.Error(AuthError.INVALID_CREDENTIALS), state.actionState)
        assertEquals(AuthError.INVALID_CREDENTIALS, state.lastError)
        assertFalse(state.isAuthenticated)
        assertEquals(1, reportedErrors.size)
        assertEquals("signIn", reportedErrors.first().first)
    }

    @Test
    fun signInWithUnregisteredEmailMapsToUserNotFound() = runTest {
        val repository = FakeAuthRepository()
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.signIn("unknown@example.com", "anyPass")
        advanceUntilIdle()

        assertEquals(AuthActionState.Error(AuthError.USER_NOT_FOUND), viewModel.uiState.value.actionState)
    }

    @Test
    fun successfulRegistrationTransitionsStateAndSetsUser() = runTest {
        val repository = FakeAuthRepository()
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.register("Bob Builder", "bob@example.com", "bobSecure99")
        assertTrue(viewModel.uiState.value.isLoading)

        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertFalse(state.isLoading)
        assertTrue(state.actionState is AuthActionState.Success)
        val success = state.actionState as AuthActionState.Success
        assertEquals(AuthSuccessType.REGISTRATION, success.type)
        assertEquals("bob@example.com", success.user?.email)
        assertEquals("Bob Builder", success.user?.displayName)
        assertTrue(state.isAuthenticated)
    }

    @Test
    fun registrationWithWeakPasswordMapsToWeakPasswordError() = runTest {
        val repository = FakeAuthRepository()
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.signUp("Bob", "bob@example.com", "123")
        advanceUntilIdle()

        assertEquals(AuthActionState.Error(AuthError.WEAK_PASSWORD), viewModel.uiState.value.actionState)
        assertFalse(viewModel.uiState.value.isAuthenticated)
    }

    @Test
    fun registrationWithExistingEmailMapsToEmailAlreadyInUse() = runTest {
        val repository = FakeAuthRepository()
        repository.seedUser("alice@example.com", "password123", testUser)
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.register("Duplicate Alice", "alice@example.com", "validPass123")
        advanceUntilIdle()

        assertEquals(AuthActionState.Error(AuthError.EMAIL_ALREADY_IN_USE), viewModel.uiState.value.actionState)
    }

    @Test
    fun registrationWithBlankFieldsFailsWithInvalidInput() = runTest {
        val repository = FakeAuthRepository()
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.register("", "email@example.com", "password")
        assertEquals(AuthActionState.Error(AuthError.INVALID_INPUT), viewModel.uiState.value.actionState)
        assertEquals(0, repository.registerCalls.size)
    }

    @Test
    fun signOutResetsAuthenticatedSessionToUnauthenticated() = runTest {
        val repository = FakeAuthRepository(initialUser = testUser)
        val viewModel = createViewModel(repository)
        runCurrent()
        assertTrue(viewModel.uiState.value.isAuthenticated)

        viewModel.signOut()
        advanceUntilIdle()

        val state = viewModel.uiState.value
        assertEquals(AuthActionState.Success(AuthSuccessType.SIGN_OUT), state.actionState)
        assertFalse(state.isAuthenticated)
        assertEquals(AuthState.Unauthenticated, state.session)
        assertNull(state.currentUser)
        assertEquals(1, repository.signOutCount)
    }

    @Test
    fun resetPasswordSucceedsForRegisteredUser() = runTest {
        val repository = FakeAuthRepository()
        repository.seedUser("alice@example.com", "password", testUser)
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.resetPassword("alice@example.com")
        advanceUntilIdle()

        assertEquals(AuthActionState.Success(AuthSuccessType.PASSWORD_RESET), viewModel.uiState.value.actionState)
        assertEquals(listOf("alice@example.com"), repository.resetPasswordCalls)
    }

    @Test
    fun resetPasswordWithBlankEmailFailsFast() = runTest {
        val repository = FakeAuthRepository()
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.resetPassword("   ")
        assertEquals(AuthActionState.Error(AuthError.INVALID_INPUT), viewModel.uiState.value.actionState)
        assertEquals(0, repository.resetPasswordCalls.size)
    }

    @Test
    fun duplicateActionsWhileLoadingAreIgnored() = runTest {
        val repository = FakeAuthRepository()
        repository.simulatedDelayMs = 500
        repository.seedUser("alice@example.com", "pass", testUser)
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.signIn("alice@example.com", "pass")
        assertTrue(viewModel.uiState.value.isLoading)

        // Second click while loading should be ignored
        viewModel.signIn("alice@example.com", "pass")

        advanceUntilIdle()
        assertEquals(1, repository.signInCalls.size)
        assertFalse(viewModel.uiState.value.isLoading)
        assertTrue(viewModel.uiState.value.isAuthenticated)
    }

    @Test
    fun reactiveAuthStateChangesPropagateDirectlyToSession() = runTest {
        val repository = FakeAuthRepository()
        val viewModel = createViewModel(repository)
        runCurrent()

        assertFalse(viewModel.uiState.value.isAuthenticated)

        repository.setSession(testUser)
        runCurrent()

        assertTrue(viewModel.uiState.value.isAuthenticated)
        assertEquals(testUser, viewModel.uiState.value.currentUser)

        repository.setSession(null)
        runCurrent()

        assertFalse(viewModel.uiState.value.isAuthenticated)
        assertNull(viewModel.uiState.value.currentUser)
    }

    @Test
    fun clearActionStateResetsErrorOrSuccessToIdle() = runTest {
        val repository = FakeAuthRepository()
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.signIn("", "")
        assertEquals(AuthActionState.Error(AuthError.INVALID_INPUT), viewModel.uiState.value.actionState)

        viewModel.clearActionState()
        assertEquals(AuthActionState.Idle, viewModel.uiState.value.actionState)
    }

    @Test
    fun repositoryNetworkFailureMapsToNetworkSemanticError() = runTest {
        val repository = FakeAuthRepository()
        repository.seedUser("alice@example.com", "pass", testUser)
        repository.nextSignInFailure = AuthException.Network()
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.signIn("alice@example.com", "pass")
        advanceUntilIdle()

        assertEquals(AuthActionState.Error(AuthError.NETWORK), viewModel.uiState.value.actionState)
    }

    @Test
    fun repositoryUnavailableFailureMapsToUnavailableSemanticError() = runTest {
        val repository = FakeAuthRepository()
        repository.seedUser("alice@example.com", "pass", testUser)
        repository.nextSignInFailure = AuthException.Unavailable("auth")
        val viewModel = createViewModel(repository)
        runCurrent()

        viewModel.signIn("alice@example.com", "pass")
        advanceUntilIdle()

        assertEquals(AuthActionState.Error(AuthError.UNAVAILABLE), viewModel.uiState.value.actionState)
    }
}
