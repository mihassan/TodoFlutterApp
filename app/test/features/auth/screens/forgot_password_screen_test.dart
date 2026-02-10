import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter_app/data/repositories/fake_auth_repository.dart';
import 'package:todo_flutter_app/domain/entities/user.dart';
import 'package:todo_flutter_app/features/auth/screens/forgot_password_screen.dart';

import '../../../helpers/test_app.dart';

void main() {
  Widget buildForgotPasswordScreen({FakeAuthRepository? repo}) {
    return ProviderScope(
      overrides: fakeAuthOverrides(repository: repo),
      child: const MaterialApp(home: ForgotPasswordScreen()),
    );
  }

  group('ForgotPasswordScreen — ', () {
    testWidgets('renders all expected elements', (tester) async {
      await tester.pumpWidget(buildForgotPasswordScreen());

      expect(find.text('Reset password'), findsOneWidget);
      expect(
        find.textContaining("Enter your email and we'll send you a link"),
        findsOneWidget,
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    group('form validation — ', () {
      testWidgets('shows error when email is empty', (tester) async {
        await tester.pumpWidget(buildForgotPasswordScreen());

        await tester.tap(find.text('Send reset link'));
        await tester.pumpAndSettle();

        expect(find.text('Email is required'), findsOneWidget);
      });

      testWidgets('shows error when email is invalid', (tester) async {
        await tester.pumpWidget(buildForgotPasswordScreen());

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'notanemail',
        );
        await tester.tap(find.text('Send reset link'));
        await tester.pumpAndSettle();

        expect(find.text('Enter a valid email'), findsOneWidget);
      });
    });

    testWidgets('shows success state after sending reset email', (
      tester,
    ) async {
      // Arrange: create a repo with a known user
      final repo = _seededRepo('test@example.com');
      await tester.pumpWidget(buildForgotPasswordScreen(repo: repo));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'test@example.com',
      );
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      // Success state
      expect(find.text('Check your email'), findsOneWidget);
      expect(
        find.textContaining('We sent a password reset link to'),
        findsOneWidget,
      );
      expect(find.text('Back to sign in'), findsOneWidget);

      // Form should no longer be visible
      expect(find.text('Send reset link'), findsNothing);
    });

    testWidgets('shows error banner when email not found', (tester) async {
      await tester.pumpWidget(buildForgotPasswordScreen());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'unknown@example.com',
      );
      await tester.tap(find.text('Send reset link'));
      await tester.pumpAndSettle();

      // FakeAuthRepository returns an error for unknown email
      expect(find.textContaining('Email not found'), findsOneWidget);
    });

    testWidgets('has a back button', (tester) async {
      await tester.pumpWidget(buildForgotPasswordScreen());

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}

/// Creates a [FakeAuthRepository] pre-seeded with a user.
FakeAuthRepository _seededRepo(String email) {
  final now = DateTime.now().toUtc();
  final user = User(
    uid: 'uid_${email.hashCode}',
    email: email,
    createdAt: now,
    updatedAt: now,
  );
  return FakeAuthRepository(users: {user.uid: user});
}
