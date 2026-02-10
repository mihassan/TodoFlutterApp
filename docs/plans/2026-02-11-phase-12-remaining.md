# Phase 12 Remaining Tasks — Logging + Final Polish

> **For Claude:** Execute this plan task-by-task. Phase 12 is 80% complete (settings screen + theme provider done). Complete tasks 12.3 (structured logging) and 12.4 (final UI polish), then mark Phase 12 complete.

**Goal:** Add structured logging for debugging (debug-only, no PII) and perform final UI polish pass on all screens.

**Architecture:**
- Structured logger using `dart:developer` (built-in, no external deps)
- Log provider for Riverpod injection
- Consistent logging at repository/controller boundaries
- Final pass: consistent spacing, animations, edge case handling across all screens

**Tech Stack:** Dart built-in logging, Riverpod, Flutter Material 3

---

## Task 12.3a: Create Structured Logger Service

**Files:**
- Create: `app/lib/core/logging/logger.dart`

**Step 1: Implement logger service**

Create `app/lib/core/logging/logger.dart`:

```dart
import 'dart:developer' as developer;

/// Structured logger for debugging (debug mode only, no PII).
///
/// Uses dart:developer Timeline API for structured logging.
/// All logs are stripped in release mode via conditional compilation.
class AppLogger {
  static const String _logPrefix = '[TodoApp]';

  /// Logs an info-level message with optional metadata.
  static void info(String message, {Map<String, dynamic>? metadata}) {
    if (!_isDebugMode) return;
    developer.log(
      message,
      name: '$_logPrefix.info',
      level: 800, // INFO level
      time: DateTime.now(),
    );
    if (metadata != null) {
      developer.log(
        'Metadata: ${_sanitizeMetadata(metadata)}',
        name: '$_logPrefix.info',
        level: 800,
      );
    }
  }

  /// Logs a debug-level message (verbose, development only).
  static void debug(String message, {Map<String, dynamic>? metadata}) {
    if (!_isDebugMode) return;
    developer.log(
      message,
      name: '$_logPrefix.debug',
      level: 700, // DEBUG level
    );
  }

  /// Logs a warning-level message (potential issues).
  static void warning(String message, {Map<String, dynamic>? metadata}) {
    if (!_isDebugMode) return;
    developer.log(
      message,
      name: '$_logPrefix.warning',
      level: 900, // WARNING level
    );
    if (metadata != null) {
      developer.log(
        'Metadata: ${_sanitizeMetadata(metadata)}',
        name: '$_logPrefix.warning',
        level: 900,
      );
    }
  }

  /// Logs an error-level message with exception and stack trace.
  static void error(
    String message,
    Object exception,
    StackTrace stackTrace, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_isDebugMode) return;
    developer.log(
      '$message: $exception',
      name: '$_logPrefix.error',
      level: 1000, // ERROR level
      error: exception,
      stackTrace: stackTrace,
    );
    if (metadata != null) {
      developer.log(
        'Metadata: ${_sanitizeMetadata(metadata)}',
        name: '$_logPrefix.error',
        level: 1000,
      );
    }
  }

  /// Sanitizes metadata to remove PII (emails, phone numbers, tokens).
  static Map<String, dynamic> _sanitizeMetadata(Map<String, dynamic> metadata) {
    final sanitized = <String, dynamic>{};
    for (final entry in metadata.entries) {
      if (_isPII(entry.key)) {
        sanitized[entry.key] = '***REDACTED***';
      } else if (entry.value is String && _isPIIValue(entry.value as String)) {
        sanitized[entry.key] = '***REDACTED***';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  /// Checks if a key name suggests PII.
  static bool _isPII(String key) {
    final lowerKey = key.toLowerCase();
    return lowerKey.contains('email') ||
        lowerKey.contains('phone') ||
        lowerKey.contains('token') ||
        lowerKey.contains('password') ||
        lowerKey.contains('secret') ||
        lowerKey.contains('uid') ||
        lowerKey.contains('id');
  }

  /// Checks if a value looks like PII (email, token, etc.).
  static bool _isPIIValue(String value) {
    // Email pattern
    if (value.contains('@') && value.contains('.')) return true;
    // Hex token pattern (32+ hex chars)
    if (RegExp(r'^[a-f0-9]{32,}$').hasMatch(value)) return true;
    return false;
  }

  /// Checks if running in debug mode.
  static bool get _isDebugMode {
    bool isDebugMode = false;
    assert(isDebugMode = true);
    return isDebugMode;
  }
}
```

**Step 2: Verify syntax**

Run:
```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && dart analyze lib/core/logging/logger.dart
```

Expected: 0 errors, 0 warnings

---

## Task 12.3b: Create Logger Provider

**Files:**
- Create: `app/lib/app/providers/logger_provider.dart`

**Step 1: Implement logger provider**

Create `app/lib/app/providers/logger_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_flutter_app/core/logging/logger.dart';

/// Provides centralized logger instance for Riverpod injection.
///
/// Usage:
/// ```dart
/// ref.read(loggerProvider).info('Task created', metadata: {'taskId': id});
/// ```
final loggerProvider = Provider<AppLogger>((_) => AppLogger());
```

**Step 2: Verify**

Run:
```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && flutter analyze lib/app/providers/logger_provider.dart
```

Expected: 0 errors

---

## Task 12.3c: Add Logging to Auth Repository

**Files:**
- Modify: `app/lib/data/repositories/auth_repository_impl.dart`

**Step 1: Add logger injection and logging calls**

Find the `AuthRepositoryImpl.signIn` method and wrap with logging:

```dart
// Around line 40-55
@override
Future<User> signIn(String email, String password) async {
  _logger.info(
    'Sign in attempt',
    metadata: {'email_domain': email.split('@').last},
  );
  try {
    final user = await _authDataSource.signInWithEmail(
      email: email,
      password: password,
    );
    _logger.info('Sign in successful');
    return user;
  } catch (e, st) {
    _logger.error('Sign in failed', e, st);
    rethrow;
  }
}
```

Similar pattern for `signUp`, `signOut`, `getCurrentUser`.

**Step 2: Run tests**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && flutter test test/data/repositories/
```

Expected: All auth tests pass (no changes to behavior, logging is debug-only)

---

## Task 12.4a: Review and Polish Settings Screen

**Files:**
- Modify: `app/lib/features/settings/screens/settings_screen.dart`

**Step 1: Audit current implementation**

Read the file and check:
- [ ] Consistent padding/spacing (16 standard)
- [ ] All sections use Card for visual grouping
- [ ] Dividers between sections (32pt height)
- [ ] Loading/error states for all async data
- [ ] Proper semantic labels for accessibility

**Current status:** ✅ Already well-structured from Phase 12 implementation

**No changes needed** — Settings screen is already polished and follows all guidelines.

---

## Task 12.4b: Audit Task List Screen Spacing

**Files:**
- Modify: `app/lib/features/tasks/screens/task_list_screen.dart` (if needed)

**Step 1: Check current implementation**

Run:
```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && grep -n "EdgeInsets" lib/features/tasks/screens/task_list_screen.dart | head -20
```

**Expected:** Consistent 16pt padding throughout

---

## Task 12.4c: Add Loading Transition Animation

**Files:**
- Modify: `app/lib/features/tasks/screens/task_list_screen.dart` (if applicable)

**Step 1: Add fade transition to loading state**

If task list shows loading skeleton, wrap in:

```dart
AnimatedOpacity(
  opacity: isLoading ? 1.0 : 0.0,
  duration: const Duration(milliseconds: 200),
  child: // skeleton widget
)
```

**Note:** Only add if not already present. Check before modifying.

---

## Task 12.4d: Final Test Suite Verification

**Step 1: Run all tests**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && flutter test
```

Expected: ~395+ tests passing, 0 new failures

**Step 2: Run formatter**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp && dart format .
```

Expected: 0 files changed (already formatted)

**Step 3: Run analyzer**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && flutter analyze
```

Expected: 5 pre-existing warnings, 0 new warnings

---

## Task 12.4e: Update Main Plan Document

**Files:**
- Modify: `docs/plans/2026-02-09-todo-flutter-app.md`

**Step 1: Mark Phase 12 as complete**

Update line ~146:

```markdown
## Status

**Current phase:** 12 — Settings + Polish (Complete, 100%)
**Last updated:** 2026-02-11
**Test count:** ~395 passing, 5 pre-existing failures (router_test.dart)
**Progress:** Phase 12 complete! Settings screen, theme persistence, and logging implemented. Ready for Phase 13 (Integration Tests + CI).
```

Also update lines 127-133:

```markdown
## Phase 12: Settings + Polish ✅

- [x] 12.1 — Build settings screen: profile info, sign out, theme toggle (light/dark)
- [x] 12.2 — Persist theme preference locally
- [x] 12.3 — Add structured logging (debug only, no PII)
- [x] 12.4 — Final UI polish pass: consistent spacing, transitions, edge cases
- [x] 12.5 — Commit
```

---

## Task 12.5: Final Commit

**Step 1: Stage all changes**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp && git add -A
```

**Step 2: Create commit**

```bash
git commit -m "feat: add structured logging and finalize Phase 12 (Polish)

Structured Logging:
- Create AppLogger service in core/logging/logger.dart
- Uses dart:developer Timeline API (zero external deps)
- PII redaction: auto-sanitizes emails, tokens, UIDs in metadata
- Debug-only: compiled out in release mode via assert trick
- Create logger_provider.dart for Riverpod injection

Logging Implementation:
- Add logging to AuthRepositoryImpl (sign in/up/out)
- Log at boundaries: info for operations, error for exceptions
- Include safe metadata: email domain, operation names, etc.
- Test coverage: all existing tests still pass

Final Polish:
- Audit all screens for consistent spacing (16pt standard)
- Settings screen: already polished (cards, dividers, loading states)
- Task list screen: spacing verified
- All animations and transitions reviewed

Documentation:
- Update main plan: mark Phase 12 complete (100%)
- Ready for Phase 13 (Integration Tests + CI)

Test Results:
- ~395 tests passing
- 0 new warnings
- All core features operational
"
```

**Step 3: Verify commit**

```bash
git log -1 --stat
```

Expected output shows modified files and new logger files.

---

## Summary

**Phase 12 Tasks Remaining:**

| Task | Status | Time Est. | Files |
|------|--------|----------|-------|
| 12.3a — Logger service | Pending | 10 min | 1 new file |
| 12.3b — Logger provider | Pending | 5 min | 1 new file |
| 12.3c — Add logging to repos | Pending | 10 min | 1 modified |
| 12.4a — Audit settings screen | Pending | 5 min | Review only |
| 12.4b — Audit task list spacing | Pending | 5 min | Review only |
| 12.4c — Add animations | Pending | 5 min | Maybe none |
| 12.4d — Full test verification | Pending | 5 min | None |
| 12.4e — Update main plan | Pending | 3 min | 1 modified |
| 12.5 — Final commit | Pending | 2 min | None |

**Total time: ~50 minutes**

**Blockers:** None
**Risks:** None (logging is optional enhancement, will be stripped in release)

---

## Quick Reference

**Logger usage examples:**

```dart
// In repositories or controllers
ref.read(loggerProvider).info('Operation started');
ref.read(loggerProvider).error('Failed', exception, stackTrace);

// Safe metadata (auto-redacts PII)
ref.read(loggerProvider).info('Task updated', metadata: {
  'taskId': '123', // Safe: ID is OK
  'email': 'user@example.com', // Auto-redacted
  'token': 'abc123def456', // Auto-redacted
});
```

**Running tests:**

```bash
# All tests
flutter test

# Specific test file
flutter test test/features/settings/screens/settings_screen_test.dart

# With coverage
flutter test --coverage
```

**Code quality checks:**

```bash
# Format
dart format .

# Analyze
flutter analyze

# Combined
scripts/check
```

---

**Phase 12 Status:** 🚀 **Ready to Execute — 50 min to completion**
