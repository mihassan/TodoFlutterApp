import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/data_sources/remote/firebase_auth_data_source.dart';
import 'package:todo_flutter_app/domain/entities/user.dart';
import 'package:todo_flutter_app/domain/repositories/auth_repository.dart';

/// Production implementation of [AuthRepository] using Firebase Auth.
///
/// Delegates all SDK calls to [FirebaseAuthDataSource] and maps
/// [fb.FirebaseAuthException] codes into typed [AuthFailure] subclasses
/// so that layers above never see raw platform exceptions.
class AuthRepositoryImpl implements AuthRepository {
  /// Creates an [AuthRepositoryImpl].
  ///
  /// Accepts a [FirebaseAuthDataSource] for testability.
  AuthRepositoryImpl({required FirebaseAuthDataSource dataSource})
    : _dataSource = dataSource;

  final FirebaseAuthDataSource _dataSource;

  @override
  User? get currentUser => _dataSource.currentUser;

  @override
  Stream<User?> get authStateChanges => _dataSource.authStateChanges;

  @override
  Future<(User, AuthFailure?)> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return (user, null);
    } on fb.FirebaseAuthException catch (e) {
      return (_emptyUser(), _mapAuthException(e));
    }
  }

  @override
  Future<(User, AuthFailure?)> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _dataSource.signUpWithEmail(
        email: email,
        password: password,
      );
      return (user, null);
    } on fb.FirebaseAuthException catch (e) {
      return (_emptyUser(), _mapAuthException(e));
    }
  }

  @override
  Future<(User, AuthFailure?)> signInWithGoogle() async {
    try {
      final user = await _dataSource.signInWithGoogle();
      if (user == null) {
        // User cancelled the Google sign-in flow.
        return (
          _emptyUser(),
          const UnknownAuthFailure('Google sign-in was cancelled.'),
        );
      }
      return (user, null);
    } on fb.FirebaseAuthException catch (e) {
      return (_emptyUser(), _mapAuthException(e));
    }
  }

  @override
  Future<void> signOut() async {
    await _dataSource.signOut();
  }

  @override
  Future<AuthFailure?> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.sendPasswordResetEmail(email);
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _mapAuthException(e);
    }
  }

  @override
  Future<AuthFailure?> refreshUser() async {
    try {
      await _dataSource.refreshUser();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return _mapAuthException(e);
    }
  }

  /// Maps a [fb.FirebaseAuthException] to a typed [AuthFailure].
  AuthFailure _mapAuthException(fb.FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' ||
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => const InvalidCredentials(),
      'email-already-in-use' => const EmailAlreadyInUse(),
      'weak-password' => const WeakPassword(),
      'user-disabled' => const AccountDisabled(),
      _ => UnknownAuthFailure(e.message ?? e.code),
    };
  }

  /// Creates a placeholder [User] to satisfy the record return type
  /// when an operation fails.
  User _emptyUser() {
    final now = DateTime.now().toUtc();
    return User(uid: '', email: '', createdAt: now, updatedAt: now);
  }
}
