import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter_app/data/repositories/fake_auth_repository.dart';
import 'package:todo_flutter_app/domain/entities/user.dart';
import 'package:todo_flutter_app/features/auth/screens/sign_up_screen.dart';

import '../../../helpers/test_app.dart';

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

void main() {
  Widget buildSignUpScreen() {
    return ProviderScope(
      overrides: fakeAuthOverrides(),
      child: const MaterialApp(home: SignUpScreen()),
    );
  }

  group('SignUpScreen — ', () {
    testWidgets('renders all expected elements', (tester) async {
      await tester.pumpWidget(buildSignUpScreen());

      expect(find.text('Create account'), findsOneWidget);
      expect(find.text('Sign up to start managing your tasks'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Sign up'), findsWidgets); // button + nav link
    });

    group('form validation — ', () {
      testWidgets('shows error when email is empty', (tester) async {
        await tester.pumpWidget(buildSignUpScreen());

        await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
        await tester.pumpAndSettle();

        expect(find.text('Email is required'), findsOneWidget);
      });

      testWidgets('shows error when email is invalid', (tester) async {
        await tester.pumpWidget(buildSignUpScreen());

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'notanemail',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
        await tester.pumpAndSettle();

        expect(find.text('Enter a valid email'), findsOneWidget);
      });

      testWidgets('shows error when password is empty', (tester) async {
        await tester.pumpWidget(buildSignUpScreen());

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
        await tester.pumpAndSettle();

        expect(find.text('Password is required'), findsOneWidget);
      });

      testWidgets('shows error when password is too short', (tester) async {
        await tester.pumpWidget(buildSignUpScreen());

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          '12345',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
        await tester.pumpAndSettle();

        expect(
          find.text('Password must be at least 6 characters'),
          findsOneWidget,
        );
      });

      testWidgets('shows error when confirm password is empty', (tester) async {
        await tester.pumpWidget(buildSignUpScreen());

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
        await tester.pumpAndSettle();

        expect(find.text('Please confirm your password'), findsOneWidget);
      });

      testWidgets('shows error when passwords do not match', (tester) async {
        await tester.pumpWidget(buildSignUpScreen());

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'),
          'different456',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
        await tester.pumpAndSettle();

        expect(find.text('Passwords do not match'), findsOneWidget);
      });

      testWidgets('accepts valid inputs', (tester) async {
        await tester.pumpWidget(buildSignUpScreen());

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm password'),
          'password123',
        );
        await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
        await tester.pumpAndSettle();

        // No validation errors should appear
        expect(find.text('Email is required'), findsNothing);
        expect(find.text('Enter a valid email'), findsNothing);
        expect(find.text('Password is required'), findsNothing);
        expect(find.text('Please confirm your password'), findsNothing);
        expect(find.text('Passwords do not match'), findsNothing);
      });
    });

    testWidgets('shows error banner on sign-up failure (email in use)', (
      tester,
    ) async {
      // Pre-seed a user in the fake repository
      final repo = _seededRepo('existing@example.com');
      await tester.pumpWidget(
        ProviderScope(
          overrides: fakeAuthOverrides(repository: repo),
          child: const MaterialApp(home: SignUpScreen()),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'existing@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Confirm password'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Sign up'));
      await tester.pumpAndSettle();

      expect(find.text('Email is already in use.'), findsOneWidget);
    });

    testWidgets('has a back button', (tester) async {
      await tester.pumpWidget(buildSignUpScreen());

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });
}
