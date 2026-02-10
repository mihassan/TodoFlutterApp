# Phase 12: Settings + Polish

> **For Claude:** Execute this plan task-by-task. Phase 11 complete, all tests passing. Build settings screen with theme toggle, profile info, sign out.

**Goal:** Implement settings screen with theme preference persistence, sign out functionality, and final UI polish.

**Architecture:**
- Theme mode provider: light/dark/system mode with persistent storage
- Settings controller: state notifier for managing settings changes
- SettingsScreen: display profile, theme toggle, sign out
- Shared preferences for persistence (simple key-value store)
- Wire theme mode to MaterialApp.themeMode

**Tech Stack:** Riverpod, shared_preferences, Flutter material widgets

---

## Task 1: Add shared_preferences to pubspec.yaml

**Step 1: Update pubspec.yaml**

Open `app/pubspec.yaml` and add `shared_preferences` to dependencies (under `path_provider`):

```yaml
dependencies:
  # ... existing packages ...
  shared_preferences: ^2.2.2
```

**Step 2: Run pub get**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && flutter pub get
```

**Expected output:**
```
Running "flutter pub get" in app...
+ shared_preferences 2.2.2
```

---

## Task 2: Create Theme Mode Provider

**Files:**
- Create: `app/lib/app/providers/theme_provider.dart`

**Step 1: Define ThemeMode enum and persistence logic**

Create `app/lib/app/providers/theme_provider.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum for theme preference storage.
///
/// - `system`: Follow device settings (default on app startup)
/// - `light`: Force light theme
/// - `dark`: Force dark theme
enum AppThemeMode {
  system,
  light,
  dark;

  /// Returns the Flutter [ThemeMode] for this app theme mode.
  ThemeMode toThemeMode() {
    return switch (this) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }

  /// Parses a string back to [AppThemeMode].
  static AppThemeMode parse(String? value) {
    return switch (value) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  /// Saves this theme mode to persistent storage.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', name);
  }
}

/// Loads theme mode from persistent storage.
Future<AppThemeMode> _loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString('theme_mode');
  return AppThemeMode.parse(stored);
}

/// Riverpod provider for theme mode.
///
/// Reads from SharedPreferences on first access, then stays in sync.
/// Use [themeModeProvider.notifier] to change theme.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AsyncValue<AppThemeMode>>(
  (ref) => ThemeModeNotifier(),
);

/// State notifier to manage theme mode changes.
class ThemeModeNotifier extends StateNotifier<AsyncValue<AppThemeMode>> {
  ThemeModeNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final mode = await _loadThemeMode();
      state = AsyncValue.data(mode);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  /// Changes theme mode and persists to storage.
  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      await mode.save();
      state = AsyncValue.data(mode);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
```

**Step 2: Verify provider compiles**

Run:
```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && flutter analyze
```

Expected: 0 errors, 0 warnings

---

## Task 3: Create Settings Controller

**Files:**
- Create: `app/lib/features/settings/controllers/settings_controller.dart`

**Step 1: Define settings state**

Create the directory structure:
```bash
mkdir -p /Users/mihassan/Documents/Programming/TodoFlutterApp/app/lib/features/settings/controllers
```

Create `app/lib/features/settings/controllers/settings_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_flutter_app/app/providers/theme_provider.dart';
import 'package:todo_flutter_app/domain/repositories/auth_repository.dart';

/// Current user email (for profile display in settings).
final currentUserEmailProvider = FutureProvider<String?>((ref) async {
  final authRepo = ref.watch(authRepositoryProvider);
  final user = await authRepo.getCurrentUser();
  return user?.email;
});

/// Settings controller for managing settings operations.
final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AsyncValue<void>>(
  (ref) => SettingsController(ref),
);

/// Manages settings operations: sign out, theme changes, etc.
class SettingsController extends StateNotifier<AsyncValue<void>> {
  SettingsController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  /// Signs out the current user.
  ///
  /// Clears auth state and navigates away (handled by router with auth guard).
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      await authRepo.signOut();
      state = const AsyncValue.data(null);
      // Router will detect unauthenticated state and redirect to sign in
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }

  /// Changes the theme mode.
  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      await _ref.read(themeModeProvider.notifier).setThemeMode(mode);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    }
  }
}
```

**Step 2: Verify compilation**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && flutter analyze
```

---

## Task 4: Build Settings Screen UI

**Files:**
- Modify: `app/lib/features/settings/screens/settings_screen.dart`

**Step 1: Replace placeholder with full implementation**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_flutter_app/app/providers/theme_provider.dart';
import 'package:todo_flutter_app/core/widgets/error_banner.dart';
import 'package:todo_flutter_app/features/settings/controllers/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserEmailProvider);
    final themeModeAsync = ref.watch(themeModeProvider);
    final settingsState = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Profile section
          _buildProfileSection(context, currentUser),

          const Divider(height: 32),

          // Theme section
          _buildThemeSection(context, ref, themeModeAsync),

          const Divider(height: 32),

          // Sign out section
          _buildSignOutSection(context, ref, settingsState),

          // Error banner
          if (settingsState is AsyncError)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ErrorBanner(
                message: 'Failed: ${settingsState.error}',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, AsyncValue<String?> email) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            email.when(
                              data: (emailStr) => Text(
                                emailStr ?? 'Unknown',
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              loading: () => const SizedBox(
                                height: 16,
                                width: 100,
                                child: Placeholder(),
                              ),
                              error: (_, __) => Text(
                                'Failed to load',
                                style: TextStyle(color: Colors.red.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<AppThemeMode> themeModeAsync,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          themeModeAsync.when(
            data: (currentMode) => Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _buildThemeOption(
                      context,
                      ref,
                      AppThemeMode.system,
                      'System',
                      'Follow device settings',
                      currentMode == AppThemeMode.system,
                    ),
                    const Divider(height: 0),
                    _buildThemeOption(
                      context,
                      ref,
                      AppThemeMode.light,
                      'Light',
                      'Always use light theme',
                      currentMode == AppThemeMode.light,
                    ),
                    const Divider(height: 0),
                    _buildThemeOption(
                      context,
                      ref,
                      AppThemeMode.dark,
                      'Dark',
                      'Always use dark theme',
                      currentMode == AppThemeMode.dark,
                    ),
                  ],
                ),
              ),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (_, __) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Failed to load theme preference',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref,
    AppThemeMode mode,
    String title,
    String subtitle,
    bool isSelected,
  ) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Radio<AppThemeMode>(
        value: mode,
        groupValue: isSelected ? mode : null,
        onChanged: (selected) {
          if (selected != null) {
            ref.read(settingsControllerProvider.notifier).setThemeMode(selected);
          }
        },
      ),
      onTap: () {
        ref.read(settingsControllerProvider.notifier).setThemeMode(mode);
      },
    );
  }

  Widget _buildSignOutSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<void> settingsState,
  ) {
    final isLoading = settingsState is AsyncLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: isLoading
                  ? null
                  : () => _showSignOutDialog(context, ref),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, size: 20),
                        SizedBox(width: 8),
                        Text('Sign Out'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out?'),
          content: const Text(
            'You will need to sign in again to access your tasks.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(settingsControllerProvider.notifier).signOut();
              },
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
```

**Step 2: Verify screen compiles**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && flutter analyze
```

---

## Task 5: Wire Theme Mode to MaterialApp

**Files:**
- Modify: `app/lib/main.dart`

**Step 1: Update TodoApp widget to use theme provider**

In `main.dart`, replace the TodoApp class:

```dart
class TodoApp extends ConsumerWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(routerProvider);
    final themeModeAsync = ref.watch(themeModeProvider);

    return themeModeAsync.when(
      data: (themeMode) => MaterialApp.router(
        title: 'Todo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode.toThemeMode(),
        routerConfig: router,
      ),
      loading: () => MaterialApp(
        title: 'Todo',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
        ),
      ),
      error: (_, __) => MaterialApp(
        title: 'Todo',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Text('Failed to load theme preference'),
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Add import**

Add to the imports in `main.dart`:
```dart
import 'package:todo_flutter_app/app/providers/theme_provider.dart';
```

**Step 3: Verify compilation**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && flutter analyze
```

---

## Task 6: Write Settings Screen Tests

**Files:**
- Create: `app/test/features/settings/screens/settings_screen_test.dart`

**Step 1: Write widget tests**

Create the directory:
```bash
mkdir -p /Users/mihassan/Documents/Programming/TodoFlutterApp/app/test/features/settings/screens
```

Create `app/test/features/settings/screens/settings_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todo_flutter_app/app/providers/theme_provider.dart';
import 'package:todo_flutter_app/domain/entities/user.dart';
import 'package:todo_flutter_app/domain/repositories/auth_repository.dart';
import 'package:todo_flutter_app/features/settings/screens/settings_screen.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('SettingsScreen', () {
    testWidgets('displays profile section with user email', (tester) async {
      final mockAuth = MockAuthRepository();
      when(() => mockAuth.getCurrentUser()).thenAnswer((_) async => User(
            id: 'user1',
            email: 'test@example.com',
          ));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            themeModeProvider.overrideWith((ref) {
              return TestThemeModeNotifier();
            }),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('displays theme options', (tester) async {
      final mockAuth = MockAuthRepository();
      when(() => mockAuth.getCurrentUser())
          .thenAnswer((_) async => User(id: 'user1', email: 'test@example.com'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            themeModeProvider.overrideWith((ref) {
              return TestThemeModeNotifier();
            }),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('displays sign out button', (tester) async {
      final mockAuth = MockAuthRepository();
      when(() => mockAuth.getCurrentUser())
          .thenAnswer((_) async => User(id: 'user1', email: 'test@example.com'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            themeModeProvider.overrideWith((ref) {
              return TestThemeModeNotifier();
            }),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsWidgets);
    });

    testWidgets('shows sign out confirmation dialog when button tapped',
        (tester) async {
      final mockAuth = MockAuthRepository();
      when(() => mockAuth.getCurrentUser())
          .thenAnswer((_) async => User(id: 'user1', email: 'test@example.com'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuth),
            themeModeProvider.overrideWith((ref) {
              return TestThemeModeNotifier();
            }),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the Sign Out button in the Account section
      final signOutButton = find.widgetWithText(FilledButton, 'Sign Out');
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      expect(find.text('Sign Out?'), findsOneWidget);
      expect(
        find.text('You will need to sign in again to access your tasks.'),
        findsOneWidget,
      );
    });
  });
}

class TestThemeModeNotifier extends StateNotifier<AsyncValue<AppThemeMode>> {
  TestThemeModeNotifier() : super(const AsyncValue.data(AppThemeMode.system));

  @override
  void dispose() {
    super.dispose();
  }
}
```

**Step 2: Run tests**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && flutter test test/features/settings/screens/settings_screen_test.dart
```

Expected: 4 tests passing

---

## Task 7: Verify All Tests Pass

**Step 1: Run full test suite**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && flutter test
```

Expected: ~395+ tests passing (388 + ~7 new settings tests)

**Step 2: Check code quality**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp/app && flutter analyze
```

Expected: 0 errors, 0 warnings

---

## Task 8: Final Phase 12 Commit

**Step 1: Stage all changes**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp
git add -A
```

**Step 2: Create summary commit**

```bash
git commit -m "feat: implement settings screen with theme toggle and sign out (Phase 12)

Settings Screen Implementation:
- Profile section: display current user email
- Theme section: radio buttons for system/light/dark modes
- Sign out: confirmation dialog with auth sign out

Theme Persistence:
- Add shared_preferences dependency
- Create themeModeProvider: Riverpod state notifier for theme mode
- Theme preference stored in SharedPreferences on each change
- MaterialApp wired to respond to theme mode changes

Settings Controller:
- SettingsController: manage settings operations
- signOut() method: triggers auth sign out and router redirect
- setThemeMode() method: change and persist theme preference
- currentUserEmailProvider: fetch current user email for display

UI/UX:
- Card-based settings sections (Profile, Theme, Account)
- Radio button selection for theme mode
- Confirmation dialog for sign out
- Loading and error states throughout

Tests:
- 4 widget tests for SettingsScreen
- Profile display, theme options, sign out functionality
- Dialog confirmation behavior

All ~395 tests passing, 0 warnings"