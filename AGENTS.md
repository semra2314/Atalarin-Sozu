# Kare Android migration

## Project purpose and reference

This repository contains the native Android migration of Kare. The functional
reference is `semra2314/Atalarin-Sozu`, branch `IOS`. Read the source revision and
analysis in `docs/ANDROID_MIGRATION.md`; current source code takes precedence over
outdated iOS planning notes. Prefer native Android behavior over literal Swift
translations. Do not expand a task into a full application migration.

## Android stack

Use Kotlin, Jetpack Compose, ViewModel, StateFlow, Kotlin Coroutines, Navigation
Compose, Room, DataStore, Firebase Auth, Firestore, Firebase Crashlytics,
Glance / Android App Widgets, and Google Play Billing as their features are
implemented. Document a strong technical reason for any departure. Do not add
unused infrastructure dependencies just to reserve a package.

## Architecture rules

The dependency flow is:

`UI → ViewModel → Repository → Local / Remote Data Source`

Compose screens must not directly access Firebase, Firestore, Room, DataStore,
network services, or billing APIs. ViewModels depend on repositories or domain
abstractions. Keep backend, persistence, and platform details behind those
boundaries. Keep domain models independent of Compose, Android resources, and
infrastructure SDK types. Use explicit mappings at serialization boundaries.
Propagate coroutine cancellation; never turn cancellation into an ordinary error.
Purchase entitlements must not be represented only by a local boolean.

## Coordination rules

Before substantial work:

1. Read this file and `docs/ANDROID_MIGRATION.md`.
2. Inspect Git status and the actual current branch.
3. Check the migration status table and both developers' Current work sections.
4. Confirm task ownership, dependencies, and likely shared-file conflicts.
5. Record the owner, branch, scope, and files before starting the task.

Do not take over an area assigned to the other developer without explicit
authorization. Unassigned suggestions are not active assignments. If developer
identity is unknown, record it as unassigned rather than inventing ownership.
Avoid unrelated changes and preserve concurrent edits. Document shared-file
dependency risks before modifying those files; coordinate with their owner.
Keep work separable whenever practical. The repository, not chat history, is
the source of truth for progress, decisions, blockers, and ownership.

## Validation rules

Before declaring a task complete, run relevant checks. At minimum, when applicable:

```sh
./gradlew assembleDebug
./gradlew test
./gradlew lint
```

Fix errors introduced by the task. Do not weaken compiler settings, disable lint
without justification, or add unsafe placeholders to obtain a passing build.
Record exact results and environmental blockers; do not describe an unrun check
as passing. Add focused tests for domain behavior and compatibility contracts.

## Documentation rules

All Markdown created or modified for this migration must be in English. New
code comments should preferably be in English. User-facing localization follows
the application's localization strategy and is not subject to this restriction.

After every completed migration task, update `docs/ANDROID_MIGRATION.md` with
implemented components, important decisions, unresolved issues, platform
differences, validation, and remaining work. Maintain chronological decision and
work logs, and release completed ownership reservations. Use only the documented
status values: NOT STARTED, IN PROGRESS, COMPLETED, BLOCKED.

## Git safety rules

Keep the integration branch stable. Large feature work belongs on an explicitly
authorized feature branch. Inspect repository state before any branch operation.
Do not automatically create, delete, rename, push, or merge branches. Do not force
push, rewrite shared history, or commit unless explicitly requested. Do not undo
another developer's work.

Never commit secrets, API keys, signing keys, `local.properties`, build outputs,
IDE temporary files, machine-specific configuration, or generated sensitive
configuration. Keep Firebase and signing provisioning outside source control.
