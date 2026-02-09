# Dependency Upgrade Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Upgrade Flutter/Dart dependencies to the latest safe major versions and keep the project building and tests passing.

**Architecture:** Update `pubspec.yaml` constraints, resolve version conflicts, run `flutter pub get`, and fix any breaking changes in code. Verify via `flutter analyze` and `flutter test`.

**Tech Stack:** Flutter, Dart, Riverpod, go_router, Drift, freezed/json_serializable

---

### Task 1: Audit current constraints and target versions

**Files:**
- Read: `app/pubspec.yaml`

**Step 1: Capture current constraints**

Review `app/pubspec.yaml` to list direct dependencies and dev dependencies.

**Step 2: Inspect available upgrades**

Run: `cd app && flutter pub outdated`

Expected: table of current/upgradable/latest versions.

**Step 3: Decide upgrade targets**

Set target majors for: `flutter_riverpod`, `go_router`, `freezed`, `freezed_annotation`, `json_annotation`, `json_serializable`, `build_runner`, `drift`, `drift_flutter`, `drift_dev`, `flutter_lints`.

---

### Task 2: Update `pubspec.yaml` constraints

**Files:**
- Modify: `app/pubspec.yaml`

**Step 1: Bump dependency versions**

Update direct dependencies and dev dependencies to the latest compatible majors (per Task 1).

**Step 2: Save and validate formatting**

Ensure YAML formatting remains valid (2-space indentation, no trailing tabs).

---

### Task 3: Resolve dependency graph

**Files:**
- Modify: `app/pubspec.lock`

**Step 1: Upgrade with major versions**

Run: `cd app && flutter pub upgrade --major-versions`

Expected: `pubspec.lock` updated with new versions.

**Step 2: If resolution fails**

Iterate on `pubspec.yaml` constraints, re-run `flutter pub get` until resolution succeeds.

---

### Task 4: Fix breaking changes (if any)

**Files:**
- Modify: `app/lib/**` (as needed)
- Test: `app/test/**` (as needed)

**Step 1: Identify breakages**

Run: `cd app && flutter analyze`

Expected: errors pointing to incompatible API changes.

**Step 2: Apply minimal fixes**

Update imports/usage for any breaking API changes (e.g., `go_router`, `riverpod`, `drift`, `freezed` changes). Keep changes minimal.

---

### Task 5: Verify

**Step 1: Static analysis**

Run: `cd app && flutter analyze`

Expected: no issues.

**Step 2: Tests**

Run: `cd app && flutter test`

Expected: all tests pass.

---

### Task 6: Commit (only if requested)

**Step 1: Stage changes**

Run: `git add app/pubspec.yaml app/pubspec.lock app/lib app/test`

**Step 2: Commit**

Run: `git commit -m "chore: upgrade Flutter dependencies"`
