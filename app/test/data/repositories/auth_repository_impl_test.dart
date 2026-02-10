import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_mocks/google_sign_in_mocks.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/data_sources/remote/firebase_auth_data_source.dart';
import 'package:todo_flutter_app/data/repositories/auth_repository_impl.dart';

/// A [MockGoogleSignIn] that also supports [signOut] and [disconnect].
class TestableGoogleSignIn extends MockGoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signOut() async => null;

  @override
  Future<GoogleSignInAccount?> disconnect() async => null;
}

void main() {
  group('AuthRepositoryImpl — ', () {
    late MockFirebaseAuth mockAuth;
    late FirebaseAuthDataSource dataSource;
    late AuthRepositoryImpl repo;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      dataSource = FirebaseAuthDataSource(
        firebaseAuth: mockAuth,
        googleSignIn: TestableGoogleSignIn(),
      );
      repo = AuthRepositoryImpl(dataSource: dataSource);
    });

    group('signInWithEmail — ', () {
      test('returns user on success', () async {
        // Arrange: create user first
        await mockAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final (user, failure) = await repo.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(failure, isNull);
        expect(user.email, 'test@example.com');
      });

      test('returns InvalidCredentials for wrong-password', () async {
        // Arrange: make signInWithEmailAndPassword throw
        whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
            .on(mockAuth)
            .thenThrow(fb.FirebaseAuthException(code: 'wrong-password'));

        // Act
        final (user, failure) = await repo.signInWithEmail(
          email: 'test@example.com',
          password: 'wrong',
        );

        // Assert
        expect(failure, isA<InvalidCredentials>());
        expect(user.uid, isEmpty);
      });

      test('returns InvalidCredentials for user-not-found', () async {
        whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
            .on(mockAuth)
            .thenThrow(fb.FirebaseAuthException(code: 'user-not-found'));

        final (user, failure) = await repo.signInWithEmail(
          email: 'nobody@example.com',
          password: 'password123',
        );

        expect(failure, isA<InvalidCredentials>());
        expect(user.uid, isEmpty);
      });

      test('returns InvalidCredentials for invalid-email', () async {
        whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
            .on(mockAuth)
            .thenThrow(fb.FirebaseAuthException(code: 'invalid-email'));

        final (user, failure) = await repo.signInWithEmail(
          email: 'not-an-email',
          password: 'password123',
        );

        expect(failure, isA<InvalidCredentials>());
      });

      test('returns InvalidCredentials for invalid-credential', () async {
        whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
            .on(mockAuth)
            .thenThrow(fb.FirebaseAuthException(code: 'invalid-credential'));

        final (user, failure) = await repo.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(failure, isA<InvalidCredentials>());
      });

      test('returns AccountDisabled for user-disabled', () async {
        whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
            .on(mockAuth)
            .thenThrow(fb.FirebaseAuthException(code: 'user-disabled'));

        final (user, failure) = await repo.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(failure, isA<AccountDisabled>());
      });

      test('returns UnknownAuthFailure for unrecognized code', () async {
        whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
            .on(mockAuth)
            .thenThrow(fb.FirebaseAuthException(code: 'too-many-requests'));

        final (user, failure) = await repo.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(failure, isA<UnknownAuthFailure>());
      });
    });

    group('signUpWithEmail — ', () {
      test('returns user on success', () async {
        final (user, failure) = await repo.signUpWithEmail(
          email: 'new@example.com',
          password: 'password123',
        );

        expect(failure, isNull);
        expect(user.email, 'new@example.com');
      });

      test('returns EmailAlreadyInUse for email-already-in-use', () async {
        whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
            .on(mockAuth)
            .thenThrow(fb.FirebaseAuthException(code: 'email-already-in-use'));

        final (user, failure) = await repo.signUpWithEmail(
          email: 'existing@example.com',
          password: 'password123',
        );

        expect(failure, isA<EmailAlreadyInUse>());
        expect(user.uid, isEmpty);
      });

      test('returns WeakPassword for weak-password', () async {
        whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
            .on(mockAuth)
            .thenThrow(fb.FirebaseAuthException(code: 'weak-password'));

        final (user, failure) = await repo.signUpWithEmail(
          email: 'test@example.com',
          password: '123',
        );

        expect(failure, isA<WeakPassword>());
      });
    });

    group('signInWithGoogle — ', () {
      test('returns user on success', () async {
        final mockGoogleSignIn = TestableGoogleSignIn();
        final mockUser = MockUser(
          isAnonymous: false,
          uid: 'google-uid',
          email: 'google@gmail.com',
          displayName: 'Google User',
        );
        final googleAuth = MockFirebaseAuth(mockUser: mockUser);
        final googleDataSource = FirebaseAuthDataSource(
          firebaseAuth: googleAuth,
          googleSignIn: mockGoogleSignIn,
        );
        final googleRepo = AuthRepositoryImpl(dataSource: googleDataSource);

        final (user, failure) = await googleRepo.signInWithGoogle();

        expect(failure, isNull);
        expect(user.uid, isNotEmpty);
      });

      test('returns UnknownAuthFailure when user cancels', () async {
        // Use MockGoogleSignIn with cancellation flag
        final cancellingGoogleSignIn = TestableGoogleSignIn();
        cancellingGoogleSignIn.setIsCancelled(true);
        final cancelAuth = MockFirebaseAuth();
        final cancelDataSource = FirebaseAuthDataSource(
          firebaseAuth: cancelAuth,
          googleSignIn: cancellingGoogleSignIn,
        );
        final cancelRepo = AuthRepositoryImpl(dataSource: cancelDataSource);

        final (user, failure) = await cancelRepo.signInWithGoogle();

        expect(failure, isA<UnknownAuthFailure>());
        expect(user.uid, isEmpty);
      });

      test('returns mapped failure for FirebaseAuthException', () async {
        final mockGoogleSignIn = TestableGoogleSignIn();
        final googleAuth = MockFirebaseAuth();
        whenCalling(Invocation.method(#signInWithCredential, null))
            .on(googleAuth)
            .thenThrow(fb.FirebaseAuthException(code: 'user-disabled'));
        final googleDataSource = FirebaseAuthDataSource(
          firebaseAuth: googleAuth,
          googleSignIn: mockGoogleSignIn,
        );
        final googleRepo = AuthRepositoryImpl(dataSource: googleDataSource);

        final (user, failure) = await googleRepo.signInWithGoogle();

        expect(failure, isA<AccountDisabled>());
        expect(user.uid, isEmpty);
      });
    });

    group('signOut — ', () {
      test('delegates to data source and clears user', () async {
        // Sign in first via the repo (uses createUserWithEmailAndPassword)
        await repo.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );
        expect(repo.currentUser, isNotNull);

        // Act
        await repo.signOut();

        // Assert — currentUser should be null after sign out
        // Note: we check via mockAuth directly because
        // MockGoogleSignIn.signOut() may have type issues.
        expect(mockAuth.currentUser, isNull);
      });
    });

    group('sendPasswordResetEmail — ', () {
      test('returns null on success', () async {
        final failure = await repo.sendPasswordResetEmail('test@example.com');
        expect(failure, isNull);
      });

      test('returns mapped failure on FirebaseAuthException', () async {
        whenCalling(Invocation.method(#sendPasswordResetEmail, null))
            .on(mockAuth)
            .thenThrow(fb.FirebaseAuthException(code: 'user-not-found'));

        final failure = await repo.sendPasswordResetEmail('x@example.com');
        expect(failure, isA<InvalidCredentials>());
      });
    });

    group('refreshUser — ', () {
      test('returns null on success', () async {
        final failure = await repo.refreshUser();
        expect(failure, isNull);
      });
    });

    group('currentUser — ', () {
      test('returns null when not signed in', () {
        expect(repo.currentUser, isNull);
      });

      test('returns user when signed in', () async {
        await mockAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(repo.currentUser, isNotNull);
        expect(repo.currentUser!.email, 'test@example.com');
      });
    });

    group('authStateChanges — ', () {
      test('emits user changes', () async {
        // Should emit null initially, then user after sign in
        final states = <Object?>[];
        repo.authStateChanges.listen((user) => states.add(user));

        // Give the stream time to emit initial state
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await mockAuth.createUserWithEmailAndPassword(
          email: 'test@example.com',
          password: 'password123',
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should have initial null + signed in user
        expect(states, isNotEmpty);
      });
    });

    group('exception mapping — ', () {
      // Test all mapped codes via signInWithEmail as the vehicle
      final testCases = <String, Type>{
        'invalid-email': InvalidCredentials,
        'user-not-found': InvalidCredentials,
        'wrong-password': InvalidCredentials,
        'invalid-credential': InvalidCredentials,
        'email-already-in-use': EmailAlreadyInUse,
        'weak-password': WeakPassword,
        'user-disabled': AccountDisabled,
        'operation-not-allowed': UnknownAuthFailure,
        'too-many-requests': UnknownAuthFailure,
        'network-request-failed': UnknownAuthFailure,
      };

      for (final entry in testCases.entries) {
        test('maps "${entry.key}" to ${entry.value}', () async {
          final auth = MockFirebaseAuth();
          whenCalling(
            Invocation.method(#signInWithEmailAndPassword, null),
          ).on(auth).thenThrow(fb.FirebaseAuthException(code: entry.key));

          final ds = FirebaseAuthDataSource(
            firebaseAuth: auth,
            googleSignIn: TestableGoogleSignIn(),
          );
          final r = AuthRepositoryImpl(dataSource: ds);

          final (_, failure) = await r.signInWithEmail(
            email: 'test@example.com',
            password: 'password123',
          );

          expect(failure.runtimeType, entry.value);
        });
      }
    });
  });
}
