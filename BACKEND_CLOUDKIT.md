# Widgy iOS - CloudKit Backend

The iOS marketplace is its own catalog (separate from Android, which has its own
repo and backend). Since iOS widgets are Apple-only tech anyway, the catalog lives
in **CloudKit**: Apple-native, free, and iCloud gives us creator identity for free.

## Two databases, on purpose

| Data | Where | Why |
|---|---|---|
| Catalog (templates, sections, reviews, profiles) | CloudKit **public** DB | Shared, browsable by everyone, server-curated |
| A user's library (added / made widgets) | SwiftData on device, optionally synced to CloudKit **private** DB | Personal, must work offline, syncs across the user's devices |

Screens never touch CloudKit directly. They talk to `WidgetRepository`.
`CloudKitWidgetRepository` fulfils it against the public DB; `MockWidgetRepository`
still serves previews and tests instantly.

## Record types (public DB)

### WidgetTemplate
`recordName` = the template id.

| Field | Type | Notes |
|---|---|---|
| `payload` | String | JSON of the whole `WidgetTemplate` (author, theme, price, content). Source of truth. |
| `name` | String | Flat copy for querying/sorting. |
| `category` | String | `WidgetCategory` raw value. |
| `installCount` | Int(64) | For "trending" sorting. |
| `searchText` | String | Lowercased name+summary+author+tags. |

### CatalogSection
`recordName` = the section id.

| Field | Type | Notes |
|---|---|---|
| `title` | String | |
| `subtitle` | String | optional |
| `style` | String | `spotlight` \| `carousel` \| `compactList` |
| `templateIds` | [String] | ordered template ids in the row |
| `order` | Int | row order on Discover |

If no `CatalogSection` records exist yet, the repository builds a sensible default
curation from the templates, so Discover works before you author any sections.

### Planned next (from the mentor notes)

| Record | Key fields |
|---|---|
| `UserProfile` (recordName = user id) | displayName, handle, avatar (CKAsset), isCreator |
| `Review` | templateRef (Reference), userRef, stars (Int), text, createdAt |
| `Purchase` | templateRef, buyerRef, amount, commission, date |

Widget preview images and editor photos should be stored as `CKAsset` (or
uploaded to a `CKAsset` field), not inlined as bytes.

## One-time setup

1. Target > **Signing & Capabilities** > add **iCloud** > check **CloudKit** and
   create a container, e.g. `iCloud.com.yourteam.Widgy`.
2. Be signed into iCloud on the device/simulator.
3. Seed the catalog once:

   ```swift
   try await CloudKitCatalogSeeder(
       containerIdentifier: "iCloud.com.yourteam.Widgy"
   ).seed()
   ```

   The first run auto-creates the record types in the **Development** environment.
   In the CloudKit dashboard, mark `name`, `category`, `installCount`, `order`,
   and `recordName` as **Queryable**, then **Deploy schema to Production**.
4. Flip the app to CloudKit in `AppEnvironment`:

   ```swift
   static let live = cloudKit(containerIdentifier: "iCloud.com.yourteam.Widgy")
   ```

   Nothing else changes. Revert to `MockWidgetRepository()` any time to demo offline.

## Library sync (optional, later)

To sync the user's SwiftData library across their devices, enable CloudKit on the
`ModelContainer`:

```swift
let config = ModelConfiguration(cloudKitDatabase: .private("iCloud.com.yourteam.Widgy"))
try ModelContainer(for: InstalledWidget.self, configurations: config)
```

Requirements: every SwiftData property must be optional or have a default, and no
`.unique` constraints (CloudKit doesn't enforce them). `InstalledWidget` is already
close; `templateID` would need its `.unique` relaxed for private-DB sync.

## Payments (not a DB concern)

Selling widgets goes through **StoreKit** (Apple requires IAP for digital goods).
CloudKit only records the sale + commission. Apple takes its cut (15-30%) on top of
your platform commission, so factor that into the split.

## Limits to know

- CloudKit's server-side logic is thin. Rating averages can be computed on the
  client for the demo; heavier accounting (commission, moderation) is a later,
  server-assisted phase.
- CloudKit is Apple-only. That is fine here: the Android app is a separate repo
  with its own backend and its own catalog.
