# Todo Flutter App

A Flutter Android todo app with Firebase backend, offline-first sync, and clean architecture — built as a learning project for real-world Android development skills.

## Features

- **Task management** — create, edit, complete, delete, and organize tasks into lists
- **Offline-first** — works without network; syncs to cloud when connected
- **Authentication** — Email/password and Google Sign-In via Firebase Auth
- **Cloud sync** — Firestore for task data, Firebase Storage for attachments
- **Material 3 UI** — intentional design tokens, accessibility, and responsive layouts

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter (Android) |
| State management | Riverpod |
| Routing | go_router |
| Local database | Drift (SQLite) |
| Backend | Firebase (Auth, Firestore, Storage) |
| Models | freezed + json_serializable |
| Testing | mocktail, fake_cloud_firestore, firebase_auth_mocks |

## Project Structure

```
app/              # Flutter application
  lib/
    app/          # App shell, router, theme
    features/     # auth/, tasks/, settings/
    core/         # Shared widgets, errors, logging
    domain/       # Entities, use cases (pure Dart)
    data/         # Repositories, local + remote data sources
firebase/         # Firestore/Storage rules, emulator config
scripts/          # Dev helper scripts
.github/          # CI workflows
```

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio + Android SDK + emulator
- [Firebase CLI](https://firebase.google.com/docs/cli) (`npm i -g firebase-tools`)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) (`dart pub global activate flutterfire_cli`)

### Setup

```sh
# Clone the repo
git clone https://github.com/mihassan/TodoFlutterApp.git
cd TodoFlutterApp/app

# Install dependencies
flutter pub get

# Run code generation
dart run build_runner build --delete-conflicting-outputs
```

### Run with Firebase Emulators (recommended for development)

```sh
# Terminal 1 — start Firebase emulators
cd firebase
firebase emulators:start

# Terminal 2 — run the app
cd app
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

### Run Tests

```sh
cd app

# All tests
flutter test

# Single file
flutter test test/domain/task_test.dart

# Single test by name
flutter test test/domain/task_test.dart --name "marks task as completed"

# With coverage
flutter test --coverage
```

### Lint & Format

```sh
# Format
dart format .

# Analyze
flutter analyze
```

## Architecture

```
UI (Widgets)
  → Controllers (Riverpod)
    → Repositories (interfaces)
      → Data Sources (Drift local DB + Firebase remote)
```

- **Offline-first:** all writes go to local SQLite first, then sync to Firestore
- **Sync strategy:** last-write-wins with `updatedAt` timestamps
- **Error boundaries:** raw exceptions are mapped to typed failures (`AuthFailure`, `NetworkFailure`, etc.) at the repository layer — never exposed to UI

## Contributing

This is a personal learning project, but contributions and suggestions are welcome.

1. Fork the repo
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Run checks before committing: `scripts/check`
4. Open a pull request

## License

MIT
