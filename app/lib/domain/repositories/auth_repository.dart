import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/user.dart';

/// Repository interface for authentication operations.
///
/// Abstracts away the underlying authentication provider (Firebase, etc.)
/// and returns typed [AppFailure] objects instead of raw platform exceptions.
///
/// Implementations must:
/// - Map Firebase/platform exceptions to [AuthFailure] subclasses
/// - Manage authentication state and session persistence
/// - Never throw exceptions; always return failures or success values
abstract interface class AuthRepository {
  /// Returns the current authenticated user, or null if not signed in.
  ///
  /// Does not make network requests — uses cached session state.
  /// Returns a [User] if authenticated, `null` if signed out.
  User? get currentUser;

  /// Stream of authentication state changes.
  ///
  /// Emits the current user whenever authentication state changes
  /// (sign in, sign out, user data refresh, etc.).
  /// Emits `null` when the user is signed out.
  Stream<User?> get authStateChanges;

  /// Signs in with email and password.
  ///
  /// Returns the authenticated [User] on success, or an [AuthFailure]
  /// if the credentials are invalid or the account is disabled.
  Future<(User, AuthFailure?)> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates a new account with email and password.
  ///
  /// Returns the newly created [User] on success, or an [AuthFailure]
  /// if the email is already registered or the password is too weak.
  Future<(User, AuthFailure?)> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Signs in using Google Sign-In.
  ///
  /// On Android, uses the native Google Sign-In SDK.
  /// Returns the authenticated [User] on success, or an [AuthFailure]
  /// if the flow was cancelled or the authentication fails.
  Future<(User, AuthFailure?)> signInWithGoogle();

  /// Signs out the current user.
  ///
  /// Clears the session and local authentication state.
  /// Always succeeds; idempotent.
  Future<void> signOut();

  /// Sends a password reset email to the given address.
  ///
  /// Returns `null` on success, or an [AuthFailure] if the email is not found
  /// or the operation fails.
  Future<AuthFailure?> sendPasswordResetEmail(String email);

  /// Refreshes the current user's claims and profile.
  ///
  /// Called periodically or after sensitive operations to ensure
  /// the cached user data is up to date. Returns `null` on success
  /// or an [AuthFailure] if the refresh fails.
  Future<AuthFailure?> refreshUser();
}
