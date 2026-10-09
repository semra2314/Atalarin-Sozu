# Authentication Migration Notes (Phase: Auth Foundation)

**Owner:** Developer 2  
**Branch:** `android/auth-foundation`  
**Status:** COMPLETED  
**Date:** 2026-10-09  

---

## 1. Phase Objective

Establish the initial Kotlin/Android native authentication foundation for the Kare application without introducing real Firebase SDK dependencies or creating concrete UI screens yet.

This phase provides:
- Decoupled domain models for authentication and session observation (`AuthUser`, `AuthState`).
- An idiomatic Kotlin repository contract (`AuthRepository`).
- Domain-specific authentication exceptions (`AuthException`).
- A presentation-layer `AuthViewModel` with immutable state (`AuthUiState`) and semantic error mapping (`AuthError`).
- An in-memory test fake (`FakeAuthRepository`).
- Thorough JVM unit test coverage verifying states, error mappings, loading lifecycles, and cancellation safety.
- Complete isolation from Developer 1's ongoing work (Template Detail, local installation, library integration).

---

## 2. iOS Functional Reference Inspection

Source inspected: `semra2314/Atalarin-Sozu`, branch `IOS` at pinned commit `41a8fbc67d2992f144383ede02c2ecfd6a73a1a1`.

Key files reviewed:
- `Widgy/Core/Store/AuthService.swift`:
  - Handled Firebase Auth methods: `signIn(with:)` (Apple), `signUp(name:email:password:)`, `logIn(email:password:)`, `sendPasswordReset(to:)`, `signOut()`, `deleteAccount(password:)`, `setDisplayName(_:)`.
  - Maintained static state `isAvailable`, `currentUID`, `currentDisplayName`, `isAppleAccount`.
  - Mapped Firebase error codes (`FIRAuthErrorDomain`) to localized UI strings via `AuthFailure`.
  - Reconciled launch auth state against `UserDefaults` / `OnboardingKeys.hasAccount`.
- `Widgy/Core/Store/ProfileStore.swift`:
  - Stored local avatar image in application support directory (`profile-avatar.jpg`).
- `Widgy/Core/Repositories/PublicProfileService.swift`:
  - Maintained public profile data (`id` = UID, `displayName`, `username`, `avatarData`) mirrored to Firestore.

### Architectural Departures & Kotlin Adaptations
- **No Static/Global Service**: Rather than a static enum/singleton (`AuthService`), Android uses an injectable `AuthRepository` interface and lifecycle-aware `AuthViewModel`.
- **Flow-based Session Observation**: Replaced static queries and ad-hoc launch reconciliations with `Flow<AuthState>`.
- **Pure Domain Boundary**: Domain models (`AuthUser`, `AuthState`) contain zero framework, Compose, or Firebase SDK types.
- **Semantic Errors**: Instead of coupling errors directly to UI strings inside the service, domain errors are represented by `AuthException` and mapped in presentation to semantic `AuthError` codes. UI copy and localization remain exclusively in the future UI presentation layer.
- **Structured Concurrency**: Coroutine cancellation (`CancellationException`) is strictly propagated and never converted into an ordinary error.

---

## 3. Files Created

### Production Source (`app/src/main/java/com/example/kare/`)
1. `core/model/AuthUser.kt`: Domain model for authenticated user identity (`id`, `email`, `displayName`).
2. `core/model/AuthState.kt`: Sealed interface representing observable session state (`Unauthenticated`, `Authenticated`).
3. `core/repository/AuthException.kt`: Domain-specific exceptions inheriting from `RepositoryException`.
4. `core/repository/AuthRepository.kt`: Kotlin repository contract for all authentication operations.
5. `feature/auth/AuthUiState.kt`: Presentation state models (`AuthUiState`, `AuthActionState`, `AuthSuccessType`, `AuthError`).
6. `feature/auth/AuthViewModel.kt`: Android ViewModel managing authentication state flow, operation execution, and error mapping.

### Test Source (`app/src/test/java/com/example/kare/`)
7. `core/repository/FakeAuthRepository.kt`: Configurable in-memory fake for repository contract and ViewModel testing.
8. `core/repository/AuthRepositoryTest.kt`: Unit tests verifying contract behavior and fake repository mechanics.
9. `feature/auth/AuthViewModelTest.kt`: Comprehensive unit tests for ViewModel state transitions, error mappings, loading states, duplicate click protection, and coroutine execution.

### Documentation
10. `docs/AUTH_MIGRATION_NOTES.md`: This migration documentation record.

---

## 4. Repository Contract & ViewModel Design

### `AuthRepository` Interface
```kotlin
interface AuthRepository {
    val authState: Flow<AuthState>
    val currentUser: AuthUser?
    suspend fun signIn(email: String, password: String): AuthUser
    suspend fun register(name: String, email: String, password: String): AuthUser
    suspend fun signUp(name: String, email: String, password: String): AuthUser = register(name, email, password)
    suspend fun signOut()
    suspend fun resetPassword(email: String)
}
```

### `AuthViewModel` & State Architecture
- **Dependency Flow**: `UI -> AuthViewModel -> AuthRepository`.
- **Session State**: Observes `repository.authState` and continually updates `_uiState.session`.
- **Action State**: Tracks interactive actions through `AuthActionState`:
  - `Idle`: No active action.
  - `Loading`: Asynchronous request running.
  - `Success`: Action succeeded with category (`SIGN_IN`, `REGISTRATION`, `SIGN_OUT`, `PASSWORD_RESET`).
  - `Error`: Recoverable failure mapped to semantic `AuthError`.
- **Concurrency & Protection**:
  - Drops duplicate invocations while `isLoading` is true.
  - Never swallows `CancellationException`.
  - Forwards underlying exceptions to diagnostic `ErrorReporter` without leaking them into UI state.

---

## 5. Test Coverage & Results

JVM unit test suites:
- `AuthRepositoryTest`:
  - Initial unauthenticated state vs initial pre-seeded user.
  - Successful sign in session updates and call logging.
  - Sign in failure on invalid credentials (`AuthException.InvalidCredentials`).
  - Sign in failure on nonexistent user (`AuthException.UserNotFound`).
  - Successful registration and state updates.
  - Registration duplicate email failure (`AuthException.EmailAlreadyInUse`).
  - Registration weak password failure (`AuthException.WeakPassword`).
  - Sign out clearing current user and emitting `Unauthenticated`.
  - Password reset success and missing user failure.
- `AuthViewModelTest`:
  - Initial unauthenticated and pre-authenticated state initialization.
  - Sign in loading state, success transition, and user propagation.
  - Sign in blank input fast failure (`AuthError.INVALID_INPUT`).
  - Sign in invalid credentials mapping (`AuthError.INVALID_CREDENTIALS`).
  - Sign in unregistered account mapping (`AuthError.USER_NOT_FOUND`).
  - Registration loading state, success transition, and session update.
  - Registration weak password mapping (`AuthError.WEAK_PASSWORD`).
  - Registration duplicate email mapping (`AuthError.EMAIL_ALREADY_IN_USE`).
  - Registration blank input fast failure (`AuthError.INVALID_INPUT`).
  - Sign out transition to `Unauthenticated`.
  - Password reset success transition and empty email fast failure.
  - Duplicate action prevention while loading.
  - Reactive repository session update propagation to ViewModel state.
  - Resetting action state via `clearActionState()`.
  - Repository transport failure mapping to `AuthError.NETWORK`.
  - Repository service unavailability mapping to `AuthError.UNAVAILABLE`.

---

## 6. Known Limitations & Deferred Work

1. **No Real Firebase SDK Yet**: Real Firebase Auth (`FirebaseAuth.getInstance()`) is deliberately deferred to keep this phase focused on clean contracts and testable domain architecture.
2. **Apple Sign-In / Credential Manager**: iOS Apple Sign-In and future Android Google Sign-In / Credential Manager integration require native Android Activity / intent launchers and will be implemented in the SDK integration phase.
3. **Account Deletion Reauthentication**: iOS `deleteAccount(password:)` requires reauthentication with recent credentials and deletion of Firestore public profiles and reviews. This is deferred until Firestore data sources and security rules are verified.
4. **No Compose UI**: Real authentication screens (Login sheet/screen, Sign up sheet, Password reset dialog) will be created in a subsequent phase once navigation destinations are integrated.

---

## 7. Future Integration Points

When integrating with the rest of the application:
1. **`AppContainer`**: Add `val authRepository: AuthRepository` to `AppContainer`, instantiating `FirebaseAuthRepository` in production and `FakeAuthRepository` in preview/test setups. Provide `AuthViewModel` from `KareViewModelFactory`.
2. **Navigation (`KareNavigation.kt`)**: Add authentication routes (e.g. `AuthRoute`, `SignInRoute`, `SignUpRoute`) to the navigation graph and gate authenticated actions.
3. **Profile Feature (`feature/profile`)**: Connect `ProfileViewModel` with `AuthRepository` for user identity, avatar updates, and sign-out triggers.
4. **Reviews & Firestore**: Wire authenticated user UID into `WidgetRepository.submitReview` and `PublicProfileService`.
