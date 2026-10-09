package com.example.kare.core.repository

import com.example.kare.core.model.AuthState
import com.example.kare.core.model.AuthUser
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class AuthRepositoryTest {

    private val testUser = AuthUser(
        id = "user-123",
        email = "test@example.com",
        displayName = "Test User",
    )

    @Test
    fun initialStateReflectsUnauthenticatedWhenEmpty() = runTest {
        val repository = FakeAuthRepository()
        assertNull(repository.currentUser)
        assertEquals(AuthState.Unauthenticated, repository.authState.first())
    }

    @Test
    fun initialStateReflectsProvidedUser() = runTest {
        val repository = FakeAuthRepository(initialUser = testUser)
        assertEquals(testUser, repository.currentUser)
        val state = repository.authState.first()
        assertTrue(state is AuthState.Authenticated)
        assertEquals(testUser, (state as AuthState.Authenticated).user)
    }

    @Test
    fun successfulSignInUpdatesCurrentUserAndAuthState() = runTest {
        val repository = FakeAuthRepository()
        repository.seedUser(testUser.email, "validPassword123", testUser)

        val result = repository.signIn(testUser.email, "validPassword123")
        assertEquals(testUser, result)
        assertEquals(testUser, repository.currentUser)

        val state = repository.authState.first()
        assertTrue(state is AuthState.Authenticated)
        assertEquals(testUser, (state as AuthState.Authenticated).user)
        assertEquals(1, repository.signInCalls.size)
    }

    @Test(expected = AuthException.InvalidCredentials::class)
    fun signInWithWrongPasswordThrowsInvalidCredentials() = runTest {
        val repository = FakeAuthRepository()
        repository.seedUser(testUser.email, "correctPassword", testUser)

        repository.signIn(testUser.email, "wrongPassword")
    }

    @Test(expected = AuthException.UserNotFound::class)
    fun signInWithUnregisteredUserThrowsUserNotFound() = runTest {
        val repository = FakeAuthRepository()
        repository.signIn("nonexistent@example.com", "anyPassword")
    }

    @Test
    fun successfulRegistrationCreatesUserAndUpdatesSession() = runTest {
        val repository = FakeAuthRepository()

        val newUser = repository.register("New User", "new@example.com", "password123")
        assertNotNull(newUser.id)
        assertEquals("new@example.com", newUser.email)
        assertEquals("New User", newUser.displayName)

        assertEquals(newUser, repository.currentUser)
        val state = repository.authState.first()
        assertTrue(state is AuthState.Authenticated)
        assertEquals(newUser, (state as AuthState.Authenticated).user)
    }

    @Test(expected = AuthException.EmailAlreadyInUse::class)
    fun duplicateRegistrationThrowsEmailAlreadyInUse() = runTest {
        val repository = FakeAuthRepository()
        repository.seedUser("existing@example.com", "pass123", testUser)

        repository.register("Another Name", "existing@example.com", "pass123456")
    }

    @Test(expected = AuthException.WeakPassword::class)
    fun registrationWithShortPasswordThrowsWeakPassword() = runTest {
        val repository = FakeAuthRepository()
        repository.register("Name", "valid@example.com", "123")
    }

    @Test
    fun signOutClearsCurrentUserAndEmitsUnauthenticated() = runTest {
        val repository = FakeAuthRepository(initialUser = testUser)
        assertEquals(testUser, repository.currentUser)

        repository.signOut()
        assertNull(repository.currentUser)
        assertEquals(AuthState.Unauthenticated, repository.authState.first())
        assertEquals(1, repository.signOutCount)
    }

    @Test
    fun resetPasswordSucceedsForExistingAccount() = runTest {
        val repository = FakeAuthRepository()
        repository.seedUser(testUser.email, "pass123", testUser)

        repository.resetPassword(testUser.email)
        assertEquals(listOf(testUser.email), repository.resetPasswordCalls)
    }

    @Test(expected = AuthException.UserNotFound::class)
    fun resetPasswordThrowsForMissingAccount() = runTest {
        val repository = FakeAuthRepository()
        repository.resetPassword("missing@example.com")
    }
}
