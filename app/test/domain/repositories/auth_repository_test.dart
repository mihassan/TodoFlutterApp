import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/repositories/fake_auth_repository.dart';
import 'package:todo_flutter_app/domain/repositories/auth_repository.dart';

void main() {
  group('AuthRepository — ', () {
    late AuthRepository authRepo;

    setUp(() {
      authRepo = FakeAuthRepository();
    });

    group('sign in with email — ', () {
      test('succeeds with valid credentials', () async {
        // Arrange: first, sign up a user
        await authRepo.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Reset to signed out
        await authRepo.signOut();

        // Act: sign in with the registered email
        final (user, failure) = await authRepo.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(failure, isNull);
        expect(user.email, 'test@example.com');
        expect(authRepo.currentUser, user);
      });

      test('fails with invalid password', () async {
        // Arrange: sign up a user
        await authRepo.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act: try to sign in with wrong password
        final (user, failure) = await authRepo.signInWithEmail(
          email: 'test@example.com',
          password: 'wrongpassword',
        );

        // Assert
        expect(failure, isA<InvalidCredentials>());
      });

      test('fails with unknown email', () async {
        // Act
        final (user, failure) = await authRepo.signInWithEmail(
          email: 'unknown@example.com',
          password: 'password123',
        );

        // Assert
        expect(failure, isA<InvalidCredentials>());
      });
    });

    group('sign up with email — ', () {
      test('creates a new user with valid inputs', () async {
        // Act
        final (user, failure) = await authRepo.signUpWithEmail(
          email: 'newuser@example.com',
          password: 'password123',
        );

        // Assert
        expect(failure, isNull);
        expect(user.email, 'newuser@example.com');
        expect(user.uid, isNotEmpty);
        expect(authRepo.currentUser, user);
      });

      test('fails if email already exists', () async {
        // Arrange: sign up a user
        await authRepo.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act: try to sign up with same email
        final (user, failure) = await authRepo.signUpWithEmail(
          email: 'test@example.com',
          password: 'newpassword',
        );

        // Assert
        expect(failure, isA<EmailAlreadyInUse>());
      });

      test('fails with weak password', () async {
        // Act
        final (user, failure) = await authRepo.signUpWithEmail(
          email: 'test@example.com',
          password: 'short', // Less than 6 chars
        );

        // Assert
        expect(failure, isA<WeakPassword>());
      });
    });

    group('sign out — ', () {
      test('clears current user', () async {
        // Arrange: sign up and sign in
        await authRepo.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        await authRepo.signOut();

        // Assert
        expect(authRepo.currentUser, isNull);
      });
    });

    group('auth state changes — ', () {
      test('emits null initially', () async {
        // Act & Assert
        final firstValue = await authRepo.authStateChanges.first;
        expect(firstValue, isNull);
      });

      test('emits user after sign up', () async {
        // Arrange: subscribe to stream before signing up
        final states = <Object?>[];
        authRepo.authStateChanges.listen((user) {
          states.add(user);
        });

        // Act
        await authRepo.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Allow async processing
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: should have emitted [null, user]
        expect(states.length, greaterThanOrEqualTo(1));
        expect(states.last, isNotNull);
      });

      test('emits null after sign out', () async {
        // Arrange: sign in
        await authRepo.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        final states = <Object?>[];
        authRepo.authStateChanges.listen((user) {
          states.add(user);
        });

        // Act
        await authRepo.signOut();

        // Allow async processing
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(states.last, isNull);
      });
    });

    group('send password reset email — ', () {
      test('succeeds if email exists', () async {
        // Arrange: sign up a user
        await authRepo.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final failure = await authRepo.sendPasswordResetEmail(
          'test@example.com',
        );

        // Assert
        expect(failure, isNull);
      });

      test('fails if email does not exist', () async {
        // Act
        final failure = await authRepo.sendPasswordResetEmail(
          'unknown@example.com',
        );

        // Assert
        expect(failure, isA<AuthFailure>());
      });
    });

    group('sign in with google — ', () {
      test('creates a new google user', () async {
        // Act
        final (user, failure) = await authRepo.signInWithGoogle();

        // Assert
        expect(failure, isNull);
        expect(user.email, contains('gmail.com'));
        expect(authRepo.currentUser, user);
      });
    });

    group('refresh user — ', () {
      test('always succeeds', () async {
        // Act
        final failure = await authRepo.refreshUser();

        // Assert
        expect(failure, isNull);
      });
    });
  });
}
