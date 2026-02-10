import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:todo_flutter_app/domain/entities/user.dart';
import 'package:todo_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:todo_flutter_app/features/settings/controllers/settings_controller.dart';
import 'package:todo_flutter_app/features/settings/screens/settings_screen.dart';

// ── Mocks ────────────────────────────────────────────────

class MockSettingsController extends Mock implements SettingsController {}

void main() {
  group('SettingsScreen', () {
    late MockSettingsController mockSettingsController;

    setUp(() {
      mockSettingsController = MockSettingsController();
    });

    Widget _buildScreen({User? user}) {
      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(user),
          settingsControllerProvider.overrideWithValue(mockSettingsController),
        ],
        child: MaterialApp(home: SettingsScreen()),
      );
    }

    testWidgets('renders profile section with user email', (
      WidgetTester tester,
    ) async {
      final testUser = User(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 1),
      );

      await tester.pumpWidget(_buildScreen(user: testUser));

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
    });

    testWidgets('renders theme section', (WidgetTester tester) async {
      final testUser = User(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 1),
      );

      await tester.pumpWidget(_buildScreen(user: testUser));

      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('renders account section with sign out button', (
      WidgetTester tester,
    ) async {
      final testUser = User(
        uid: 'test-uid',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime.utc(2024, 1, 1),
        updatedAt: DateTime.utc(2024, 1, 1),
      );

      await tester.pumpWidget(_buildScreen(user: testUser));

      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('null user email shows "No email"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_buildScreen(user: null));

      expect(find.text('No email'), findsOneWidget);
    });

    testWidgets('has settings appbar title', (WidgetTester tester) async {
      await tester.pumpWidget(_buildScreen(user: null));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
