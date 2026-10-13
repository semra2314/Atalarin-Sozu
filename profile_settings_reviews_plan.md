# Migration Plan: Profile, Settings & Reviews System

**Target Branch:** `feature/profile-settings-reviews`  
**Base:** `origin/ANDROID` (incorporating `feature/auth-ui`)  
**Role:** Developer 2  
**Functional Reference:** `semra2314/Atalarin-Sozu` (Branch: `IOS`)  
**Language Rule:** English for code/docs, Turkish for chat communication  

---

## 1. Executive Summary & Scope

This plan covers the concurrent architecture and implementation of two tightly coupled features:
1. **Option 1: Profile & Settings Screens**
   - User identity & avatar storage (`ProfileAvatarStore`)
   - `ProfileScreen` (Header, Avatar/Handle, Guest claim banner, Stats, My Widgets, Favorites)
   - `EditProfileScreen` (Photo picker, Name, Username, Save)
   - `SettingsScreen` (Account info, Guide dialog, Theme/Appearance picker, Language picker, Notification trigger, Privacy & Support links, Sign Out, Account Deletion)
   - Preferences management (Theme, Language, User profile data)
2. **Option 2: Reviews & Ratings System**
   - `Review` domain model & `ReviewRepository` contract
   - Profanity & objectionable content moderation (`ReviewFilter` for EN/TR)
   - Author reporting and user blocking logic
   - `PublicProfile` service/repository (author avatar & handle cache)
   - UI: `StarRating` composable, `ReviewRow`, `ReviewComposer` (bottom sheet dialog), and modular `ReviewSection`

---

## 2. Architecture & Layering Rules

Following `AGENTS.md`:
```
UI (Compose) → ViewModel (StateFlow) → Repository → Local / Remote Data Source
```

- **Compose Screens:** Never touch SDKs, SharedPreferences, or file system directly. Observe state via `StateFlow` from ViewModels.
- **ViewModels:** Depend strictly on `AuthRepository`, `ProfileRepository`, `PreferencesRepository`, and `ReviewRepository`.
- **Cancellation:** Coroutine cancellation is always propagated cleanly without being swallowed.

---

## 3. Option 1: Profile & Settings Architecture

### 3.1. Domain & Data Layer
- **`UserProfile` Model:**
  ```kotlin
  data class UserProfile(
      val uid: String?,
      val displayName: String,
      val username: String,
      val avatarPath: String? = null,
      val hasAccount: Boolean = false
  )
  ```
- **`AppTheme` / `AppLanguage` Enums:**
  - `AppTheme`: `SYSTEM`, `LIGHT`, `DARK`
  - `AppLanguage`: `SYSTEM`, `EN`, `TR`
- **`ProfileAvatarStore`:**
  - Local file storage in `context.filesDir / "profile-avatar.jpg"`.
  - Downscales bitmap to max 400px (matching iOS `ImageDownscaler.downscaledJPEG(imageData, maxDimension: 400)`).
  - Provides atomic save, load, and delete operations.
- **`UserPreferencesRepository`:**
  - Manages theme (`AppTheme`), language (`AppLanguage`), and local profile draft.
  - Backed by Android DataStore / EncryptedSharedPreferences.
- **`ProfileRepository`:**
  - Bridges local identity with `AuthRepository`.
  - Publishes public identity to `PublicProfileRepository` on profile changes.

### 3.2. Presentation Layer
- **`ProfileViewModel`:**
  - Exposes `ProfileUiState`:
    - `userProfile`: Current user's display name, handle, avatar.
    - `isGuest`: True if anonymous/not logged in.
    - `stats`: Widget count, Made count, Favorite count (queried via `LibraryRepository`).
    - `myWidgets`: List of installed widgets.
    - `favoriteWidgets`: Filtered list of favorite widgets.
  - Actions: `onRefresh()`, `onToggleFavorite(widgetId)`.
- **`SettingsViewModel`:**
  - Exposes `SettingsUiState`:
    - `currentTheme`: Current theme preference.
    - `currentLanguage`: Current language preference.
    - `userHandle`: Current user's `@handle`.
    - `hasAccount`: Whether current user is authenticated.
    - `appVersion`: App version string (e.g. `1.0 (1)`).
    - `isDeletingAccount`: Progress state for account deletion.
  - Actions:
    - `setTheme(theme: AppTheme)`
    - `setLanguage(lang: AppLanguage)`
    - `signOut()`
    - `deleteAccount(password: String?)`

### 3.3. UI Components (`feature/profile` & `feature/settings`)
1. **`ProfileScreen`:**
   - Header with "Profile" title and "Edit" action button.
   - `ProfileAvatar` composable: Displays image or serif initial fallback if no image.
   - Claim Profile Card (for guests): Navigates to `SignIn`.
   - Stats row: Widgets / Made / Favorites separated by hairlines.
   - "My Widgets" 2-column grid.
   - "Favorites" list with heart toggle button.
2. **`EditProfileScreen` (Modal/Sheet):**
   - Avatar picker with camera overlay badge.
   - Remove photo button if avatar exists.
   - Name and Username text fields with uppercase/sanitization rules.
   - Save / Cancel actions with public profile sync.
3. **`SettingsScreen`:**
   - Grouped list rows: Account, "How to add a widget" guide, Language, Appearance, Notifications, Privacy Policy, Help & Support.
   - Bottom actions: "Log Out" (or "Start over" for guests), "Delete Account" dialog.
   - Footer: Kare wordmark + `VERSION 1.0 (1)`.
4. **Dialogs & Sheets:**
   - `LanguagePickerSheet` (System, English, Turkish).
   - `AppearancePickerSheet` (System, Light, Dark).
   - `DeleteAccountConfirmationDialog`.

---

## 4. Option 2: Reviews & Ratings Architecture

### 4.1. Domain & Data Layer
- **`Review` Model:** (Already in `core/model/Review.kt`)
  - Added `ReportReason`: `SPAM`, `OFFENSIVE`, `HARASSMENT`, `OTHER`.
- **`ReviewFilter` (Content Moderation):**
  - Identical list of banned words as iOS for both English and Turkish.
  - Method `isObjectionable(text: String): Boolean` prevents submission of inappropriate text.
- **`ReviewRepository` Interface:**
  ```kotlin
  interface ReviewRepository {
      fun observeReviews(templateId: String): Flow<List<Review>>
      suspend fun getReviews(templateId: String): List<Review>
      suspend fun submitReview(templateId: String, stars: Int, text: String): Result<Unit>
      suspend fun deleteMyReview(templateId: String, reviewId: String): Result<Unit>
      suspend fun reportReview(reviewId: String, templateId: String, reason: ReportReason, text: String): Result<Unit>
      suspend fun blockUser(authorId: String): Result<Unit>
      suspend fun isBlocked(authorId: String): Boolean
  }
  ```
- **`InMemoryReviewRepository` (Data Implementation):**
  - Maintains in-memory review collection for catalog templates.
  - Enforces: 1 review per user per template, word filter check, local blocking list, and reported review hiding.
  - Integrates with `AuthRepository.currentUser` to verify authentication before review submission.
- **`PublicProfileRepository`:**
  - In-memory cache of public profiles (`PublicProfile(uid, displayName, username, avatarPath)`).
  - Syncs the author's public profile when reviews are authored or profiles are edited.

### 4.2. Presentation Layer
- **`ReviewViewModel`:**
  - `ReviewUiState`:
    - `reviews`: List of visible reviews (newest first).
    - `userReview`: The review written by the current user (if any).
    - `averageRating`: Calculated average stars.
    - `ratingCount`: Total count of reviews.
    - `isLoading`, `errorMessage`.
  - Actions:
    - `loadReviews(templateId)`
    - `submitReview(stars, text)`
    - `deleteMyReview()`
    - `reportReview(reviewId, reason)`
    - `blockAuthor(authorId)`

### 4.3. UI Composables (`feature/reviews` & `core/ui`)
1. **`StarRating`:** Reusable 1-5 star rating component (supporting both display mode and interactive selection mode).
2. **`ReviewRow`:** Card showing:
   - Author avatar (from `PublicProfile`) + Name + `@handle`.
   - Relative creation date (e.g. "2 days ago", "just now").
   - 1-5 stars display.
   - Review text body.
   - Overflow Menu: "Delete my review" (if own), or "Report review" / "Block this person" (if another's).
3. **`ReviewComposerSheet` (Bottom Sheet):**
   - Modal bottom sheet allowing rating selection (1-5 stars) and review text area.
   - Real-time character limit (1,000 chars) and submit validation.
   - Blocks submission if user is guest with a prompt to sign in.
4. **`ReviewSection` (Standalone Composable):**
   - Can be embedded directly into `DetailScreen` without interfering with Developer 1's ViewModel logic.

---

## 5. Coordination with Developer 1 & Conflict Prevention

1. **Developer 1's Scope:**
   - Template Detail (`DetailViewModel.kt`, `DetailScreen.kt`) and Library/Room installations.
2. **Our Strategy to Avoid Conflicts:**
   - Keep Reviews modular: create `ReviewViewModel` and `ReviewSection` in `com.example.kare.feature.review` or `com.example.kare.feature.detail.review`.
   - Do not rewrite `DetailViewModel.kt`. Developer 1 can simply integrate `<ReviewSection(templateId) />` into `DetailScreen.kt`, or we provide an extension point that does not touch Developer 1's ongoing PRs.
   - Profile and Settings screens are completely isolated in `feature/profile` and `feature/settings`.
3. **Navigation Updates:**
   - In `KareNavigation.kt`, replace `PendingContent` for `Profile` and `Settings` with `ProfileRoute` and `SettingsRoute`.
   - Update `ScreenNavigationTest.kt` to assert Profile/Settings contents rather than placeholder text.

---

## 6. Testing Strategy

1. **Unit Tests:**
   - `ReviewRepositoryTest`: Verify review submission, 1-review-per-user constraint, `ReviewFilter` profanity rejection, reporting, and author blocking.
   - `ReviewViewModelTest`: Verify state transitions, submission errors, deletion, and auth requirements.
   - `ProfileViewModelTest`: Verify user stats computation (widgets, made, favorites) and profile updates.
   - `SettingsViewModelTest`: Verify theme/language changes, sign-out effect, and account deletion.
   - `ProfileAvatarStoreTest`: Verify image downscaling, storage, and deletion.
2. **Robolectric UI Tests:**
   - `ProfileScreenTest`: Profile header, avatar rendering, stats display, guest claim card, favorites list.
   - `SettingsScreenTest`: Settings rows, theme picker dialog, language picker dialog, sign-out dialog.
   - `ReviewSectionTest`: Star rating interaction, review list rendering, review composer bottom sheet.
3. **Regression Tests:**
   - Ensure all 128 existing tests continue to pass (`./gradlew test`).

---

## 7. Step-by-Step Implementation Order

- **Phase A (Foundation & Domain):**
  1. Create models: `UserProfile`, `AppTheme`, `AppLanguage`, `ReportReason`, `PublicProfile`.
  2. Implement `ReviewFilter` with EN/TR wordlists.
  3. Define `ProfileRepository`, `UserPreferencesRepository`, `ReviewRepository`, `PublicProfileRepository`.
  4. Implement `ProfileAvatarStore` (local bitmap scaling & storage).
  5. Implement `InMemoryReviewRepository` and `InMemoryPublicProfileRepository`.
  6. Unit tests for repositories and moderation logic.
- **Phase B (ViewModels & DI):**
  1. Implement `ProfileViewModel`, `SettingsViewModel`, `ReviewViewModel`.
  2. Register new repositories and ViewModels in `AppContainer.kt` and `KareViewModelFactory.kt`.
  3. ViewModel unit tests.
- **Phase C (UI & Compose Screens):**
  1. Implement `StarRating`, `ReviewRow`, `ReviewComposerSheet`, and `ReviewSection`.
  2. Implement `ProfileScreen`, `ProfileAvatar`, `EditProfileScreen`.
  3. Implement `SettingsScreen`, `LanguagePickerSheet`, `AppearancePickerSheet`.
  4. Wire routes in `KareNavigation.kt`.
  5. String resources (`profile_strings.xml`, `settings_strings.xml`, `review_strings.xml` for `values` and `values-tr`).
- **Phase D (Testing & Validation):**
  1. Add Compose Robolectric UI tests.
  2. Run `./gradlew assembleDebug test lint` with English locale parameters.
  3. Update `docs/ANDROID_MIGRATION.md` and documentation logs.
