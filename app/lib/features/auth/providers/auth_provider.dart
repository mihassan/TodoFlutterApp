import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_flutter_app/data/data_sources/remote/firebase_auth_data_source.dart';
import 'package:todo_flutter_app/data/repositories/auth_repository_impl.dart';
import 'package:todo_flutter_app/domain/entities/user.dart';
import 'package:todo_flutter_app/domain/repositories/auth_repository.dart';

/// Provides the [FirebaseAuthDataSource] singleton.
///
/// Override in tests with a mock or fake data source.
final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>(
  (_) => FirebaseAuthDataSource(),
);

/// Provides the [AuthRepository] backed by Firebase.
///
/// Override in tests with [FakeAuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(firebaseAuthDataSourceProvider);
  return AuthRepositoryImpl(dataSource: dataSource);
});

/// Streams the current authenticated user (or `null` if signed out).
///
/// Rebuilds automatically whenever Firebase auth state changes
/// (sign in, sign out, token refresh, etc.).
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// The currently authenticated user, or `null` if not signed in.
///
/// Derived from [authStateProvider]; returns `null` while loading.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// Whether the user is currently authenticated.
///
/// Used by the router for auth-guard redirects.
/// Returns `false` while the auth state is still loading.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});
