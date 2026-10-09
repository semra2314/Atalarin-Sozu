# Kare Android migration

## Source

- iOS repository: `semra2314/Atalarin-Sozu`
- iOS branch: `IOS`
- Inspected iOS commit: `41a8fbc67d2992f144383ede02c2ecfd6a73a1a1`
- Android integration branch: `ANDROID` (verified, case-sensitive)
- Analysis date: 2026-10-08

## Objective

Create a native Android version of Kare with functional, data, visual, and
architectural parity where practical. This is not a literal Swift-to-Kotlin
translation. Platform behavior must use appropriate native Android solutions.

Phase 5 adds the Kare design/theme/font and English/Turkish localization foundation.
Phase 4 added application dependency wiring and Discover/Search/Library ViewModels.
Phase 3 added Room-backed local library persistence.
Phase 2 added the bundled catalog, explicit JSON adapters and repository tests.
UI and platform integrations remain deferred.

Phase 1 was limited to source analysis, coordination documentation, package
boundaries, platform-independent models, and repository contracts. Full screens,
Firebase implementations, Room, widgets, billing, and the editor are deferred.

## Android project analysis

The starting project is a single Android application module, not an existing
feature implementation. `MainActivity` renders the generated greeting; the
Material theme, launcher icons, resources, unit test, and instrumented test are
Android Studio starter files. There is no navigation graph, ViewModel, repository,
database, preferences store, Firebase configuration, widget receiver, or billing
integration. The initial working tree was clean.

The existing toolchain is retained: AGP 9.3.3, Gradle 9.5.0, Compose compiler plugin
2.2.10, Compose BOM 2026.02.01, compile SDK 36.1, target SDK 36, minimum SDK 26,
and Java source/target compatibility 11. Namespace and application ID remain
`com.example.kare`; choose the production application ID before Firebase/Play
registration. The starter UI remains unchanged and does not demonstrate parity.

The only added runtime dependency is explicit `kotlinx-coroutines-core:1.9.0`
for the library Flow contract, matching the version already available in the
local dependency cache. Other selected technologies are architectural choices,
not installed or implemented features. No toolchain upgrade is part of Phase 1.

## iOS implementation analysis

Paths below are relative to the pinned iOS checkout, not this Android branch.
This is a source inspection, not an iOS device validation. Inspect updated source
before a later phase if the iOS branch has advanced. The source is available at
[the inspected revision](https://github.com/semra2314/Atalarin-Sozu/tree/41a8fbc67d2992f144383ede02c2ecfd6a73a1a1).

| Component | Actual iOS reference and behavior | Android direction |
|---|---|---|
| Application entry | `Widgy/App/KareApp.swift`: fonts, conditional Firebase initialization, debug Crashlytics collection disabled, auth reconciliation, SwiftData container, subscriptions and launch tasks | Application composition root and lifecycle-aware ViewModels; inject repositories |
| Core models | `Widgy/Core/Models/`: template, author, review, theme, sizes, categories, sections, full editor payload | Plain Kotlin values in `core/model`; UI formatting outside models |
| Catalog | `SampleCatalog.swift`: house creator `a-kare`, fixed live designs plus editable presets, explicit `isEditable`, empty sample reviews | Bundle a versioned catalog in a later phase; preserve IDs and curation order |
| Repository implementations | `WidgetRepository.swift`, `FirebaseWidgetRepository.swift`, `MockWidgetRepository.swift`, `CloudKitWidgetRepository.swift`, `CloudKitCatalogSeeder.swift` | Preserve suspend contract; bundled catalog source and independent remote review source |
| Composition and stores | `Core/Store/AppEnvironment.swift`, `LibraryStore`, `ProfileStore`, `SharedWidgetStore`, `SubscriptionStore` | Constructor injection; repositories own persistence/platform services |
| Navigation | `Navigation/AppRoute.swift`, `AppNavigator.swift`, `RootView.swift`, `RootGate.swift`, `KareTabBar.swift`: Discover, Library, Profile, Search, Settings; separate tab stacks and cross-tab library routing | Navigation Compose, ID-based destinations, native Back and state restoration |
| Design system | `DesignSystem/Theme.swift`, `AppFont.swift`, components: warm light/dark surfaces, coral accent, serif display and sans body, shared spacing/radius tokens | Compose tokens/components in `core/design`, not SwiftUI helpers in models |
| Firebase Auth | `Core/Store/AuthService.swift`: Apple and email/password sign-in, registration, reset, sign-out, recent-login reauthentication and deletion | Auth repository with observable authenticated session; Android provider choice remains open |
| Firestore | `ReviewService.swift`, `PublicProfileService.swift`, `RemovalFeedback.swift` use `reviews`, `profiles`, `reports`, `removalFeedback` | Preserve compatible collections/fields after rules and project configuration are verified |
| Reviews | `reviews/{templateID}_{uid}`; one review per user/template, latest first; moderation filtering, report/block, delete, author lookup | Contract for list/submit now; moderation/account cleanup contracts added with the feature |
| Public profiles | `PublicProfileService.swift`, `Features/Profile/PublicProfileView.swift`: UID, display name, username, small JPEG document bytes, cached reads, user's reviews, report/block | Separate public-profile repository later; value model exists now |
| SwiftData persistence | `InstalledWidget.swift`, `LibraryStore.swift`: unique template ID, offline metadata, theme/content JSON, favorites, ordering, add/remove, widget mirror | Room entities/DAO behind `LibraryRepository`; no direct Compose database queries |
| UserDefaults / AppStorage | `OnboardingKeys.swift`, language/appearance stores, review block/report sets, removal survey throttle, shared widget preferences | DataStore for small preferences; files/Room for images and structured data |
| StoreKit 2 | `SubscriptionStore.swift`: verified entitlements, transaction updates, renewals/revocations, restore; monthly, yearly, lifetime and individual widget products; `subscriptionsAreLive = true` | Google Play Billing plus validated entitlement state; product IDs and cross-platform access policy require decisions |
| WidgetKit target | Xcode embeds `actual-widgetsExtension`; `actual-widgets/actual_widgetsBundle.swift` registers custom Kare, Aurora, Focus, Frame, Hush, Daily, Proverb, Exhale, Countdown, Progress | One Android app with widget providers/receivers; do not migrate the unused example widget as a feature |
| App Groups | `SharedWidgetStore.appGroupID = group.com.zeddy.Widgy`; JSON design files, focus/session and frame files; defaults mirrors | App-private shared storage/repository accessed by app and widget components; no Apple group entitlement |
| Widget configuration | `actual-widgets/KareSelection.swift`, `CountdownEvent.swift`, `LifeProgress.swift`: per-instance design, countdown, measure selection | Configuration activity and persistent appWidgetId-to-content mapping |
| Widget editor | `Features/Editor/WidgetEditorView.swift`, `PhotoCropView.swift`, `CustomWidgetView.swift`: text/style/background/photos/stickers, transforms, duplicate/delete, crop, share, save and mirror | Payload only in Phase 1; later editor ViewModel and renderer, with native image acquisition |
| Onboarding | `OnboardingView.swift`, `OnboardingKeys.swift`: language, slides, aesthetic preferences, sign-in/guest, username; returning-user path | DataStore plus onboarding/auth ViewModels; browsing and private widget creation remain guest-accessible |
| Discover | `DiscoverViewModel.swift`, `DiscoverView.swift`: idle/loading/loaded/failed, refresh, hero, stocked categories and curated shelves | ViewModel + StateFlow + repository |
| Search | `SearchViewModel.swift`, `SearchView.swift`, `CategoryView.swift`: 280 ms debounce, cancellation, optional category; name/summary/tag/author matching | Coroutines with cancellation and stale-result protection; preserve search semantics |
| Library | `LibraryView.swift`, `SetUpOnHomeView.swift`, `RemovalSurveySheet.swift`: offline list, favorite filter, reorder/remove, optional feedback, share and setup | Library ViewModel consumes Flow; library membership is distinct from launcher placement |
| Detail | `TemplateDetailView.swift`, `AuthorView.swift`, `LiveWidgetRender.swift`: sizes, preview, reviews, add/remove, entitlement gate, route to setup/editor | Detail ViewModel composes catalog/library/access contracts; Android preview rendering later |
| Profile | `ProfileView.swift`, `EditProfileView.swift`, `ProfileStore.swift`: local name/handle/avatar, made/favorite counts, own library, public identity publication | Profile repository and ViewModel; private library does not automatically become a public catalog |
| Settings | `SettingsView.swift`, `KarePlusView.swift`, `WidgetUnlockSheet.swift`, `KarePlusGate.swift`: identity, language, appearance, help, purchases, sign-out/deletion | Preferences/auth/billing abstractions; Android settings and purchase flows |
| Daily | `Core/Daily/DailyPassage.swift`, `DailySetupView.swift`, `actual-widgets/DailyWidget.swift`: source choice (quran/bible/stoic/poetry/proverbs), attributed passages selected deterministically by day; midnight refresh request | Persist source, define calendar/timezone behavior and Android refresh strategy |
| Focus | `Core/Focus/FocusSession.swift`, intents, `FocusView.swift`, `FocusAudioPlayer.swift`: stored start/duration/pause state, 25/45/60/90-minute choices, optional bundled ambient sound | Persist timestamps across process death; native widget actions and audio lifecycle; no per-second database polling |
| Frame | `Core/Frame/FramePhoto.swift`, `FrameSetupView.swift`: separate image/metadata, caption/subtitle/card color, 1200px image limit | Photo Picker and durable app-private image copy; metadata behind repository |
| Aurora | `actual-widgets/AuroraWidget.swift`, `Core/WidgetViews/AuroraWidgetView.swift`: clock/date, time-of-day art, one timeline entry and next-hour refresh | Native clock-capable rendering where suitable; battery-aware art updates |
| Proverb / Söz | `Core/Proverb/ProverbLibrary.swift`, `actual-widgets/ProverbWidget.swift`: bundled Turkish sayings/idioms with meanings/examples | Preserve content language and deterministic rotation; do not treat source text as English UI copy |
| Other live widgets | Hush affirmation/time-of-day art; Exhale quit plan/recovery/breath/reset; Countdown multiple themed events; Progress day/week/month/year/life with birthday | Dedicated later features and native widgets; no live-widget business logic ported now |
| Localization | App and extension `Localizable.xcstrings`, `LanguagePreference.swift`, `WidgetLanguage.swift`: English/Turkish plus system choice; widget locale mirror | `values/strings.xml`, `values-tr/strings.xml`, plurals and app locale strategy; localize display text outside domain models |
| Tests | `WidgyTests/WidgyTests.swift`: repository search/fetch/sections/categories and model formatting/theme JSON tests; `WidgyUITests/` mostly launch/performance scaffolding | JVM model/contract tests now, repository tests and Compose/device/widget tests in their respective phases |
| Technical documentation | `ARCHITECTURE.md`, `BACKEND_CLOUDKIT.md`, `MENTOR_NOTES.md`, `LIVE_WIDGETS_SETUP.md`, `WIDGET_EXTENSION_SETUP.md`, `KAREPLUS-SETUP.md`, `TESTFLIGHT.md`, `YOL-HARITASI.md`, font notes and design prompts | Source behavior wins over old plans; maintain this English Android document independently |

### Findings that affect migration scope

- `AppEnvironment.live` selects `FirebaseWidgetRepository`. Its catalog methods
  delegate to the bundled mock with zero delay; only reviews use Firestore. A
  remote catalog is not required to reproduce current behavior.
- `ARCHITECTURE.md` omits the newer review methods. `BACKEND_CLOUDKIT.md` describes
  an alternate backend, not the active one. The Android migration will not copy
  CloudKit or assume that its proposed schemas are live Firebase schemas.
- Several iOS screens directly call stores/services. Preserve the conceptual
  repository architecture, not these boundary violations: all Android feature
  access must go through ViewModels and repositories.
- `WidgyWidget/` contains older extension sources. Use the actual Xcode target and
  `actual-widgets/` bundle as the reference. Focus, Frame, and Daily have duplicated
  app/extension sources; compare both when migrating. Prefer one shared Android
  implementation to source duplication.
- The old widget setup note describes one current design; current source stores
  designs per ID and configures each placed instance independently. The older
  Aurora note describes per-minute timelines; current provider requests hourly
  refreshes and delegates ticking to the system text rendering.
- Catalog author identity is not a Firebase account ID. Sample reviews are empty;
  do not invent published reviews, download counts, or creator accounts.
- Fraunces font files are present; DM Sans is named as an optional fallback but
  no DM Sans file was found in `Widgy/Resources/Fonts`. No bundled MP3 files were
  found. Verify redistribution rights and audio assets before a visual/audio port.
- App localization has 609 keys and extension localization has 147 keys. Both
  contain English/Turkish, with untranslated/new entries; translation completeness
  must be checked rather than assumed.
- No Firestore security rules or `firebase.json` were found in the inspected
  tree. Their deployed configuration and account-deletion behavior remain
  unverified. Source inspection does not prove server-side permissions.

## Architecture mapping

| iOS | Android |
|---|---|
| Swift | Kotlin |
| SwiftUI | Jetpack Compose |
| SwiftData / ModelContainer / @Query | Room / DAO Flow behind repository |
| UserDefaults / AppStorage | DataStore for lightweight preferences |
| NavigationStack / NavigationPath | Navigation Compose with restorable destination IDs |
| Observable / @Observable | ViewModel + StateFlow |
| async / await / Task | Kotlin Coroutines and structured cancellation |
| AppEnvironment / environment injection | KareApplication-owned AppContainer and explicit ViewModel factory |
| WidgetRepository protocol | Kotlin suspend WidgetRepository interface |
| LibraryStore | LibraryRepository / RoomLibraryRepository with transactional DAO writes |
| Firebase Auth | Firebase Auth behind an auth repository |
| Firestore | Firestore SDK behind remote data sources |
| Firebase Crashlytics | Firebase Crashlytics with controlled debug collection |
| CloudKit | Not ported; bundled catalog and Firebase where appropriate |
| WidgetKit | Glance / Android App Widgets, with RemoteViews where needed |
| App Groups | App-private shared storage strategy within the Android package |
| AppIntentConfiguration / AppEntity | Widget configuration activity and per-instance persisted IDs |
| AppIntent actions | Android widget callbacks / PendingIntent actions |
| StoreKit 2 | Google Play Billing, verified entitlements and purchase lifecycle |
| PhotosPicker | Android Photo Picker and durable URI/file handling |
| SF Symbols | Material Icons / Android vector resources with explicit mapping |
| xcstrings | Android string resources and plurals |
| Foundation Date | java.time.Instant for timestamps; explicit transport conversion |
| Decimal | BigDecimal, never binary floating-point money |
| Foundation Data | ImageData with value equality and defensive byte copies |
| Codable | Explicit kotlinx.serialization adapters reused by database mappers |
| AVAudioPlayer / AVAudioSession | Android media playback and audio-focus policy (deferred) |
| Vision subject lifting | Evaluate an Android image-segmentation solution later; no direct API translation |
| ShareLink / ImageRenderer | Android Sharesheet and native bitmap/file rendering |
| Dynamic Type / accessibility labels | Scalable text, Compose semantics, TalkBack and accessibility tests |

The enforced flow is `Screen → ViewModel → Repository → Data Source`. No screen
may directly access Firebase, Firestore, Room, DataStore, networking, or billing.
Repositories expose values, suspend operations, and Flow; SDK errors/types stay
behind the boundary. ViewModels will expose StateFlow when screens are built.
The application-owned container composes real repositories. ViewModels consume
repository interfaces; fake repositories exist only in tests.

## Package structure

All paths below are under `app/src/main/java/com/example/kare/`.
`.gitkeep` files preserve reserved directories in Git; they contain no behavior
and do not mean the associated technology or feature has been migrated.

| Package | Responsibility / current contents |
|---|---|
| `core/model` | Catalog/editor/library/public-profile values; no Android or Compose imports |
| `core/repository` | WidgetRepository, LibraryRepository, RepositoryException |
| `core/data` | Catalog, serialization and Room library repository/mappers |
| `core/database` | KareDatabase v1, internal entity/DAO; exported schema; never exposed to UI |
| `core/preferences` | Future DataStore implementations |
| `core/firebase` | Future Firebase configuration and remote data sources |
| `core/design` | Kare palettes, Material theme, typography, shapes, spacing and layout tokens |
| `core/localization` | UI-only semantic error/category/section resource mappings |
| `navigation` | Future route graph and cross-tab coordination |
| `feature/discover`, `feature/search` | Catalog ViewModels/StateFlow; screens deferred |
| `feature/library`, `feature/detail` | LibraryViewModel; library/detail UI deferred |
| `feature/editor` | Future editing state, actions and canvas |
| `feature/profile`, `feature/settings`, `feature/onboarding` | Future identity/preferences/first-run UI |
| `feature/daily`, `feature/focus`, `feature/frame` | Future live-widget setup/session UI |
| `widget` | Future Android providers, rendering, actions and configuration |

The existing `ui/theme/Theme.kt` delegates to core/design.KareTheme for starter
entry-point compatibility; generated purple tokens and default typography were removed. Additional live-feature packages should be created when those
features are assigned. Keep a single module for now; split modules only when
ownership or build boundaries justify it.

## Model and serialization contracts

Implemented values: `WidgetTemplate` (including Price), `WidgetContent` (including
all text/photo/sticker fields), `WidgetTheme`, `WidgetSize`, `WidgetCategory`,
`Author`, `Review`, `CatalogSection`, `InstalledWidget`, `PublicProfile`, and
`ImageData`. Core models are read-only Kotlin values with no persistence
annotations. Callers should pass owned snapshots rather than mutable collections.

Phase 2 implements explicit JSON-only kotlinx.serialization adapters in
`core/data/serialization`, without annotations or SDK types in domain models.
Swift-exported fixtures exercise the real Codable shapes. Firestore, PublicProfile
adapters remain deferred; InstalledWidget now has explicit Room mapping. Never treat Codable Review JSON
as the Firestore document schema.

| Boundary | Explicit boundary mapping |
|---|---|
| Author | Kotlin `avatarUrl` maps to iOS Codable `avatarURL` |
| Review | Kotlin `templateId` maps to `templateID`; `authorId` maps to Codable `authorID`, but Firestore uses `uid`; Firestore document ID is `{templateID}_{uid}` |
| PublicProfile | Kotlin `avatarData` maps to Firestore `avatar` bytes; `id` is the document UID; `updatedAt` is remote metadata |
| Enums | Use exact `rawValue` tokens, including `accessoryCircular`, `accessoryRectangular`, `compactList`, `topLeading`, `topTrailing`; never ordinal or Kotlin constant names |
| Price | Swift synthesized shape is `{"free":{}}` or `{"paid":{"amount":1.99,"currencyCode":"USD"}}`; retain decimal precision |
| Background | Swift synthesized shape is `{"color":{"_0":["1D1D1F"]}}` or `{"photo":{"_0":"<base64>"}}`; Kotlin sealed types do not automatically encode this way |
| Data / UUID | Swift JSON Data uses base64; image values need explicit conversion; UUIDs use string representations |
| Dates | The inspected stores use default JSONEncoder/JSONDecoder Date handling (seconds since Apple's 2001 reference date), while Firestore uses Timestamp. Do not reinterpret either as Unix milliseconds or assume ISO-8601 |
| CatalogSection | iOS domain section contains resolved `templates` and is not Codable; the alternate CloudKit schema uses ordered `templateIds`. Do not treat it as a live Firestore document shape |
| InstalledWidget | Typed domain snapshot replaces SwiftData raw enums/JSON blobs; Room v1 uses explicit codecs and offline metadata; catalog metadata resolution is in the repository |

The associated-value enum shapes follow Swift's
[Codable synthesis specification](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0295-codable-synthesis-for-enums-with-associated-values.md).

Legacy editor decoding must distinguish an absent/null `texts` field from a
present empty array. iOS lifts nonblank legacy `text` into one TextElement only
when `texts` is absent/null. It uses x = 0.34/0.5/0.66 for leading/center/trailing,
y = 0.24/0.5/0.76 for top/middle/bottom, and carries the original font, size,
weight, color, alignment and spacing. A present empty list stays empty. Missing
new fields and nested element fields use the defaults in `WidgetContent.swift`.
This migration behavior is implemented in the JSON decoder, not the constructor for
new designs. The source default `Your text` is retained for parity; a future
editor should supply localized starter text rather than display this default.

Intentional foundation deviations:

- `Review` rejects stars outside 1..5, including invalid `copy()` calls. Swift's
  initializer silently clamps them. This prevents invalid domain state; a legacy
  importer may explicitly clamp at its boundary to reproduce iOS import behavior.
- `InstalledWidget.isCustomizable` defaults to false rather than the old stored
  SwiftData fallback of true. Repositories must copy the actual catalog flag at
  installation; an unknown fixed design must not accidentally open the editor.
- Library favorite updates set a desired state instead of toggling. Repeated
  requests are idempotent. Removal returns the previous snapshot for later
  feedback. Reorder must atomically validate complete membership.
- SwiftUI colors, fonts, preview aspect ratios, SF Symbol lookups, localized
  display labels, number/price formatting and route construction are not copied
  into domain models. `galleryName` and symbol names remain source metadata only.
- Live-specific models (FocusSession, DailyPassage, FramePhoto, QuitPlan,
  CountdownEvent, progress preferences) remain future work; their persistence
  and lifecycle requirements have been analyzed but not implemented.

## Migration status

Statuses describe the scope named in each row, not a claim of complete app
parity. `COMPLETED` foundation rows have no hidden backend implementation.
Owner `Unassigned` means no active reservation. Developer 1 completed Phase 5. Developer 2 has not started implementation and
has no active ownership; earlier reservations were reassigned for Phase 5.

| Area | iOS reference | Android implementation | Owner | Status | Notes |
|---|---|---|---|---|---|
| Project setup | KareApp / Xcode targets | Existing single module + reserved packages | Phase 1 agent | COMPLETED | Starter UI retained; production ID unresolved |
| Core models | Core/Models | `core/model` values | Phase 1 agent | COMPLETED | Catalog codecs implemented separately; live models deferred |
| Repository architecture | WidgetRepository / LibraryStore | Suspend catalog/review interface + library Flow contract | Phase 1 agent | COMPLETED | Bundled implementation available; Room library implemented; remote implementations deferred |
| Bundled catalog | SampleCatalog / MockWidgetRepository | LocalCatalogDataSource + BundledWidgetRepository | Developer 1 | COMPLETED | 20 templates, 6 sections, lookup/filter/search; no UI |
| Catalog serialization | Codable models | Explicit JSON adapters and Swift fixtures | Developer 1 | COMPLETED | Associated values, dates, images and legacy content; no Firestore adapters |
| Application wiring | AppEnvironment | KareApplication / AppContainer / factory | Developer 1 | COMPLETED | Real repositories; no DI framework |
| Library ViewModel | LibraryStore / @Query | LibraryViewModel / LibraryUiState | Developer 1 | COMPLETED | Reactive list and actions; UI remains NOT STARTED |
| Firebase configuration | KareApp | None | Unassigned | NOT STARTED | Project/Android app registration and rules need verification |
| Firebase Auth | AuthService | None | Unassigned | NOT STARTED | Providers/account linking/deletion policy open |
| Reviews | ReviewService | Review value + list/submit contract only | Unassigned | NOT STARTED | No Firestore, moderation or reporting logic |
| Public profiles | PublicProfileService | Value only | Unassigned | NOT STARTED | No repository implementation/UI |
| Local library | LibraryStore / InstalledWidget | RoomLibraryRepository + explicit mapper | Developer 1 | COMPLETED | Library persistence implemented; widget synchronization deferred |
| Room | SwiftData | KareDatabase v1 / LibraryDao / InstalledWidgetEntity | Developer 1 | COMPLETED | Schema exported; no destructive fallback |
| DataStore | AppStorage / defaults | Reserved `core/preferences` | Unassigned | NOT STARTED | No dependency or implementation |
| Navigation | Navigation/ | Reserved package | Unassigned | NOT STARTED | No graph or routes |
| Discover | DiscoverView / ViewModel | DiscoverViewModel / LoadState | Developer 1 | COMPLETED | Data/state layer only; Compose screen NOT STARTED |
| Search | SearchView / ViewModel | SearchViewModel / SearchUiState | Developer 1 | COMPLETED | Debounce/cancellation/state complete; Compose screen NOT STARTED |
| Template detail | TemplateDetailView | Reserved package | Unassigned | NOT STARTED | No preview/review/purchase UI |
| Library UI | LibraryView | Reserved package | Unassigned | NOT STARTED | No screen |
| Profile | ProfileView / EditProfileView | Reserved package | Unassigned | NOT STARTED | No screen |
| Settings | SettingsView | Reserved package | Unassigned | NOT STARTED | No screen |
| Onboarding | OnboardingView / RootGate | Reserved package | Unassigned | NOT STARTED | No screen or preference flags |
| Editor | WidgetEditorView / WidgetContent | Payload values only | Unassigned | NOT STARTED | Content codecs ready; no editor, renderer or image processing |
| Daily | DailyStore / DailyWidget | Reserved feature package | Unassigned | NOT STARTED | No content/source persistence |
| Focus | FocusSession / FocusView / FocusWidget | Reserved feature package | Unassigned | NOT STARTED | No timer/audio/session logic |
| Frame | FramePhotoStore / FrameWidget | Reserved feature package | Unassigned | NOT STARTED | No photo picker/storage |
| Aurora | AuroraWidget | None | Unassigned | NOT STARTED | Native clock/update design needed |
| Proverb | ProverbLibrary / ProverbWidget | None | Unassigned | NOT STARTED | Turkish source dataset not copied |
| Other live widgets | Hush / Exhale / Countdown / Progress | None | Unassigned | NOT STARTED | Models, setup, renderers and actions deferred |
| Android App Widgets | actual-widgetsExtension | Reserved `widget` | Unassigned | NOT STARTED | No receiver/provider/Glance dependency |
| Kare+ | SubscriptionStore / gates | Price metadata only | Unassigned | NOT STARTED | No entitlement or paywall implementation |
| Google Play Billing | StoreKit 2 | None | Unassigned | NOT STARTED | No product IDs or purchase flows |
| Localization | App Localizable.xcstrings | English/Turkish resources and UI mappings | Developer 1 | COMPLETED | Phase 5: 86 strings + count plural per locale; full app translation deferred |
| Design system | Theme / AppFont / components | core/design + Material theme | Developer 1 | COMPLETED | Phase 5 tokens, three Fraunces weights, no full components/screens |
| Crashlytics | KareApp / FirebaseCrashlytics | None | Unassigned | NOT STARTED | SDK and collection policy deferred |
| Tests | WidgyTests / WidgyUITests | Foundation + catalog/serialization tests | Developer 1 | COMPLETED | 72 JVM tests including design/resources, Room, ViewModels and wiring; device/widget coverage remains NOT STARTED |

## Current work

### Developer 1

Branch: `ANDROID` (verified; no branch changes authorized).

Current tasks: Phase 5 COMPLETED and validated. Owner: Developer 1.
No Phase 6 work started. Completed design/theme/fonts/localization reservations
are released. Future implementation must claim scope here before starting.
Shared hotspots: core/design, theme entry point, string resources and this document.

### Developer 2

Developer 2 has not started implementation. Design system, typography and
localization were initially reserved for Developer 2, but the user temporarily
reassigned them to Developer 1 for Phase 5 on 2026-10-09. Developer 2 currently has
no active implementation ownership. Future work must be explicitly reassigned and
recorded here before Developer 2 starts. No code is attributed to Developer 2.

### Phase 1 session record

Owner: initiating coding agent; human developer identity unassigned.

Branch: `ANDROID` (no branch creation authorized).

Status: COMPLETED. All Phase 1 reservations are released; no active task remains.

Build-file changes: `app/build.gradle.kts` and `gradle/libs.versions.toml`
received an explicit Coroutines dependency for `LibraryRepository`'s Flow
contract. `.gitignore` now excludes Firebase configuration and signing files.
No other dependency setup was part of this phase. These are shared files;
later owners must coordinate edits rather than replace the whole files.

Completed scope: this document, `AGENTS.md`, `core/model`, `core/repository`,
foundation tests, reserved package directories, a minimal dependency adjustment,
and configuration ignore rules. No other active assignments existed in the
repository at the start of this session.

Do not take over another developer's assigned work without explicit authorization.
Future agents must claim scope here before substantial work and release it on
completion. This file and build configuration are shared conflict hotspots.

### Phase 2 scope

Developer 1 is now identified explicitly by the user. Phase 1 is accepted as
complete. Phase 2 implements local catalog data and serialization only, with no
UI, Room/DataStore, Firebase, widgets, billing or editor UI. Catalog artwork names
and shipped text are source data, not a design-system or localization migration.

## Architectural decisions

Chronological log; append a new dated decision when revising a choice rather
than relying on conversation history.

| Date | Decision | Rationale and impact |
|---|---|---|
| 2026-10-08 | Native Android | Kotlin and Jetpack Compose with ViewModel, StateFlow and Coroutines; preserve feature semantics using native lifecycle and navigation |
| 2026-10-08 | CloudKit is not ported | Apple-specific implementation is not the shipping catalog path; avoid a speculative replacement backend |
| 2026-10-08 | Firebase reuse | Reuse Firebase Auth, Firestore and Crashlytics conceptually and share the existing project/data where appropriate, after verifying Android registration and rules; no SDK wiring in Phase 1 |
| 2026-10-08 | Persistence | Room replaces structured SwiftData storage; DataStore holds lightweight preferences; large images remain files. Domain models are separate from entities |
| 2026-10-08 | Repository boundary | Screen → ViewModel → Repository → Data Source, including features where iOS currently bypasses the boundary. Dependencies enter through constructors; SDK details stay private |
| 2026-10-08 | Widgets | Use Glance / Android App Widgets where suitable, with native configuration and update scheduling; WidgetKit timelines are not translated literally |
| 2026-10-08 | Purchases | Google Play Billing replaces StoreKit 2. Access must derive from validated purchase/entitlement state with refresh/revocation handling, never only a local boolean |
| 2026-10-08 | Offline catalog | A later implementation should first port the bundled catalog and curation behavior of FirebaseWidgetRepository, independently of Firestore reviews |
| 2026-10-08 | Model boundary | Instant, BigDecimal, UUID, typed enums, sealed price/background and value-semantic ImageData replace Apple types. UI rendering and localized formatting remain outside domain values |
| 2026-10-08 | Serialization is explicit | Preserve raw values and document wire mappings now; implement DTO/codecs with real iOS fixtures in the data/persistence phase. Do not advertise an untested cross-platform JSON round trip |
| 2026-10-08 | Library contract | Flow observation, suspend writes, one entry per template, idempotent favorite assignment and atomic membership-validated reorder support offline use and safe retries |
| 2026-10-08 | Narrow implementation scope | No full screens, catalog seed, Firebase services, Room/DataStore implementation, live widgets, billing or editor behavior in Phase 1; keep existing starter UI compiling |
| 2026-10-08 | Package and Git strategy | Keep existing namespace and single module. Reserve packages without empty implementation classes. Work on current ANDROID branch as requested; no new branch, commit, merge, or push |
| 2026-10-08 | Ownership and language | Neither human developer is assigned by inference. All migration Markdown is English; feature ownership must be explicitly recorded before work begins |

### 2026-10-08 — Phase 2 decisions

- **Source-derived bundle:** export actual SampleCatalog and MockWidgetRepository
  at the pinned iOS revision, verified against the remote IOS head. Preserve
  ordering, text, prices, categories, themes, content and fixed IDs. Source hashes
  and independently encoded Swift fixtures are checked in for reproducibility.
- **Explicit JSON boundary:** use kotlinx.serialization JSON 1.9.0 with manual
  KSerializer adapters; no compiler plugin, reflection or model annotations.
  Associated values retain Swift case objects, including nested `_0` payloads.
  Decimal amounts and Apple-epoch dates use unquoted numeric tokens to avoid
  Double conversion. Dates retain nanoseconds on Android; Swift Date itself has
  floating-point precision limits. Subnanosecond inputs round half-even.
- **Compatibility policy:** preserve required Codable fields and optional/legacy
  defaults. Ignore additional fields, reject unknown enum cases and wrong types.
  Reject malformed/noncanonical base64, invalid UUIDs, nonfinite doubles, invalid
  review stars and unsupported bundle versions. Numeric input is bounded to 128
  characters and decimal scales -1000..1000 to avoid pathological expansion.
- **Repository:** cache only validated immutable snapshots, perform I/O off the
  caller thread, preserve source ordering and case-insensitive trimmed search
  over name/summary/tags/author with optional category intersection. Unknown IDs
  throw NotFound; malformed bundles throw InvalidData with suppressed diagnostic,
  I/O throws Persistence, and coroutine cancellation propagates.
- **Review boundary:** both review operations throw Unavailable. No in-memory
  review fallback or successful no-op submission; real Firebase review support
  belongs to a later phase. Paid shelf visibility is merchandising, never an
  entitlement or billing implementation.

## Known platform differences

| Concern | Android migration approach / limitation |
|---|---|
| WidgetKit vs Android widgets | Launcher widgets are not full Compose screens. Glance has its own composables; share data and design tokens, not arbitrary UI composables. Complex canvas designs may need bitmap/RemoteViews rendering after a prototype |
| App Groups | No Apple group entitlement or extension file-copy layout. App and widget components use the same app-private persistence strategy. Decide single vs multiple processes before selecting a DataStore access pattern |
| Configurable widgets | Store the selected design/event/measure by Android appWidgetId; handle cancel, reconfigure, deletion and restoration. A library template ID alone is not a placed widget ID |
| Widget sizes | Android launcher sizing/resizing varies. Source small/medium/large remain catalog concepts; accessory sizes are retained as data but do not promise iOS lock-screen equivalents |
| Refresh behavior | Updates are system-constrained and inexact; do not schedule iOS timelines verbatim. Favor updates after data changes and native time display when possible. Prototype Aurora/Focus behavior before promising second-accurate home-screen animations |
| Background execution | Persist durable state rather than rely on a running coroutine. Evaluate WorkManager for deferrable work; any ongoing audio/timer service must fit Android lifecycle and permission requirements |
| Photo access | Prefer Photo Picker. Retain valid grants or copy selected content to app-private files; handle unavailable/revoked sources. Downscale before storage/rendering. Do not request broad storage access just to select a photo |
| Permissions | Request only permissions needed by an implemented feature. Widget pinning, notifications and any foreground work need separate UX; no broad permissions are added by this foundation |
| Navigation and Back | Honor Android system Back and task behavior. Store route IDs and reload data after recreation; do not serialize bitmap/editor payloads into navigation arguments |
| Lifecycle and process death | ViewModels manage screen state, not durable ownership. Reconstruct library, editor drafts, widget config and focus deadlines from persistence. Inject clocks for deterministic time tests |
| Purchases | Google Play product IDs and purchase tokens are distinct from StoreKit transactions. Plan pending/cancelled/refunded/restored states, verification and acknowledgement; cross-store entitlement sharing requires an explicit backend policy |
| Symbols and artwork | SF Symbol identifiers need an Android mapping/fallback and compatible assets. Preserve raw source identifiers for imports; do not treat them as Android resource IDs |
| UI effects | SwiftUI glass, zoom/matched-geometry transitions, haptics and native sheets need appropriate Android equivalents. Respect reduced motion, font scaling and TalkBack rather than force Apple behavior |
| Shared image storage | The launcher runs outside the app; widgets must receive supported rendered content/URIs with the needed access, not arbitrary private file paths. Persist app/widget state independently of process memory |
| Subject lifting | Vision cutouts have no literal platform port. Evaluate quality, device support and licensing of a native Android solution in the editor phase |
| Localization | Keep English and Turkish UI resources separate from user-authored content and Turkish proverb data; decide how app locale affects widgets and daily content |

Phase 2 catalog differences:

- Relative Swift `.now` publication dates are frozen at `2026-10-08T00:00:00Z`
  with the original offsets; randomly initialized editor element UUIDs become
  deterministic UUIDs. Template IDs are unchanged. This avoids changing identity
  and publication time each time the app loads or the export runs.
- CatalogSection is not Codable in iOS. The bundle uses ordered `templateIds`,
  resolved to shared templates on load; its standalone Android adapter uses
  resolved `templates`. Neither is asserted to be a Firestore section schema.
- Swift Codable data compatibility does not imply Firestore compatibility.
  Review `uid`/Timestamp/document-ID mappings remain future infrastructure work.
- No mock network delay or generated reviews. Source artwork names and SF Symbol
  tokens are metadata; their Android assets/rendering are not implemented.
- Original catalog prose is preserved as source content. Developer 2's UI
  localization resources are independent and unchanged.

Android references checked during analysis:
[Glance rendering boundary](https://developer.android.com/develop/ui/compose/glance),
[widget update considerations](https://developer.android.com/develop/ui/views/appwidgets/advanced),
and [widget configuration lifecycle](https://developer.android.com/develop/ui/views/appwidgets/configuration).
Recheck API-specific constraints when implementing those features.

## Recommended next phase and parallel work

Recommended Phase 6: Navigation Compose and initial Discover, Search and Library
screens using the existing factory/ViewModels, core/design.KareTheme and localized
resources. Include native Back, lifecycle-aware collection, query/filter restoration,
accessibility and empty/error/action states. No navigation or full screen was added
in Phase 5. These recommendations do not authorize starting work or branch changes.

Developer 2 has no active implementation ownership. Suitable future assignments
include accessibility/localization review and tests, or Profile/Settings presentation
after contracts are agreed. Reassign and reserve scope here before work begins;
previous design/localization reservations no longer apply.

### Conflict hotspots

- `docs/ANDROID_MIGRATION.md`: both developers must append logs and update their
  ownership/status without overwriting the other's work.
- `AGENTS.md`: shared permanent rules; change deliberately, not as a task log.
- `gradle/libs.versions.toml`, `app/build.gradle.kts`, root Gradle files: serialize
  dependency/plugin changes through an agreed owner.
- `core/model/*`, `core/repository/*`: shared contracts; agree changes before
  adapting feature implementations. Preserve raw values and explicit wire mapping.
- `MainActivity.kt`, `AndroidManifest.xml`, future composition root and navigation
  graph: integration points requiring a designated owner.
- `ui/theme/*`, future `core/design/*`, shared `strings.xml`, fonts and drawable
  names: use feature-specific resources where practical and coordinate renames.

## Open questions and blockers

There is no known Phase 5 implementation blocker. The following are unresolved
inputs or design questions for later phases, not claims that work has started:

- Developer 2 future scope/branch must be assigned before implementation; no work
  has started. Any feature branch operation still requires authorization.
- Final Android application ID and Firebase Android registration; shared project
  access, deployed Firestore rules/indexes, moderation permissions and account
  deletion consistency. Do not infer these from client Swift code.
- Auth provider parity: how existing Apple-created Firebase accounts sign in on
  Android, and whether another provider/account-linking flow is wanted.
- Room schema and library payload format start at version 1. Future version upgrades
  need explicit migrations and preservation tests. PublicProfile adapters remain
  deferred. Catalog JSON schema is version 1; unsupported versions fail.
- Play products, verification backend, restore/expiry behavior, and whether
  iOS purchases should grant Android access. App Store product IDs are not Play
  product definitions; catalog prices are not checkout prices.
- Widget rendering fidelity, support for source accessory sizes, launcher size
  mapping, update strategy and per-instance configuration/restore behavior.
- Font/art/audio redistribution and availability; the current optional audio
  choices have no matching MP3 files in the inspected source tree.
- Daily content attribution/licensing verification and timezone/day-index parity.
  Source comments are not a completed rights audit. Exhale health estimates and
  disclaimers need a dedicated content review when that feature is migrated.
- No device/emulator UI, widget, billing or Firebase test has run in this phase;
  those features do not exist on Android yet.

## Validation

Run on 2026-10-08, branch `ANDROID`, after the foundation changes:

| Command | Result |
|---|---|
| `./gradlew assembleDebug` | PASS; also passed on the untouched starter baseline |
| `./gradlew test` | PASS; testDebugUnitTest ran 9 tests: 8 new ModelContractTest cases and 1 existing starter test; 0 failures/errors/skips |
| `./gradlew lint` | PASS; 0 errors, 20 warnings |
| `git diff --check` | PASS |

Model tests pin source enum raw values, exact decimal preservation, template size
fallback, image value equality/hash and defensive copying, image-bearing payload
equality, sticker tintability, and invalid review ratings (including copy).
These do not claim a JSON round trip, repository implementation validation, or
feature parity. No instrumentation/emulator test was run.

Lint warnings: existing target/compile SDK and tool/dependency version notices,
the starter manifest's redundant activity label, and seven unused starter color
resources. The added Coroutines 1.9.0 dependency also receives a newer-version
notice; it is intentionally pinned to an already available compatible version
for this foundation, not presented as the latest release. No lint rules were
disabled and no baseline/suppression was introduced. The build also reports that
`libandroidx.graphics.path.so` could not be stripped and was packaged unchanged;
this is a dependency packaging warning, not a new native library in this phase.

Local reports (generated/ignored, not source-controlled):

- `app/build/reports/tests/testDebugUnitTest/index.html`
- `app/build/reports/lint-results-debug.html`
- `app/build/reports/lint-results-debug.xml`

Environment note: the sandbox initially blocked the Gradle cache lock under
`~/.gradle`; commands succeeded with the approved cache access. The iOS read-only
download also required network access. No machine paths/configuration were added
to build files, and the Android branch/history was not changed.

## Work log

### 2026-10-08 — Phase 1 analysis started

- Branch: `ANDROID`.
- Owner: initiating coding agent (human developer unassigned).
- Android inspection: clean Git working tree, one `app` module, namespace and
  application ID `com.example.kare`, minimum API 26, target API 36, compile API
  36.1, AGP 9.3.3, Gradle 9.5.0, Compose starter activity and theme only.
- iOS reference downloaded outside this repository for read-only inspection.
  No iOS configuration or credentials copied into Android.
- Important finding: the live iOS repository uses bundled `SampleCatalog` data
  plus Firestore reviews. Older architecture and CloudKit notes are not an
  accurate description of the shipping composition root.
- Remaining work: complete source inventory, implement foundation, validate,
  and finalize the status tables and decisions below.

### 2026-10-08 — Phase 1 foundation completed

Branch: `ANDROID`.

Owner: initiating coding agent (human developer unassigned).

Implemented:

- English permanent agent instructions and this shared source-of-truth document.
- Source analysis pinned to iOS commit `41a8fbc67d2992f144383ede02c2ecfd6a73a1a1`,
  including entry, models, repositories/stores, features, Firebase usage,
  persistence/preferences, navigation/design, purchases, widget targets and
  configuration, localization, tests, and existing technical notes.
- Eleven Kotlin model files covering the requested core values, editor elements,
  offline library snapshot and public identity; three repository contract/error
  files; eighteen tracked package directory markers.
- Eight model-contract tests, explicit Coroutines dependency, and sensitive
  Firebase/signing file ignore rules.

Important decisions:

- Match current bundled-catalog/Firestore-review architecture rather than stale
  CloudKit plans. Keep infrastructure and display helpers outside domain values.
- No production fake implementations, SDK provisioning, full UI or complex
  platform features. Existing activity/theme remain the starter implementation.
- Prepare wire contracts without claiming serialization parity; future codecs
  require iOS fixtures and explicit legacy migrations.
- Record ownership as unassigned rather than attribute work to the wrong person.

Issues encountered and resolution:

- Sandbox prevented initial cache/network access; approved execution succeeded.
- Older iOS docs disagree with current app composition/widget/purchase behavior;
  discrepancies and pinned references are captured above.
- All required checks pass; remaining lint and native-symbol packaging warnings
  are documented without suppressions.

Unresolved issues and follow-up:

- See Open questions and blockers; none prevents this foundation from compiling.
- Next phase should implement bundled catalog/data adapters and their tests;
  Developer 2 can independently prepare design tokens/localization after claiming
  ownership. Room work is another option once codec contracts are agreed.
- All Phase 1 reservations released. No commits, pushes, branch operations,
  merges or history rewrites were performed. Stop here pending further scope.

## Phase 1 file manifest

Source-controlled deliverables only; generated build reports/APKs and the
external temporary iOS checkout are excluded. All new Markdown is English.

Created (35 files):

- `AGENTS.md`
- `app/src/main/java/com/example/kare/core/data/.gitkeep`
- `app/src/main/java/com/example/kare/core/database/.gitkeep`
- `app/src/main/java/com/example/kare/core/design/.gitkeep`
- `app/src/main/java/com/example/kare/core/firebase/.gitkeep`
- `app/src/main/java/com/example/kare/core/model/Author.kt`
- `app/src/main/java/com/example/kare/core/model/CatalogSection.kt`
- `app/src/main/java/com/example/kare/core/model/ImageData.kt`
- `app/src/main/java/com/example/kare/core/model/InstalledWidget.kt`
- `app/src/main/java/com/example/kare/core/model/PublicProfile.kt`
- `app/src/main/java/com/example/kare/core/model/Review.kt`
- `app/src/main/java/com/example/kare/core/model/WidgetCategory.kt`
- `app/src/main/java/com/example/kare/core/model/WidgetContent.kt`
- `app/src/main/java/com/example/kare/core/model/WidgetSize.kt`
- `app/src/main/java/com/example/kare/core/model/WidgetTemplate.kt`
- `app/src/main/java/com/example/kare/core/model/WidgetTheme.kt`
- `app/src/main/java/com/example/kare/core/preferences/.gitkeep`
- `app/src/main/java/com/example/kare/core/repository/LibraryRepository.kt`
- `app/src/main/java/com/example/kare/core/repository/RepositoryException.kt`
- `app/src/main/java/com/example/kare/core/repository/WidgetRepository.kt`
- `app/src/main/java/com/example/kare/feature/daily/.gitkeep`
- `app/src/main/java/com/example/kare/feature/detail/.gitkeep`
- `app/src/main/java/com/example/kare/feature/discover/.gitkeep`
- `app/src/main/java/com/example/kare/feature/editor/.gitkeep`
- `app/src/main/java/com/example/kare/feature/focus/.gitkeep`
- `app/src/main/java/com/example/kare/feature/frame/.gitkeep`
- `app/src/main/java/com/example/kare/feature/library/.gitkeep`
- `app/src/main/java/com/example/kare/feature/onboarding/.gitkeep`
- `app/src/main/java/com/example/kare/feature/profile/.gitkeep`
- `app/src/main/java/com/example/kare/feature/search/.gitkeep`
- `app/src/main/java/com/example/kare/feature/settings/.gitkeep`
- `app/src/main/java/com/example/kare/navigation/.gitkeep`
- `app/src/main/java/com/example/kare/widget/.gitkeep`
- `app/src/test/java/com/example/kare/core/model/ModelContractTest.kt`
- `docs/ANDROID_MIGRATION.md`

Modified (3 files):

- `.gitignore`
- `app/build.gradle.kts`
- `gradle/libs.versions.toml`

No existing source files were deleted or renamed.

## Phase 2 work log and file manifest

### 2026-10-08 — Bundled catalog and serialization completed

Branch: `ANDROID`. Owner: Developer 1. Status: COMPLETED.

Implemented 20 source templates, six discover shelves, stable lookup, category
filtering, trimmed case-insensitive search and explicit unavailable review
operations. Preserved all important live/custom/preset IDs and setup/Kare+ helper
mappings. The bundle has 13 free and seven paid templates; paid prices are catalog
metadata only. No UI, design, localization, persistence or backend implementation
was changed. Existing model and repository contracts and AGENTS.md are unchanged.

Created files:

- `app/src/main/java/com/example/kare/core/data/catalog/LocalCatalogDataSource.kt`
- `app/src/main/java/com/example/kare/core/data/catalog/BundledWidgetRepository.kt`
- `app/src/main/java/com/example/kare/core/data/serialization/JsonFields.kt`
- `app/src/main/java/com/example/kare/core/data/serialization/SwiftValueSerializers.kt`
- `app/src/main/java/com/example/kare/core/data/serialization/WidgetContentSerializer.kt`
- `app/src/main/java/com/example/kare/core/data/serialization/CatalogSerializers.kt`
- `app/src/main/java/com/example/kare/core/data/serialization/CatalogJson.kt`
- `app/src/main/resources/catalog/kare-catalog-v1.json`
- `app/src/test/java/com/example/kare/core/data/CatalogTest.kt`
- `app/src/test/java/com/example/kare/core/data/SerializationTest.kt`
- `app/src/test/resources/catalog/ios-wire-fixtures.json`
- `app/src/test/resources/catalog/ios-source-manifest.json`
- `scripts/export_ios_catalog.py`

Modified files:

- `app/build.gradle.kts`: JSON runtime dependency only.
- `gradle/libs.versions.toml`: serialization version and library alias only.
- `docs/ANDROID_MIGRATION.md`: status, ownership, contracts, decisions, differences,
  next phase, validation and this manifest.

Reproduce the bundle and fixtures with a local checkout of the pinned iOS commit
and a macOS Swift toolchain:

```sh
python3 scripts/export_ios_catalog.py /path/to/ios-checkout
```

The script verifies the revision and records input hashes; it neither downloads
source nor modifies Git state. Use `--output-root /tmp/kare-export` to compare
without replacing checked-in resources. Re-export was verified byte-for-byte
identical for all three JSON files. The catalog resource was also verified inside
the debug APK. Normal Android builds do not require Swift or the iOS checkout.

Twenty new JVM tests cover catalog loading, unique/source IDs, known/missing
lookup, all category filters, search/locale behavior, section membership/order,
unavailable reviews, concurrent caching, retry after failure, malformed bundles,
cancellation, all exported template round trips, Swift fixtures, exact decimal
and date precision, both associated-value families, binary images, legacy text
migration/defaults, invalid inputs and the explicit section shape.

Initial validation caught numeric rounding through JsonPrimitive(Number) and
attempting to initialize an exception cause already set by its base class. Both
were fixed: explicit numeric literals preserve precision, and suppressed
serialization diagnostics preserve the existing domain error contract.

Remaining work: Room/library storage schema and converters, ViewModels and UI,
real review infrastructure and resource rendering. No Phase 2 blocker remains.
Shared conflict hotspots are the migration document and both Gradle files.
Developer 2 retains design/theme/typography/localization ownership; Phase 2
reservations are released. No commit, push, merge or branch change was made.

### Phase 2 final validation

Run on 2026-10-08 on `ANDROID`:

| Command | Result |
|---|---|
| `./gradlew assembleDebug` | PASS |
| `./gradlew test` | PASS; 29 JVM tests, zero failures/errors (20 new, 9 existing) |
| `./gradlew lint` | PASS; zero errors, 21 warnings |
| `git diff --check` | PASS |

Gradle tasks were run together in the final successful invocation. Lint warnings
are version/update notices and existing starter resource/manifest warnings; the
serialization dependency adds one version notice compared with Phase 1. No lint
rule, compiler setting or baseline was weakened. No device test was run: this
phase implements data behavior only. The initial cache restriction required
approved Gradle cache access. Build reports remain generated and ignored.

## Phase 3 persistence architecture and source analysis

Owner: Developer 1. Branch: `ANDROID`. Source IOS head reconfirmed as
`41a8fbc67d2992f144383ede02c2ecfd6a73a1a1` on 2026-10-08.

Inspected `Widgy/Core/Store/InstalledWidget.swift`, `LibraryStore.swift`,
`SharedWidgetStore.swift`, `Core/LiveWidgets/KarePlusAccess.swift` (LibraryMirror),
LibraryView removal/reordering/favorites, TemplateDetailView installation/removal,
WidgetEditorView saving/downscaling/mirroring, and WidgyTests. Source tests cover
theme JSON but contain no library persistence tests. Source comments about a
remote catalog and initially nil preset content are stale: install seeds the
actual template payload and current catalog is bundled.

### SwiftData → Room

The flow remains `UI → ViewModel → LibraryRepository → Room DAO/database`.
KareDatabase is opened using the application context; a future composition root
must retain one instance per process. This phase does not wire it into starter UI.
Room entities and DAO are internal persistence types, and domain models/contracts
are unchanged. Repository calls are main-safe, use structured coroutines and
perform JSON work on Dispatchers.IO. Flow emits only committed ordered snapshots.
No repository-owned CoroutineScope or main-thread database access is enabled.

Schema version 1 has one table, `installed_widgets`:

| Columns | Persistence meaning |
|---|---|
| `templateId` TEXT primary key | One installation per template; no catalog foreign key so retired designs survive |
| `name`, `authorName` TEXT | Cached offline identity/display metadata |
| `categoryRaw`, `sizeRaw` TEXT | Stable source raw enum tokens, never Kotlin ordinals |
| `themeJson`, `contentJson` nullable TEXT | Existing Phase 2 codecs, including images/gradients/text/photo/sticker payloads |
| `payloadVersion` INTEGER | Version 1; reject unsupported versions rather than reinterpret them |
| `addedAtSeconds`, `addedAtNanos` INTEGER | Unix epoch seconds plus nanoseconds, preserving Instant precision |
| `isFavorite`, `isCustomizable` INTEGER | Favorite state and cached fixed/editable metadata |
| `sortIndex` INTEGER | Ordered by index, then templateId for deterministic ties |
| `previewImageName` nullable TEXT | Cached source artwork identifier |

Explicit mapper methods handle entity/domain conversion. No TypeConverter is
needed: JSON is encoded exactly once at the boundary using established adapters.
SQL timestamp columns deliberately differ from Swift Codable's Apple epoch;
embedded content/theme retain the Phase 2 wire format. The nullable payload state
is preserved; malformed data is an error, not silently converted to null.

Room 2.8.4, KSP 2.3.6 and Robolectric 4.16.1 are pinned; the existing toolchain is
unchanged. Configuration follows [Room's setup/schema guidance](https://developer.android.com/jetpack/androidx/releases/room)
and [AGP built-in Kotlin guidance](https://developer.android.com/build/migrate-to-built-in-kotlin).
Robolectric runs real generated Room DAO code with native SQLite on SDK 28.
Schema export is enabled through the Room Gradle plugin and checked in under
`app/schemas/com.example.kare.core.database.KareDatabase/1.json`. There is no
previous Android database to migrate. Future changes must increment the schema
version and add explicit migrations with preservation tests. No destructive
migration fallback, downgrade wipe or prepackaged database is configured.

### Repository behavior and intentional differences

- Installation is transactional and idempotent, including simultaneous calls.
  Existing content, favorite, size and installation date are retained. New entries
  copy metadata/theme/content, validate supported size, and append after the
  largest sortIndex instead of iOS's potentially colliding row count.
- `widget(id) != null` determines installation; `observeWidgets()` supplies the
  ordered library. No public interface additions are necessary.
- `setFavorite(id, desiredState)` supports toggling by choosing the opposite state
  while preserving retry idempotence. Missing IDs raise NotFound. No separate
  read-modify-write toggle API was added.
- Remove returns the previous domain snapshot, is idempotent, and compacts remaining
  order within the same transaction. Removal survey timing stays outside persistence.
- Reorder requires the entire current membership exactly once and writes atomically;
  stale/partial/duplicate orders fail without changing rows.
- Content updates reject missing or currently fixed designs. Author, editability
  and fixed preview art resolve from the current bundled catalog in the repository,
  matching iOS's computed metadata behavior without putting catalog access inside
  models. Retired templates fall back to their stored metadata. User name, theme,
  content, size and order are never overwritten by metadata resolution.
- Persisted strings together are limited to 512 KiB per row to stay comfortably
  below Android cursor-window limits, including base64 image expansion. Oversized
  writes fail before mutation. Later photo/editor work must resize images or move
  larger images into durable app-private files with migration/cleanup rules. This
  is an intentional Android constraint, not silent image truncation.
- Unknown raw enums/version, invalid timestamps/order and corrupt JSON fail
  explicitly; iOS often substitutes defaults or ignores decode/save failures.
  SQLite/I/O failures map to Persistence, serialization failures to InvalidData;
  cancellation propagates. Corrupt rows remain stored for future recovery tooling.

### App Groups / SharedWidgetStore → deferred Android widget-state architecture

No App Group directories, mirror JSON files, LibraryMirror preferences or WidgetKit
reload calls are ported. Android app and widget components can access app-private
Room state through repository boundaries. Library membership remains distinct
from launcher placement. A later widget phase needs durable appWidgetId-to-design
configuration, deletion/reconfiguration/restore rules, suitable rendered images
or URI access, and a post-commit refresh/reconciliation mechanism that survives
process death. Prefer the same app process initially; multiple processes require
an explicit invalidation/concurrency design. Room Flow alone does not schedule
launcher refreshes. Do not mirror data in this phase or claim widget updates work.

### 2026-10-08 — Phase 3 architectural decisions

1. Keep LibraryRepository unchanged; implement native transactions and Flow.
2. Store standalone offline snapshots; resolve the three live metadata fields in
   the repository and retain fallback metadata for retired templates.
3. Reuse versioned JSON codecs; export schema v1; forbid destructive fallback.
4. Bound embedded row payloads and reject corruption explicitly rather than lose
   user data silently. Defer file-backed images and recovery UI to dedicated work.
5. Defer all App Widget synchronization and placement state; introduce no unused
   synchronization abstraction or platform side effects.

### Phase 3 work log / file manifest

Date: 2026-10-08. Owner: Developer 1. Branch: `ANDROID`.

Created:

- `app/src/main/java/com/example/kare/core/database/InstalledWidgetEntity.kt`
- `app/src/main/java/com/example/kare/core/database/LibraryDao.kt`
- `app/src/main/java/com/example/kare/core/database/KareDatabase.kt`
- `app/src/main/java/com/example/kare/core/data/library/InstalledWidgetMapper.kt`
- `app/src/main/java/com/example/kare/core/data/library/RoomLibraryRepository.kt`
- `app/schemas/com.example.kare.core.database.KareDatabase/1.json`
- `app/src/test/java/com/example/kare/core/data/library/InstalledWidgetMapperTest.kt`
- `app/src/test/java/com/example/kare/core/data/library/RoomLibraryRepositoryTest.kt`

Modified:

- `app/build.gradle.kts`: Room/KSP plugins, schema export, runtime/compiler/test dependencies and Android-resource unit tests.
- `gradle/libs.versions.toml`: pinned Room/KSP/Robolectric aliases.
- `docs/ANDROID_MIGRATION.md`: ownership, status, architecture, decisions, source analysis and work log.

Shared-file risk was recorded before implementation. AGENTS.md, models, public
contracts, catalog codecs and all Developer 2 areas are unchanged. No Git branch,
commit, push, merge or history operation was performed. Initial test compilation
caught an incorrect Robolectric getApplication type argument; corrected without
weakening checks. Remaining work is application wiring, ViewModels/UI, widget
state synchronization and future schema migrations/image storage policy.

### Phase 3 final validation and completion

Status: COMPLETED. Owner: Developer 1. Branch: `ANDROID`. Date: 2026-10-08.

| Command | Result |
|---|---|
| `./gradlew assembleDebug` | PASS |
| `./gradlew test` | PASS; 46 tests, zero failures/errors/skips; 17 new persistence tests |
| `./gradlew lint` | PASS; zero errors, 26 warnings |
| `git diff --check` | PASS |

Final Gradle validation ran the three requested tasks together. The 17 new tests
cover both mapper directions across all catalog templates, binary/null payloads,
precise timestamps, invalid values, installation/retrieval, concurrent duplicates,
favorite changes/retries, removal, content updates, fixed-design protection,
reordering and invalid membership, current/retired metadata, reactive reads,
corrupt JSON, payload limits, disk close/reopen, cancellation, and rollback after
an injected SQLite failure during reorder. Room tests use native SQLite under
Robolectric; no emulator/device test or actual prior-version migration was run.

Lint warnings are dependency/tool version notices and starter resource/manifest
warnings; no checks or compiler settings were disabled. Existing native symbol
stripping warning remains. Dependency downloads/test runtime required approved
Gradle access. No unresolved Phase 3 blocker. Remaining design questions include
future file-backed images, corrupt-data recovery UX, widget refresh scheduling
and production application identity. All completed reservations are released.
Developer 2 can continue design/theme/typography/localization independently.
Stop after Phase 3; no Phase 4 work has begun.

## Phase 4 application layer

Date: 2026-10-08. Owner: Developer 1. Branch: `ANDROID`.

Inspected the existing Android contracts and implementations from Phases 1–3 and
pinned iOS AppEnvironment.swift, DiscoverViewModel.swift, SearchViewModel.swift,
LibraryStore.swift and LibraryView.swift. iOS Discover has idle/loading/loaded/
failed plus reload; Search debounces 280 ms and cancels its task; Library observes
SwiftData directly and derives a favorites-only list. Android keeps those concepts
behind repository-backed lifecycle ViewModels, never direct screen data access.

### AppEnvironment → application-owned composition root

`KareApplication`, registered in AndroidManifest.xml, owns one lazy `AppContainer`
per application instance. No global mutable singleton or DI framework is added.
The container uses only application Context and constructs one shared local catalog
source, BundledWidgetRepository, KareDatabase and RoomLibraryRepository. Repository
properties expose their interfaces; the database remains internal to composition/
data code. Repositories reuse the same catalog snapshot. Lazy initialization does
not query or read the database/catalog during Application construction.

`KareViewModelFactory` receives both repository interfaces and an ErrorReporter,
then constructs Discover, Search or Library ViewModels. It rejects unsupported
classes. Future navigation/UI entry points obtain this factory from the application
and use ViewModelProvider with an appropriate owner; they must not call repositories
or build databases themselves. ViewModelStore owns ViewModel lifetimes, and
viewModelScope cancellation owns their work. Production database lifetime follows
the process; the container has an internal close helper for test teardown, without
relying on Application.onTerminate. Closing an individual screen must not close
application dependencies.

Existing stateless CatalogJson adapters and InstalledWidgetMapper stay encapsulated
inside data/persistence code. They need no new stateful instance, service locator
entry or duplicate serialization implementation. Database schema, codecs, domain
models and repository interfaces are unchanged.

An explicit lifecycle-viewmodel-ktx dependency uses the existing lifecycle version
alias; kotlinx-coroutines-test uses the existing coroutine version alias for
virtual-time JVM tests. No unrelated dependency upgrades were made. Android's
[ViewModel scoping guidance](https://developer.android.com/topic/libraries/architecture/viewmodel/viewmodel-apis)
and [coroutine test API](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-test/)
inform the lifecycle/factory and test setup.

### State and command contracts

| Component | Behavior |
|---|---|
| `LoadState<T>` | Exclusive Loading, Loaded(value), Failed(UiError); empty is a valid loaded list |
| DiscoverViewModel | Starts loading automatically; reload cancels prior load; only the latest load may publish |
| SearchUiState | Raw query, optional category and exclusive result state; derived empty-result indicator |
| SearchViewModel | Initial empty query immediately loads all templates; edits debounce 280 ms; equivalent trimmed/case-insensitive queries and unchanged categories do not repeat searches |
| LibraryUiState | Reactive installed snapshots, favorites filter and separate action state; display filtering retains repository order |
| LibraryViewModel | Observes on creation; retries failed subscriptions; installs by catalog ID, removes, toggles favorite from a fresh repository read, reorders full membership and updates content |
| LibraryActionState | Idle, Running, Succeeded or Failed with operation/template identity; no raw exception or localized text |

Commands are main-thread APIs. One library mutation is accepted at a time;
methods return false while busy so UI can disable actions or explicitly handle
rejection. No hidden queue or automatic replay of removals/toggles is introduced.
Successful commands do not manufacture list state: repository Flow is authoritative.
A write failure preserves the loaded list and appears in action state. Success/error
remains until a later action or clearAction; this is renderable state, not a
one-shot snackbar event. Observation errors are retried separately. Reorder accepts
the complete library, including rows hidden by the favorites filter.

Search cancels immediately on criteria changes, including before the next debounce
expires. Cancellation and generation checks prevent even an uncooperative old
request from publishing stale results. Same-query retry runs immediately. Setting a
category is idempotent; clearing passes null, unlike iOS's implicit chip toggle.
Discover begins Loading instead of iOS idle/loadIfNeeded. Neither emits a cancellation
error. Data lists are read-only domain snapshots with no Compose/Room/SDK types.

`UiError` contains semantic keys for not-found, unavailable, sign-in-required,
invalid-data, connection, storage and unexpected failures. Localization remains
Developer 2's responsibility. ErrorReporter receives original exceptions and
operation context for diagnostics; the production implementation uses Android Log.
No exception details are exposed in UI state. Cancellation is rethrown without
reporting. Crashlytics integration is not added.

### 2026-10-08 — Phase 4 decisions and limitations

- Use explicit application wiring and a small factory, with constructor-injected
  repository interfaces. Avoid a DI framework for this small dependency graph.
- Keep loading state exclusive and library observation independent from write
  progress; no contradictory loading/error/empty booleans.
- Retain iOS search delay but strengthen stale-result/cancellation protection;
  normalize equivalent queries to avoid redundant work.
- Keep observation active for the ViewModel lifetime, cancelled when its owner
  clears. Future navigation decides screen/tab ownership and lifecycle collection.
- Search/filter state survives configuration changes through ViewModel ownership,
  but SavedStateHandle/process-death restoration remains future navigation work.
  Persistent library data already survives process death in Room.
- Library membership is not launcher placement or a purchase entitlement. This
  layer does not authorize paid access; future purchase UI/use cases must apply
  the agreed entitlement policy before gated user actions.
- Removal survey payload/events, editor rendering, auth, widgets, reviews, billing,
  navigation and full screens remain outside this phase.

### Phase 4 work log and file manifest

Created:

- `app/src/main/java/com/example/kare/KareApplication.kt`
- `app/src/main/java/com/example/kare/app/AppContainer.kt` (also contains KareViewModelFactory)
- `app/src/main/java/com/example/kare/core/presentation/UiState.kt`
- `app/src/main/java/com/example/kare/feature/discover/DiscoverViewModel.kt`
- `app/src/main/java/com/example/kare/feature/search/SearchViewModel.kt`
- `app/src/main/java/com/example/kare/feature/library/LibraryViewModel.kt`
- `app/src/test/java/com/example/kare/presentation/TestRepositories.kt`
- `app/src/test/java/com/example/kare/presentation/ViewModelsTest.kt`
- `app/src/test/java/com/example/kare/app/AppContainerTest.kt`

Modified:

- `app/src/main/AndroidManifest.xml`: Application registration only.
- `app/build.gradle.kts`: explicit ViewModel runtime and coroutine test dependencies.
- `gradle/libs.versions.toml`: aliases using existing version pins.
- `docs/ANDROID_MIGRATION.md`: ownership/status, architecture, decisions and validation.

Shared-file risks were recorded before implementation. AGENTS.md, MainActivity,
all visual/theme/localization resources, repositories, database schema and codecs
remain unchanged. Initial wiring-test validation found a Kotlin expression return
incompatible with JUnit's void test signature; corrected to Unit without weakening
checks. No Git commits, pushes, merges, branch changes or history rewrites.

### Phase 4 final validation and completion

Date: 2026-10-08. Owner: Developer 1. Branch: `ANDROID`. Status: COMPLETED.

| Command | Result |
|---|---|
| `./gradlew assembleDebug` | PASS |
| `./gradlew test` | PASS; 66 JVM tests, zero failures/errors/skips; 20 new tests |
| `./gradlew lint` | PASS; zero errors, 28 warnings |
| `git diff --check` | PASS |

The final successful Gradle invocation ran all three requested tasks together.
Nineteen fake-repository tests cover initial/loading/success/error/retry states,
all error mappings and original diagnostic delivery, empty search, category
filtering, virtual-time debounce/deduplication, immediate cancellation and stale
result protection, reactive library/favorites, install/remove/content/reorder,
fresh favorite toggles, action failure/recovery, observation resubscription, busy
command rejection, lifecycle cancellation and factory dispatch. One Robolectric
wiring test verifies the manifest Application, stable dependency identity and real
catalog-to-library persistence. Existing Room tests remain separate and unchanged.
No device or Compose UI tests were added/run because screens remain deferred.

Lint warnings are dependency/tool updates and existing starter resource/manifest
notices; the two explicit dependency aliases add version notices. No lint rule,
compiler check or baseline was disabled. The existing native-symbol packaging
warning remains. No unresolved Phase 4 blocker. Future decisions include navigation
ownership, process-death restoration of query/filter state, localized error mapping,
removal feedback events and entitlement gates; none is claimed implemented here.

Recommended Phase 5 is the navigation/initial screen integration described above.
Developer 2 can independently continue design tokens, typography and localization,
including mapping UiError keys to copy, while coordinating shared Gradle/manifest/
documentation changes. Phase 4 ownership reservations are released. No further work
is started until explicitly requested.

## Phase 5 design and localization foundation

Date: 2026-10-09. Owner: Developer 1. Branch: `ANDROID`.

### Ownership change

Developer 2 has not started any implementation. Design system, typography and
localization were initially reserved for Developer 2. The user temporarily
reassigned these areas to Developer 1 for Phase 5 so future UI work can proceed.
All Phase 5 code is Developer 1 work. Developer 2 currently has no active
implementation ownership. Future scope must be reassigned and recorded before
Developer 2 starts. Earlier work-log suggestions are historical, not active claims.

### Source analysis and design mapping

Inspected the pinned IOS Theme.swift, AppFont.swift, Color+Hex.swift, MacScale.swift,
CategoryChip, SectionHeader and StateViews, plus source font binaries/README,
AccentColor asset, application Localizable.xcstrings and relevant Discover/Search/
Library/Profile/Settings call sites. The AccentColor asset has no explicit color;
Theme.Palette is the actual semantic source. MacScale applies 1.25 scaling only
for iOS-on-Mac. Color+Hex uses RRGGBBAA; Android tint constants are AARRGGBB.

| iOS palette | Android KareColors | Light | Dark |
|---|---|---|---|
| background | background | FDF8F8 | 141111 |
| surface | surface | FFFFFF | 1F1B1B |
| surfaceMuted | surfaceMuted | F1EDEC | 2B2626 |
| ink | textPrimary | 1D1D1F | F5F1F0 |
| subtleText | textSecondary | 5E5E63 | A8A2A1 |
| hairline | border | E5E2E1 | 3A3434 |
| accent | accent | D44A33 | E25A42 |
| accentTint (RRGGBBAA) | accentTint | D44A331F | E25A422E |
| onInk | onInk | FFFFFF | 1D1D1F |
| stageTop | stageTop | EFE9E7 | 2A2525 |
| stageBottom | stageBottom | E2DAD8 | 1F1B1B |

MaterialTheme integrates background/surface/text/outline roles and keeps the
original brand palette available through `KareDesign.colors`. Material primary
uses CC442E in light mode: source D44A33 with white text measures about 4.35:1,
so this small darkening gives normal button labels at least 4.5:1. Dark primary
retains E25A42 with dark on-primary text. Decorative accent tokens are unchanged;
use Material primary for interactive text/fills requiring the tested contrast.
Secondary uses ink/onInk, tertiary uses subtle text, and error roles retain native
Material light/dark defaults because iOS has no shared error palette. Containers
composite translucent source tint over surface to produce opaque Material colors.
Dynamic wallpaper colors are not enabled: the default theme preserves Kare identity.

Spacing is 4/8/12/20/24/40 dp, matching source xs through xxl. Card radius is 20 dp;
hero/sheet radius is 28 dp; pills use 50% corners instead of a magic 999 radius.
Material small-control corners retain native defaults. Optional layout maximums
are 680/1040 dp for readable/wide content; screens choose responsive arrangements.
No full screen, button wrapper, custom chip or unused component library was created.

### Typography and fonts

Three unmodified source Fraunces 72pt Soft static fonts are bundled in res/font:
SemiBold (600), Bold (700), Black (900). Source heavy maps to the Black file.
Regular is used by later Daily/widget/editor features, not the shared heading
scale, so it is deliberately not copied now. DM Sans is absent from the iOS bundle;
Android uses FontFamily.SansSerif instead of importing Apple's SF Pro.

| Source style | KareTextStyles | Size / line height (sp) | Weight |
|---|---|---|---|
| displayLarge / hero | display | 34 / 42 | Fraunces Black |
| headline | headline | 24 / 32 | Fraunces Bold |
| headlineSmall / sectionTitle | headlineSmall | 20 / 28 | Fraunces Bold |
| title | title | 17 / 24 | Fraunces SemiBold |
| body | body | 15 / 22 | System sans regular |
| bodyLarge | bodyLarge | 17 / 24 | System sans regular |
| label / caption | label | 13 / 18 | System sans medium |
| labelCaps | labelCaps | 12 / 16 | System sans bold, 0.6 sp tracking |
| cardTitle | cardTitle | 15 / 22 | System sans semibold |

All Material typography roles are explicitly mapped to this compact scale; the
extra Material display slots do not invent new oversized headings. Source sizes
become scalable sp. Line heights are deliberate Android choices, not Swift values.
Text casing remains locale-aware UI work; styles do not uppercase Turkish strings.
No MacScale, UIKit font registration, Dynamic Type curve emulation, Apple shadow
blur, glass materials or SwiftUI motion is copied. Native Compose font scaling,
Material interaction/accessibility and elevation remain the Android approach.

Font name-table records confirm Fraunces72ptSoft-SemiBold/Bold/Black, copyright
2020 The Fraunces Project Authors, and SIL Open Font License 1.1. The unmodified
[upstream license](https://github.com/undercasetype/Fraunces/blob/master/OFL.txt)
is packaged as assets/licenses/fraunces_ofl.txt. Android uses bundled resources
as described in [Compose font guidance](https://developer.android.com/develop/ui/compose/text/fonts).
Font hashes below pin the copied iOS assets:

- `fraunces_soft_black.ttf`: `882c17d17f47101702556ff5365d5e2bd98eaae7de6e59f4398e1f1e29445e19`
- `fraunces_soft_bold.ttf`: `af10e7e2bcfae5a8e638e944f22c63b50fd8e769a4f54095fa3a3480512ff9ea`
- `fraunces_soft_semibold.ttf`: `736e4db7b979ea31cd46baaa365a7f4776ce976204b15dce0c873b190217c812`

### Localization mapping and boundaries

The source app actively contains English and Turkish only. Android default
`values/strings.xml` is English; `values-tr/strings.xml` supplies Turkish, with
normal Android fallback for other locales. No per-app language picker, locale
persistence or widget-language synchronization is implemented here.

Each locale has 86 strings and one widget-count plural. Seventy-three strings
come directly from the iOS catalog, including navigation labels, library actions,
favorites, category names, six discover shelf titles and available subtitles,
profile/settings basics, errors and author attribution. Thirteen are explicit
Android additions: generic semantic errors, search/favorite empty states, loading,
back/edit, language self-names and the localized starter greeting. Source loading
copy exists in StateViews but is absent from xcstrings; Search's empty message is
system-provided on iOS. Added Turkish copy preserves the app's informal tone and
should receive normal native-speaker review with the first screens.

`app/src/test/resources/localization/source-mapping.json` lists every resource,
its iOS key (or null for additions), and English/Turkish values. `%@` attribution
becomes Android `%1$s`. Widget counts use quantity resources (`one`/`other`);
Turkish count nouns remain singular. XML escapes apostrophes and markup; tests
verify compiled text matches source meaning. Existing inconsistent source terms
such as Kitaplık/Kütüphane are not silently rewritten across unrelated content.

`core/localization/UiStrings.kt` maps every UiError and WidgetCategory exhaustively
to @StringRes IDs. A UI imports the extension and calls
`stringResource(error.stringResource())`; ViewModels continue to emit semantic
keys, with no Context or resource IDs. Known catalog section IDs map to localized
title/subtitle resources; unknown IDs return null for caller-provided source copy.
Template prose and user-authored content remain unchanged. No review/auth/billing
copy or all 609 app/147 widget entries are blindly imported.

### 2026-10-09 — Phase 5 decisions and work log

- Reassigned previously reserved Developer 2 areas to Developer 1 before editing.
- Ported exact semantic tokens and relevant fonts, with native Material integration
  and documented contrast/type/shape differences.
- Kept stateless UI resource mappings outside domain, repositories and ViewModels.
- Replaced starter purple tokens/default typography; retained a thin ui/theme
  delegate so MainActivity's theme entry point remains compatible.
- Localized the existing starter greeting without building a feature screen.
- Added no Gradle dependency and changed no repository, Room schema, catalog,
  serializer, ViewModel, Firebase, navigation, widget or billing implementation.
- Initial compile caught two nonexistent shelf subtitles; corrected to null to
  match the actual catalog rather than invent subtitle text.

Created:

- `app/src/main/java/com/example/kare/core/design/KareColors.kt`
- `app/src/main/java/com/example/kare/core/design/KareTypography.kt`
- `app/src/main/java/com/example/kare/core/design/KareTheme.kt`
- `app/src/main/java/com/example/kare/core/localization/UiStrings.kt`
- `app/src/main/res/font/fraunces_soft_semibold.ttf`
- `app/src/main/res/font/fraunces_soft_bold.ttf`
- `app/src/main/res/font/fraunces_soft_black.ttf`
- `app/src/main/assets/licenses/fraunces_ofl.txt`
- `app/src/main/res/values-tr/strings.xml`
- `app/src/test/java/com/example/kare/design/DesignResourcesTest.kt`
- `app/src/test/resources/localization/source-mapping.json`

Modified:

- `app/src/main/java/com/example/kare/ui/theme/Theme.kt`
- `app/src/main/java/com/example/kare/MainActivity.kt` (starter string resource only)
- `app/src/main/res/values/strings.xml`
- `docs/ANDROID_MIGRATION.md`

Removed obsolete starter files:

- `app/src/main/java/com/example/kare/ui/theme/Color.kt`
- `app/src/main/java/com/example/kare/ui/theme/Type.kt`

No commits, pushes, merges, branch operations or history changes. Shared conflict
hotspots are core/design tokens, resource names, the theme entry point and this
migration record. Future Developer 2 work must be assigned explicitly first.

### Phase 5 final validation and completion

Date: 2026-10-09. Owner: Developer 1. Branch: `ANDROID`. Status: COMPLETED.
The read-only remote check confirmed IOS still points to the pinned source commit.

| Command | Result |
|---|---|
| `./gradlew assembleDebug` | PASS |
| `./gradlew test` | PASS; 72 tests, zero failures/errors/skips; six new resource/design tests |
| `./gradlew lint` | PASS; zero errors, 85 warnings |
| `git diff --check` | PASS |

Six Robolectric tests cover compiled English/Turkish values against the source
mapping, formatting contracts/fallback, exhaustive semantic-error/category/shelf
mappings, plurals, bundled font loading/weight assignment/license presence, and
light/dark Material token/contrast checks. A separate XML audit confirmed identical
87-name/type resource structures without duplicates in both locales. APK inspection
confirmed all three fonts and their license are packaged. No screenshot/golden,
physical-device or full-screen visual validation is claimed in this foundation.

Lint has 64 unused-resource warnings (including starter resources and prepared
near-term strings), 12 dependency notices, five newer-version notices, two AGP
notices, one target-SDK notice and one existing redundant-label warning. Prepared
strings are intentionally unused until Phase 6; no resource warnings were suppressed
and no checks were disabled. No new Gradle dependency/configuration was needed.

No Phase 5 blocker remains. Native-speaker review of new Turkish messages and
large-font/real-device UI review belong with initial screens. Full catalog prose,
widget/editor copy, app-language selection and future Fraunces Regular usage remain
deferred. Phase 6 should implement Navigation Compose and initial Discover/Search/
Library screens using this foundation. Developer 2 could take an explicitly
assigned accessibility/localization review or separate Profile/Settings work later;
there is currently no active Developer 2 implementation ownership. Stop here.
