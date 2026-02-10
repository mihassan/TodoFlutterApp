import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options: system (device default), light, or dark.
enum AppThemeMode {
  system,
  light,
  dark;

  /// Converts enum to string for persistence.
  String toStringValue() => name;

  /// Converts string back to enum.
  static AppThemeMode fromStringValue(String value) {
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  /// Converts to Flutter's ThemeMode for MaterialApp.
  ThemeMode toFlutterThemeMode() {
    return switch (this) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
  }
}

/// Provider for shared preferences instance.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

/// Provider for current theme mode (persisted via SharedPreferences).
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, AsyncValue<AppThemeMode>>((ref) {
      final sharedPrefs = ref.watch(sharedPreferencesProvider);

      return ThemeModeNotifier(sharedPrefs);
    });

/// State notifier for managing and persisting theme mode.
class ThemeModeNotifier extends StateNotifier<AsyncValue<AppThemeMode>> {
  static const _themeKeyName = 'appThemeMode';

  final AsyncValue<SharedPreferences> sharedPrefsAsync;

  ThemeModeNotifier(this.sharedPrefsAsync) : super(const AsyncValue.loading()) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final sharedPrefs = await sharedPrefsAsync.when(
        data: (prefs) => Future.value(prefs),
        loading: () => throw Exception('SharedPreferences not initialized'),
        error: (error, stack) => Future.error(error, stack),
      );

      final themeModeString = sharedPrefs.getString(_themeKeyName) ?? 'system';
      final themeMode = AppThemeMode.fromStringValue(themeModeString);

      state = AsyncValue.data(themeMode);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }

  /// Updates theme mode and persists to SharedPreferences.
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    state = const AsyncValue.loading();
    try {
      final sharedPrefs = await sharedPrefsAsync.when(
        data: (prefs) => Future.value(prefs),
        loading: () => throw Exception('SharedPreferences not initialized'),
        error: (error, stack) => Future.error(error, stack),
      );

      await sharedPrefs.setString(_themeKeyName, themeMode.toStringValue());
      state = AsyncValue.data(themeMode);
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
    }
  }
}
