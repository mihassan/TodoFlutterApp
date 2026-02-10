import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/repositories/fake_auth_repository.dart';
import 'package:todo_flutter_app/features/auth/controllers/auth_controller.dart';

void main() {
  group('AuthController — ', () {
    late FakeAuthRepository repo;
    late AuthController controller;

    setUp(() {
      repo = FakeAuthRepository();
      controller = AuthController(repository: repo);
    });

    group('initial state — ', () {
      test('is not loading and has no failure', () {
        expect(controller.state.isLoading, isFalse);
        expect(controller.state.failure, isNull);
      });
    });

    group('signInWithEmail — ', () {
      test('returns true on success', () async {
        // Arrange: create an account first
        await repo.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );
        await repo.signOut();

        // Act
        final result = await controller.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, isTrue);
        expect(controller.state.isLoading, isFalse);
        expect(controller.state.failure, isNull);
      });

      test('returns false and sets failure on invalid credentials', () async {
        // Act: no account exists, so sign in will fail
        final result = await controller.signInWithEmail(
          email: 'unknown@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, isFalse);
        expect(controller.state.isLoading, isFalse);
        expect(controller.state.failure, isA<InvalidCredentials>());
      });

      test('clears previous error before starting', () async {
        // Arrange: cause a failure first
        await controller.signInWithEmail(
          email: 'unknown@example.com',
          password: 'wrong',
        );
        expect(controller.state.failure, isNotNull);

        // Act: sign in again (still fails, but error should be cleared
        // before the new attempt)
        // We capture intermediate states
        final states = <AuthFormState>[];
        controller.addListener((state) => states.add(state));

        await controller.signInWithEmail(
          email: 'unknown@example.com',
          password: 'wrong',
        );

        // Assert: first transition after listener added should have
        // loading=true and no failure (the clearError + copyWith step).
        // addListener fires immediately with the current state, so skip it.
        // states[0] = current state at addListener time (has failure)
        // states[1] = cleared + loading
        // states[2] = final failure state
        expect(states.length, greaterThanOrEqualTo(3));
        expect(states[1].isLoading, isTrue);
        expect(states[1].failure, isNull);
      });
    });

    group('signUpWithEmail — ', () {
      test('returns true on success', () async {
        final result = await controller.signUpWithEmail(
          email: 'new@example.com',
          password: 'password123',
        );

        expect(result, isTrue);
        expect(controller.state.isLoading, isFalse);
        expect(controller.state.failure, isNull);
        expect(repo.currentUser, isNotNull);
        expect(repo.currentUser!.email, 'new@example.com');
      });

      test('returns false for email already in use', () async {
        // Arrange: create an account first
        await repo.signUpWithEmail(
          email: 'existing@example.com',
          password: 'password123',
        );

        // Act: try to sign up with same email
        final result = await controller.signUpWithEmail(
          email: 'existing@example.com',
          password: 'different123',
        );

        // Assert
        expect(result, isFalse);
        expect(controller.state.failure, isA<EmailAlreadyInUse>());
      });

      test('returns false for weak password', () async {
        final result = await controller.signUpWithEmail(
          email: 'test@example.com',
          password: 'short',
        );

        expect(result, isFalse);
        expect(controller.state.failure, isA<WeakPassword>());
      });
    });

    group('signInWithGoogle — ', () {
      test('returns true on success', () async {
        final result = await controller.signInWithGoogle();

        expect(result, isTrue);
        expect(controller.state.isLoading, isFalse);
        expect(controller.state.failure, isNull);
        expect(repo.currentUser, isNotNull);
      });
    });

    group('sendPasswordResetEmail — ', () {
      test('returns true on success', () async {
        // Arrange: create a user so the email exists
        await repo.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final result = await controller.sendPasswordResetEmail(
          'test@example.com',
        );

        // Assert
        expect(result, isTrue);
        expect(controller.state.isLoading, isFalse);
        expect(controller.state.failure, isNull);
      });

      test('returns false when email not found', () async {
        final result = await controller.sendPasswordResetEmail(
          'unknown@example.com',
        );

        expect(result, isFalse);
        expect(controller.state.failure, isA<AuthFailure>());
      });
    });

    group('clearError — ', () {
      test('clears the current failure', () async {
        // Arrange: cause a failure
        await controller.signInWithEmail(
          email: 'unknown@example.com',
          password: 'wrong',
        );
        expect(controller.state.failure, isNotNull);

        // Act
        controller.clearError();

        // Assert
        expect(controller.state.failure, isNull);
        expect(controller.state.isLoading, isFalse);
      });

      test('preserves loading state when clearing', () {
        // This tests the clearError method on AuthFormState
        const state = AuthFormState(
          isLoading: true,
          failure: InvalidCredentials(),
        );
        final cleared = state.clearError();

        expect(cleared.isLoading, isTrue);
        expect(cleared.failure, isNull);
      });
    });

    group('AuthFormState — ', () {
      test('copyWith preserves defaults', () {
        const state = AuthFormState();
        final copied = state.copyWith();

        expect(copied.isLoading, isFalse);
        expect(copied.failure, isNull);
      });

      test('copyWith overrides isLoading', () {
        const state = AuthFormState();
        final copied = state.copyWith(isLoading: true);

        expect(copied.isLoading, isTrue);
      });

      test('copyWith overrides failure', () {
        const state = AuthFormState();
        final copied = state.copyWith(failure: const WeakPassword());

        expect(copied.failure, isA<WeakPassword>());
      });
    });
  });
}
