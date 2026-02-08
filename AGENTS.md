# AGENTS.md — Flutter Todo App (Android)

## Project Overview

Monorepo for a Flutter Android todo app backed by Firebase (Auth, Firestore, Storage).
Offline-first with local SQLite (Drift) and background sync to Firestore.

**Implementation plan:** See [`docs/plans/2026-02-09-todo-flutter-app.md`](docs/plans/2026-02-09-todo-flutter-app.md) for phased task list and current status. Check it before starting work; update it after completing tasks.

## Repo Layout

```
app/            # Flutter Android application (all Dart code lives here)
firebase/       # Firebase config-as-code (rules, indexes, emulator config)
scripts/        # Dev/CI helper scripts
.github/        # CI workflows
```

Within `app/lib/`:
```
app/            # App shell, router (go_router), theme
features/       # Feature modules: auth/, tasks/, settings/
core/           # Shared widgets, error types, logging, constants
domain/         # Entities (freezed), use cases (pure Dart)
data/           # Repositories, local (Drift) + remote (Firebase) data sources
```

## Build / Run / Test Commands

All Flutter commands run from the `app/` directory.

```sh
# Install dependencies
flutter pub get

# Code generation (freezed, json_serializable, drift)
dart run build_runner build --delete-conflicting-outputs

# Format (entire repo — run from root)
dart format .

# Static analysis
flutter analyze

# Run on emulator (debug, with Firebase emulators)
flutter run --dart-define=USE_FIREBASE_EMULATORS=true

# ── Tests ──────────────────────────────────────────────
# All unit + widget tests
flutter test

# Single test file
flutter test test/domain/task_test.dart

# Single test by name (substring match)
flutter test test/domain/task_test.dart --name "marks task as completed"

# Tests with coverage
flutter test --coverage

# Integration tests (requires running emulator/device)
flutter test integration_test -d <deviceId>

# ── Firebase Emulators (run from firebase/) ────────────
firebase emulators:start
```

## Helper Scripts (run from repo root)

```sh
scripts/check          # dart format --set-exit-if-changed . && flutter analyze && flutter test
scripts/dev_emulators  # starts Firebase emulators
scripts/dev_app        # flutter run with emulator flags
```

## Code Style Guidelines

### Formatting & Analysis
- Dart formatter: `dart format .` — no manual line-length overrides.
- Lints: `flutter_lints` (or `very_good_analysis` if adopted). Zero warnings policy.
- Max line length: default (80). Let the formatter handle it.

### Imports
- Use relative imports within a feature (`import '../widgets/task_tile.dart';`).
- Use package imports across features (`import 'package:todo_flutter_app/core/errors.dart';`).
- Order: dart: → package: → relative. Separate groups with a blank line.
- Never use `dart:io` in domain/ or core/ (keep them platform-agnostic).

### Naming Conventions
- Files/directories: `snake_case` (`task_repository.dart`).
- Classes/enums/typedefs: `PascalCase` (`TaskRepository`, `AuthFailure`).
- Variables/functions/parameters: `camelCase` (`fetchTasks`, `isCompleted`).
- Private members: prefix with `_` (`_syncQueue`).
- Constants: `camelCase` (not SCREAMING_SNAKE) per Dart convention.
- Providers (Riverpod): `camelCase` with `Provider` suffix (`taskListProvider`).
- Generated files: co-locate with source (`task.freezed.dart`, `task.g.dart`).

### Types & Models
- Domain entities: use `freezed` with `@freezed` annotation. Keep them in `domain/`.
- JSON serialization: `json_serializable` via `@JsonSerializable()` on data-layer DTOs.
- Avoid dynamic; prefer explicit types everywhere.
- Use `typedef` for complex function signatures or callback types.
- Prefer `sealed class` (Dart 3) for error/result types when practical.

### State Management (Riverpod)
- One provider per concern; keep providers small and composable.
- Use `AsyncValue` for any data that can load/fail.
- Controllers (state notifiers) go in `features/<name>/controllers/`.
- Never access `ref` from domain/ or data/ layers.

### Error Handling
- Map all exceptions at repository boundaries into typed failures:
  `AuthFailure`, `NetworkFailure`, `StorageFailure`, `ValidationFailure`.
- Never let raw Firebase/platform exceptions propagate above the data layer.
- UI surfaces errors via `AsyncValue.error` or dedicated error state; never raw `try/catch` in widgets.
- Log errors with structured logger; never use `print()` in committed code.

### Firebase / Data Layer Rules
- **No direct Firebase SDK calls from widgets or controllers.**
  Widgets → Controller → Repository → DataSource (Firebase/Drift).
- Firestore paths: `users/{uid}/tasks/{taskId}`, `users/{uid}/lists/{listId}`.
- All writes go to local DB first (offline-first), then enqueue sync.
- Timestamps: use `FieldValue.serverTimestamp()` for Firestore writes;
  store `DateTime.utc(...)` locally.

### Testing Conventions
- File naming: `<source_file>_test.dart`, same directory structure under `test/`.
- Use `mocktail` for mocking (not mockito).
- Use in-memory Drift DB for repository tests.
- Use `fake_cloud_firestore` / `firebase_auth_mocks` for unit/widget tests.
- Each test file should be runnable independently.
- Prefer `group()` + descriptive `test()` names: `"TaskRepository — returns empty list when no tasks exist"`.
- TDD: write the failing test first, then implement, then refactor.

### Accessibility & UX
- Every interactive widget must have a `Semantics` label or use semantic widgets.
- Minimum tap target: 48x48 dp.
- Support dynamic type (no hardcoded font sizes; use `Theme.of(context).textTheme`).
- Every screen must handle: loading, empty, error, and populated states.

## Security — What Never Gets Committed

```gitignore
# Keystores & signing
**/*.jks
**/*.keystore
**/key.properties

# Service accounts & secrets
**/*serviceAccount*.json
**/*service-account*.json
.env
.env.*

# Firebase emulator data (local-only)
firebase/emulators/

# IDE secrets
.idea/workspace.xml
```

Files that ARE safe to commit (public project identifiers, not secrets):
- `app/android/app/google-services.json`
- `app/lib/firebase_options.dart`
- `firebase/firestore.rules`, `firebase/storage.rules`

## CI (GitHub Actions)

Expected workflow steps:
1. `flutter pub get`
2. `dart format --set-exit-if-changed .`
3. `flutter analyze`
4. `flutter test`

Cache: `~/.pub-cache` keyed on `pubspec.lock` hash.

## Key Decisions (context for agents)

| Choice | Value | Why |
|--------|-------|-----|
| State mgmt | Riverpod | Compile-safe, testable, no context needed |
| Routing | go_router | Declarative, supports auth redirects |
| Local DB | Drift (SQLite) | Type-safe, migrations, in-memory test support |
| Models | freezed + json_serializable | Immutable, union types, less boilerplate |
| Backend | Firebase (Auth + Firestore + Storage) | Industry standard for Android learning |
| Sync | Offline-first, last-write-wins | Simple to reason about for v1 |
| Testing | mocktail + fake Firebase packages | Fast, no emulator needed for unit/widget |
| Mocking | mocktail (not mockito) | No codegen, simpler API |
