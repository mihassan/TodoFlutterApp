import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/user.dart';
import 'package:todo_flutter_app/domain/repositories/auth_repository.dart';

/// A fake implementation of [AuthRepository] for testing.
///
/// Stores users in memory and does not require Firebase.
/// Useful for unit tests and widget tests that need authentication.
class FakeAuthRepository implements AuthRepository {
  /// Creates a [FakeAuthRepository].
  ///
  /// Optionally provide an initial [currentUser] and a [users] map
  /// for testing scenarios with multiple accounts.
  FakeAuthRepository({this.currentUser, Map<String, User>? users})
    : _users = users ?? {},
      _passwords = {} {
    if (currentUser != null) {
      _users[currentUser!.uid] = currentUser!;
    }
  }

  /// In-memory store of users by UID.
  final Map<String, User> _users;

  /// In-memory store of passwords by UID (for testing only).
  final Map<String, String> _passwords;

  /// Stream controller for auth state changes.
  final List<void Function(User?)> _authStateListeners = [];

  @override
  User? currentUser;

  @override
  Stream<User?> get authStateChanges {
    return Stream.multi((controller) {
      // Emit current state immediately
      controller.add(currentUser);

      // Add listener for future changes
      void listener(User? user) {
        controller.add(user);
      }

      _authStateListeners.add(listener);

      controller.onCancel = () {
        _authStateListeners.remove(listener);
      };
    });
  }

  @override
  Future<(User, AuthFailure?)> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Find user by email
    final userOrNull = _users.values.cast<User?>().firstWhere(
      (u) => u != null && u.email == email,
      orElse: () => null,
    );

    // Return failure if user not found
    if (userOrNull == null) {
      final now = DateTime.now().toUtc();
      final emptyUser = User(
        uid: '',
        email: '',
        createdAt: now,
        updatedAt: now,
      );
      return (emptyUser, const InvalidCredentials());
    }

    final user = userOrNull;

    // Verify password
    final storedPassword = _passwords[user.uid];
    if (storedPassword != password) {
      return (user, const InvalidCredentials());
    }

    currentUser = user;
    _notifyAuthStateChanged();
    return (user, null);
  }

  @override
  Future<(User, AuthFailure?)> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    // Check if email already exists
    if (_users.values.any((u) => u.email == email)) {
      final now = DateTime.now().toUtc();
      final emptyUser = User(
        uid: '',
        email: '',
        createdAt: now,
        updatedAt: now,
      );
      return (emptyUser, const EmailAlreadyInUse());
    }

    // Check password strength (mock: at least 6 chars)
    if (password.length < 6) {
      final now = DateTime.now().toUtc();
      final emptyUser = User(
        uid: '',
        email: '',
        createdAt: now,
        updatedAt: now,
      );
      return (emptyUser, const WeakPassword());
    }

    // Create new user
    final now = DateTime.now().toUtc();
    final newUser = User(
      uid: 'fake_uid_${email.hashCode}',
      email: email,
      createdAt: now,
      updatedAt: now,
    );

    _users[newUser.uid] = newUser;
    _passwords[newUser.uid] = password;
    currentUser = newUser;
    _notifyAuthStateChanged();
    return (newUser, null);
  }

  @override
  Future<(User, AuthFailure?)> signInWithGoogle() async {
    // For testing, just create a fake Google user
    final now = DateTime.now().toUtc();
    final googleUser = User(
      uid: 'google_uid_${now.millisecondsSinceEpoch}',
      email: 'testuser@gmail.com',
      displayName: 'Test User',
      createdAt: now,
      updatedAt: now,
    );

    _users[googleUser.uid] = googleUser;
    currentUser = googleUser;
    _notifyAuthStateChanged();
    return (googleUser, null);
  }

  @override
  Future<void> signOut() async {
    currentUser = null;
    _notifyAuthStateChanged();
  }

  @override
  Future<AuthFailure?> sendPasswordResetEmail(String email) async {
    final userExists = _users.values.any((u) => u.email == email);
    if (!userExists) {
      return const UnknownAuthFailure('Email not found.');
    }
    return null;
  }

  @override
  Future<AuthFailure?> refreshUser() async {
    // In a fake implementation, there's nothing to refresh
    return null;
  }

  /// Notifies all listeners of auth state change.
  void _notifyAuthStateChanged() {
    for (final listener in _authStateListeners) {
      listener(currentUser);
    }
  }
}
