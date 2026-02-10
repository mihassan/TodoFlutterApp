import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter_app/features/auth/screens/sign_in_screen.dart';

import '../../../helpers/test_app.dart';

void main() {
  Widget buildSignInScreen() {
    return ProviderScope(
      overrides: fakeAuthOverrides(),
      child: const MaterialApp(home: SignInScreen()),
    );
  }

  group('SignInScreen — ', () {
    testWidgets('renders all expected elements', (tester) async {
      await tester.pumpWidget(buildSignInScreen());

      expect(find.text('Todo'), findsOneWidget);
      expect(find.text('Sign in to get started'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
    });

    group('form validation — ', () {
      testWidgets('shows error when email is empty', (tester) async {
        await tester.pumpWidget(buildSignInScreen());

        // Tap sign in without entering anything
        await tester.tap(find.text('Sign in'));
        await tester.pumpAndSettle();

        expect(find.text('Email is required'), findsOneWidget);
      });

      testWidgets('shows error when email is invalid', (tester) async {
        await tester.pumpWidget(buildSignInScreen());

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'notanemail',
        );
        await tester.tap(find.text('Sign in'));
        await tester.pumpAndSettle();

        expect(find.text('Enter a valid email'), findsOneWidget);
      });

      testWidgets('shows error when password is empty', (tester) async {
        await tester.pumpWidget(buildSignInScreen());

        // Enter valid email but no password
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.tap(find.text('Sign in'));
        await tester.pumpAndSettle();

        expect(find.text('Password is required'), findsOneWidget);
      });

      testWidgets('shows error when password is too short', (tester) async {
        await tester.pumpWidget(buildSignInScreen());

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          '12345',
        );
        await tester.tap(find.text('Sign in'));
        await tester.pumpAndSettle();

        expect(
          find.text('Password must be at least 6 characters'),
          findsOneWidget,
        );
      });

      testWidgets('accepts valid email and password', (tester) async {
        await tester.pumpWidget(buildSignInScreen());

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'),
          'test@example.com',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'),
          'password123',
        );
        await tester.tap(find.text('Sign in'));
        await tester.pumpAndSettle();

        // No validation error messages should appear
        expect(find.text('Email is required'), findsNothing);
        expect(find.text('Enter a valid email'), findsNothing);
        expect(find.text('Password is required'), findsNothing);
        expect(
          find.text('Password must be at least 6 characters'),
          findsNothing,
        );
      });
    });

    testWidgets('shows error banner on sign-in failure', (tester) async {
      await tester.pumpWidget(buildSignInScreen());

      // Enter credentials for a non-existent account
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'unknown@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'password123',
      );
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      // FakeAuthRepository returns InvalidCredentials for unknown email
      expect(find.text('Invalid email or password.'), findsOneWidget);
    });

    testWidgets('has sign-up link', (tester) async {
      await tester.pumpWidget(buildSignInScreen());

      // Verify the sign-up link is present
      final signUpButton = find.widgetWithText(TextButton, 'Sign up');
      expect(signUpButton, findsOneWidget);
    });

    testWidgets('has forgot-password link', (tester) async {
      await tester.pumpWidget(buildSignInScreen());

      // Verify the forgot-password link is present
      final forgotButton = find.widgetWithText(TextButton, 'Forgot password?');
      expect(forgotButton, findsOneWidget);
    });
  });
}
