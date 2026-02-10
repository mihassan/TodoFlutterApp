import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/repositories/auth_repository.dart';
import 'package:todo_flutter_app/features/auth/providers/auth_provider.dart';

/// State for authentication form operations (sign in, sign up, etc.).
///
/// Tracks loading state and the latest error.
class AuthFormState {
  const AuthFormState({this.isLoading = false, this.failure});

  final bool isLoading;
  final AuthFailure? failure;

  AuthFormState copyWith({bool? isLoading, AuthFailure? failure}) {
    return AuthFormState(
      isLoading: isLoading ?? this.isLoading,
      failure: failure,
    );
  }

  /// Returns a copy with the error cleared.
  AuthFormState clearError() {
    return AuthFormState(isLoading: isLoading);
  }
}

/// Controller for authentication operations.
///
/// Delegates to [AuthRepository] and updates [AuthFormState].
class AuthController extends StateNotifier<AuthFormState> {
  AuthController({required AuthRepository repository})
    : _repository = repository,
      super(const AuthFormState());

  final AuthRepository _repository;

  /// Signs in with email and password.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.clearError().copyWith(isLoading: true);

    final (_, failure) = await _repository.signInWithEmail(
      email: email,
      password: password,
    );

    if (failure != null) {
      state = AuthFormState(failure: failure);
      return false;
    }

    state = const AuthFormState();
    return true;
  }

  /// Creates a new account with email and password.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.clearError().copyWith(isLoading: true);

    final (_, failure) = await _repository.signUpWithEmail(
      email: email,
      password: password,
    );

    if (failure != null) {
      state = AuthFormState(failure: failure);
      return false;
    }

    state = const AuthFormState();
    return true;
  }

  /// Signs in with Google.
  ///
  /// Returns `true` on success, `false` on failure or cancellation.
  Future<bool> signInWithGoogle() async {
    state = state.clearError().copyWith(isLoading: true);

    final (_, failure) = await _repository.signInWithGoogle();

    if (failure != null) {
      state = AuthFormState(failure: failure);
      return false;
    }

    state = const AuthFormState();
    return true;
  }

  /// Sends a password reset email.
  ///
  /// Returns `true` on success, `false` on failure.
  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.clearError().copyWith(isLoading: true);

    final failure = await _repository.sendPasswordResetEmail(email);

    if (failure != null) {
      state = AuthFormState(failure: failure);
      return false;
    }

    state = const AuthFormState();
    return true;
  }

  /// Clears any current error.
  void clearError() {
    state = state.clearError();
  }
}

/// Provides the [AuthController] for the auth screens.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthFormState>((ref) {
      final repo = ref.watch(authRepositoryProvider);
      return AuthController(repository: repo);
    });
