import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_flutter_app/app/providers/theme_provider.dart';
import 'package:todo_flutter_app/features/auth/providers/auth_provider.dart';

/// Provider for the current user's email.
final currentUserEmailProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.email;
});

/// Provider for the [SettingsController].
final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(ref);
});

/// Controller for settings-related actions.
class SettingsController {
  final Ref _ref;

  SettingsController(this._ref);

  /// Signs out the current user.
  Future<void> signOut() async {
    final authRepo = _ref.read(authRepositoryProvider);
    await authRepo.signOut();
  }

  /// Updates the app theme mode and persists it.
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    final notifier = _ref.read(themeModeProvider.notifier);
    await notifier.setThemeMode(themeMode);
  }
}
