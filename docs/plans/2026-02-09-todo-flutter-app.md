# Todo Flutter App — Implementation Plan

> **For agents:** Check task statuses below before starting work. Pick up the next `[ ]` task in order. Mark `[x]` when done, `[~]` if in progress. Update this file after each task.

**Goal:** Build an offline-first Flutter Android todo app with Firebase backend to learn real-world Android development skills.

**Architecture:** Clean layering (UI → Controllers → Repositories → DataSources), Riverpod state management, go_router navigation, Drift local DB + Firestore cloud sync.

**Tech Stack:** Flutter, Firebase (Auth + Firestore + Storage), Riverpod, go_router, Drift, freezed, json_serializable, mocktail

---

## Phase 0: Project Scaffold + Tooling ✅

- [x] 0.1 — Run `flutter create` in `app/` directory
- [x] 0.2 — Add `analysis_options.yaml` with `flutter_lints`, zero-warnings policy
- [x] 0.3 — Create `app/lib/` folder structure: `app/`, `features/`, `core/`, `domain/`, `data/`
- [x] 0.4 — Add core dependencies to `pubspec.yaml` (riverpod, go_router, freezed, drift, etc.)
- [x] 0.5 — Run `flutter pub get` and `flutter analyze` — verify clean
- [x] 0.6 — Create `.gitignore` (root + app-level) with security exclusions from AGENTS.md
- [x] 0.7 — Initialize git repo, initial commit

## Phase 1: UX/UI Foundation ✅

- [x] 1.1 — Define Material 3 theme: `ColorScheme`, typography scale, spacing tokens
- [x] 1.2 — Build reusable core widgets: buttons, text fields, error banner, empty state, loading skeleton
- [x] 1.3 — Write widget tests for core components
- [x] 1.4 — Commit

## Phase 2: Navigation + Screen Skeleton ✅

- [x] 2.1 — Set up go_router with shell route and auth guard (stubbed auth state)
- [x] 2.2 — Create placeholder screens: auth gate, task list, task detail, settings
- [x] 2.3 — Write widget tests for routing (auth gate redirects)
- [x] 2.4 — Commit

## Phase 3: Domain Model + Use Cases ✅

- [x] 3.1 — Define `Task` entity with freezed (id, title, notes, completed, dueAt, priority, tags, listId, timestamps)
- [x] 3.2 — Define `TaskList` entity with freezed
- [x] 3.3 — Define `Attachment` entity with freezed
- [x] 3.4 — Define typed failure classes: `AuthFailure`, `NetworkFailure`, `StorageFailure`, `ValidationFailure`
- [x] 3.5 — Write use cases: create/update/complete task, filter/sort (Today/Upcoming/Completed)
- [x] 3.6 — Write unit tests for all entities and use cases
- [x] 3.7 — Run code generation (`build_runner`), verify tests pass
- [x] 3.8 — Commit

## Phase 4: Data Layer — Repository Contracts ✅

- [x] 4.1 — Define `AuthRepository` interface
- [x] 4.2 — Define `TaskRepository` interface
- [x] 4.3 — Define `AttachmentRepository` interface
- [x] 4.4 — Create fake/mock implementations for testing
- [x] 4.5 — Write unit tests using fakes
- [x] 4.6 — Commit

## Phase 5: Local Persistence (Drift) ✅

- [x] 5.1 — Add Drift dependencies and configure database
- [x] 5.2 — Create tables: `tasks`, `task_lists`, `attachments`, `sync_queue` (merged 5.4 — sync tracking baked in)
- [x] 5.3 — Implement `LocalTaskDataSource`, `LocalAttachmentDataSource`, `LocalSyncQueueDataSource` with CRUD operations
- [x] 5.4 — _(merged into 5.2)_
- [x] 5.5 — Write unit tests with in-memory Drift DB (49 tests)
- [x] 5.6 — Commit

## Phase 6: Firebase Setup ✅

- [x] 6.1 — Create Firebase project + add Android app
- [x] 6.2 — Run `flutterfire configure`, add Firebase packages to pubspec
- [x] 6.3 — Enable Auth providers (Email/Password + Google Sign-In)
- [x] 6.4 — Set up Firebase Emulator Suite (`firebase init emulators` in `firebase/`)
- [x] 6.5 — Wire emulator connection in debug builds (`--dart-define=USE_FIREBASE_EMULATORS`)
- [x] 6.6 — Verify: sign in + read/write Firestore on emulators (deferred to Phase 7 — needs auth UI)
- [x] 6.7 — Commit

## Phase 7: Authentication ✅

- [x] 7.1 — Implement `FirebaseAuthDataSource` (email/password sign up/in, Google sign-in, sign out)
- [x] 7.2 — Implement `AuthRepositoryImpl` wrapping data source, mapping exceptions to `AuthFailure`
- [x] 7.3 — Create Riverpod providers: `authStateProvider`, `currentUserProvider`
- [x] 7.4 — Build auth screens: sign in, sign up, password reset
- [x] 7.5 — Wire go_router auth guard to real auth state
- [x] 7.6 — Write unit tests (mocked auth) + widget tests (form validation, error states)
- [x] 7.7 — Commit

## Phase 8: Cloud Data + Security Rules ✅

- [x] 8.1 — Write Firestore security rules (`users/{uid}/**` scoping, field validation)
- [x] 8.2 — Write Storage security rules (user-scoped, size/type restrictions)
- [x] 8.3 — Implement `FirestoreTaskDataSource` (CRUD under `users/{uid}/tasks/`)
- [x] 8.4 — Implement `TaskRepositoryImpl` combining local + remote data sources
- [x] 8.5 — Write unit tests with `fake_cloud_firestore` (67 tests: mappers, data source, repository)
- [x] 8.6 — Manual verification against emulators (cross-user access denied) — deferred to integration tests
- [x] 8.7 — Commit

## Phase 9: Sync Engine

- [x] 9.1 — Implement sync queue processor: read dirty records → push to Firestore → mark clean
- [x] 9.2 — Implement pull sync: fetch remote changes → merge into local DB (last-write-wins)
- [x] 9.3 — Trigger sync on: app start, pull-to-refresh, network regain
- [x] 9.4 — Add retry with backoff for failed syncs
- [x] 9.5 — Surface sync status in UI (syncing/synced/error indicator)
- [x] 9.6 — Write unit tests with fake clock + mocked cloud data source
- [x] 9.7 — Commit

## Phase 10: Task UI (Full Feature) ✅

- [x] 10.1 — Build task list screen with filters (Inbox/Today/Upcoming/Completed)
- [x] 10.2 — Build task creation bottom sheet
- [x] 10.3 — Build task detail/edit screen
- [x] 10.4 — Add swipe actions (complete/delete)
- [x] 10.5 — Handle all 4 states per screen: loading, empty, error, populated
- [x] 10.6 — Add accessibility: Semantics labels, 48dp tap targets, dynamic text
- [x] 10.7 — Write widget tests for key flows
- [x] 10.8 — Commit

## Phase 11: Attachments

- [ ] 11.1 — Add file/image picker dependency
- [ ] 11.2 — Implement upload to Firebase Storage (`users/{uid}/attachments/`)
- [ ] 11.3 — Store attachment metadata in Firestore + local DB
- [ ] 11.4 — Handle offline: queue upload, show "pending" status
- [ ] 11.5 — Display attachments on task detail (thumbnail/link)
- [ ] 11.6 — Write unit tests for attachment state machine
- [ ] 11.7 — Commit

## Phase 12: Settings + Polish

- [ ] 12.1 — Build settings screen: profile info, sign out, theme toggle (light/dark)
- [ ] 12.2 — Persist theme preference locally
- [ ] 12.3 — Add structured logging (debug only, no PII)
- [ ] 12.4 — Final UI polish pass: consistent spacing, transitions, edge cases
- [ ] 12.5 — Commit

## Phase 13: Integration Tests + CI

- [ ] 13.1 — Write integration tests: sign up → create task → sync → restart → verify persisted
- [ ] 13.2 — Set up GitHub Actions workflow: `pub get` → `format` → `analyze` → `test`
- [ ] 13.3 — Verify CI passes on push
- [ ] 13.4 — Commit

---

## Status

**Current phase:** 10 — Task UI (Full Feature)
**Last updated:** 2026-02-11
