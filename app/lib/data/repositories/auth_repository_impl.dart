import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/core/logging/logger.dart';
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
    AppLogger.info(
      'Sign in attempt',
      metadata: {'email_domain': email.split('@').last},
    );
    try {
      final user = await _dataSource.signInWithEmail(
        email: email,
        password: password,
      );
      AppLogger.info('Sign in successful', metadata: {'uid': user.uid});
      return (user, null);
    } on fb.FirebaseAuthException catch (e) {
      AppLogger.error('Sign in failed', e, StackTrace.current);
      return (_emptyUser(), _mapAuthException(e));
    }
  }

  @override
  Future<(User, AuthFailure?)> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    AppLogger.info(
      'Sign up attempt',
      metadata: {'email_domain': email.split('@').last},
    );
    try {
      final user = await _dataSource.signUpWithEmail(
        email: email,
        password: password,
      );
      AppLogger.info('Sign up successful', metadata: {'uid': user.uid});
      return (user, null);
    } on fb.FirebaseAuthException catch (e) {
      AppLogger.error('Sign up failed', e, StackTrace.current);
      return (_emptyUser(), _mapAuthException(e));
    }
  }

  @override
  Future<(User, AuthFailure?)> signInWithGoogle() async {
    AppLogger.info('Google sign-in attempt');
    try {
      final user = await _dataSource.signInWithGoogle();
      if (user == null) {
        // User cancelled the Google sign-in flow.
        AppLogger.info('Google sign-in cancelled by user');
        return (
          _emptyUser(),
          const UnknownAuthFailure('Google sign-in was cancelled.'),
        );
      }
      AppLogger.info('Google sign-in successful', metadata: {'uid': user.uid});
      return (user, null);
    } on fb.FirebaseAuthException catch (e) {
      AppLogger.error('Google sign-in failed', e, StackTrace.current);
      return (_emptyUser(), _mapAuthException(e));
    }
  }

  @override
  Future<void> signOut() async {
    AppLogger.info('Sign out initiated');
    await _dataSource.signOut();
    AppLogger.info('Sign out completed');
  }

  @override
  Future<AuthFailure?> sendPasswordResetEmail(String email) async {
    AppLogger.info(
      'Password reset email requested',
      metadata: {'email_domain': email.split('@').last},
    );
    try {
      await _dataSource.sendPasswordResetEmail(email);
      AppLogger.info('Password reset email sent');
      return null;
    } on fb.FirebaseAuthException catch (e) {
      AppLogger.error('Password reset email failed', e, StackTrace.current);
      return _mapAuthException(e);
    }
  }

  @override
  Future<AuthFailure?> refreshUser() async {
    AppLogger.info('User refresh initiated');
    try {
      await _dataSource.refreshUser();
      AppLogger.info('User refresh completed');
      return null;
    } on fb.FirebaseAuthException catch (e) {
      AppLogger.error('User refresh failed', e, StackTrace.current);
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
