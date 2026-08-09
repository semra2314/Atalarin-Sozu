# Widgy — Architecture

A widget marketplace for iOS. Browse curated widget templates, add them to a
personal library. A design editor is the planned next phase.

**Target:** iOS 26.4 · SwiftUI · SwiftData · Swift Testing

---

## Layout

```
Widgy/
├── App/                  WidgyApp — entry point, ModelContainer setup
├── Navigation/           AppRoute (route table), RootView (tabs + stacks)
├── Core/
│   ├── Models/           Pure value types. No UIKit, no persistence, no network.
│   ├── Repositories/     WidgetRepository protocol + Mock and Firebase impls
│   └── Store/            SwiftData model, LibraryStore, AppEnvironment
├── DesignSystem/         Theme tokens + reusable components
└── Features/
    ├── Discover/         Curated home feed
    ├── Search/           Search + category browsing
    ├── Library/          The user's installed widgets
    └── Detail/           Template detail, creator profile
```

The Xcode project uses a file-system-synchronized group, so **new files appear
in the target automatically** — no `.pbxproj` editing needed.

---

## The one rule that matters

Screens never talk to a backend. They talk to `WidgetRepository`:

```swift
protocol WidgetRepository: Sendable {
    func discoverSections() async throws -> [CatalogSection]
    func template(id: String) async throws -> WidgetTemplate
    func search(query: String, category: WidgetCategory?) async throws -> [WidgetTemplate]
    func templates(in category: WidgetCategory) async throws -> [WidgetTemplate]
}
```

Right now `MockWidgetRepository` fulfils it from `SampleCatalog`. This means the
whole app is buildable, testable and demoable today, with zero backend.

### Switching to Firebase

One line, in `Core/Store/AppEnvironment.swift`:

```swift
static var live: AppEnvironment {
    AppEnvironment(widgets: FirebaseWidgetRepository())   // was MockWidgetRepository()
}
```

Then fill in `FirebaseWidgetRepository` (the file has the full checklist at the
top). Expected Firestore shape:

```
/templates/{templateId}       → WidgetTemplate (Codable, as-is)
/catalogSections/{sectionId}  → { title, subtitle, style, templateIds: [String] }
```

No view, view-model or test needs to change. Previews stay instant because they
keep using the mock with zero latency.

---

## Two kinds of state

| | Where | Why |
|---|---|---|
| **Catalog** (templates, sections) | Remote, via repository | Shared, changes constantly, server-curated |
| **Library** (what you added, favorites, order) | Local, SwiftData | Yours, must work offline, must survive reinstall of the catalog |

`InstalledWidget` denormalizes name/author/theme on purpose — the library must
render fully offline, even if the catalog is unreachable.

All library writes go through `LibraryStore`. Views read with `@Query` and
mutate through the store, so persistence rules live in one file.

---

## Design system

Every spacing value, radius, colour and font in the UI comes from `Theme`.
A restyle is one file, not a scavenger hunt. `WidgetPreview` is the placeholder
for the real WidgetKit render — its API is shaped to match what a live preview
will need, so swapping it is contained.

---

## What's next

1. **WidgetKit extension** — a real widget on the home screen, reading from the
   SwiftData store via an App Group.
2. **Firebase** — replace the mock, add auth for creator accounts.
3. **The editor** — the second phase. `WidgetTheme` is already the serializable
   recipe an editor would produce, so this is additive rather than a rewrite.
4. **Purchases** — `WidgetTemplate.Price` models paid tiers already; needs StoreKit.
