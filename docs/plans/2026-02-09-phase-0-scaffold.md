# Phase 0 Scaffold Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Scaffold the Flutter app structure, linting, dependencies, and git ignore to prepare for feature work.

**Architecture:** Clean layering (UI → Controllers → Repositories → DataSources) with domain entities and use cases in `app/lib/domain/`, repository interfaces in `app/lib/domain/repositories/`, and implementations in `app/lib/data/`. Offline-first sync uses a dedicated `sync_queue` table (not `isDirty` flags on domain tables). Task lists and attachments are defined at the domain level now, with list CRUD and attachment data sources deferred to later phases. Introduce a small `AppUser` domain entity to avoid leaking Firebase types above the data layer.

**Tech Stack:** Flutter, Riverpod, go_router, Drift, freezed, json_serializable, mocktail

---

### Task 1: Flutter app scaffold

**Files:**
- Create: `app/` (Flutter scaffold)

**Step 1: Run scaffold command**

Run: `flutter create app`

Expected: Flutter project created in `app/` with default Android + lib structure.

**Step 2: Verify baseline build**

Run: `flutter --version`

Expected: Shows stable channel (informational check only).

### Task 2: Add lint configuration

**Files:**
- Create: `analysis_options.yaml`

**Step 1: Write lint config**

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    avoid_print: true
    prefer_single_quotes: true
```

**Step 2: Confirm file exists**

Run: `ls`

Expected: `analysis_options.yaml` present at repo root.

### Task 3: Create lib folder structure

**Files:**
- Create: `app/lib/app/`
- Create: `app/lib/features/`
- Create: `app/lib/core/`
- Create: `app/lib/domain/`
- Create: `app/lib/data/`

**Step 1: Create directories**

Run: `mkdir -p app/lib/{app,features,core,domain,data}`

Expected: All directories exist under `app/lib/`.

### Task 4: Add core dependencies

**Files:**
- Modify: `app/pubspec.yaml`

**Step 1: Add runtime dependencies**

Run:

```bash
cd app
flutter pub add flutter_riverpod go_router freezed_annotation json_annotation drift drift_flutter
```

Expected: Dependencies added to `app/pubspec.yaml`.

**Step 2: Add dev dependencies**

Run:

```bash
cd app
flutter pub add --dev build_runner freezed json_serializable drift_dev mocktail
```

Expected: Dev dependencies added to `app/pubspec.yaml`.

### Task 5: Install and analyze

**Files:**
- Modify: `app/pubspec.lock`

**Step 1: Install deps**

Run: `flutter pub get`

Expected: Dependencies resolved.

**Step 2: Analyze**

Run: `flutter analyze`

Expected: 0 issues.

### Task 6: Add gitignore files

**Files:**
- Create: `.gitignore`
- Create: `app/.gitignore`

**Step 1: Root .gitignore**

Include:
- Build outputs (`/build`, `/app/build`, `/app/.dart_tool`, `/app/.idea`)
- Dart/Flutter tooling caches
- Android keystore secrets (`**/*.jks`, `**/*.keystore`, `**/key.properties`)
- Firebase emulator data (`firebase/emulators/`)
- Env files (`.env`, `.env.*`)

**Step 2: App .gitignore**

Include app-local build outputs and tooling caches for Flutter/Android.

### Task 7: Initialize git (optional)

**Files:**
- Create: `.git/` (if requested)

**Step 1: Initialize**

Run: `git init`

Expected: Git repository created.

**Step 2: First commit (only if user requests)**

Run: `git add . && git commit -m "chore: scaffold flutter app"`

Expected: Initial commit created.
