import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import 'package:todo_flutter_app/domain/entities/user.dart';

/// Data source that wraps Firebase Authentication SDK calls.
///
/// This class is the single point of contact with the Firebase Auth SDK.
/// It translates Firebase types into domain types ([User]) and lets
/// raw [fb.FirebaseAuthException]s propagate — the repository layer
/// is responsible for mapping them to typed [AuthFailure]s.
class FirebaseAuthDataSource {
  /// Creates a [FirebaseAuthDataSource].
  ///
  /// Accepts optional [firebaseAuth] and [googleSignIn] instances
  /// for dependency injection (useful in tests).
  FirebaseAuthDataSource({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  }) : _auth = firebaseAuth ?? fb.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  /// The currently signed-in user, or `null`.
  User? get currentUser => _mapUser(_auth.currentUser);

  /// Stream of auth state changes, mapped to domain [User].
  Stream<User?> get authStateChanges => _auth.authStateChanges().map(_mapUser);

  /// Signs in with email and password.
  ///
  /// Throws [fb.FirebaseAuthException] on failure.
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapUser(credential.user)!;
  }

  /// Creates a new account with email and password.
  ///
  /// Throws [fb.FirebaseAuthException] on failure.
  Future<User> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapUser(credential.user)!;
  }

  /// Signs in using Google Sign-In.
  ///
  /// Returns `null` if the user cancels the Google sign-in flow.
  /// Throws [fb.FirebaseAuthException] on Firebase-level failure.
  Future<User?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the sign-in flow.
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    return _mapUser(userCredential.user)!;
  }

  /// Signs out from both Firebase and Google.
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  /// Sends a password reset email.
  ///
  /// Throws [fb.FirebaseAuthException] on failure.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Reloads the current user's profile from the server.
  ///
  /// Throws [fb.FirebaseAuthException] on failure.
  Future<void> refreshUser() async {
    await _auth.currentUser?.reload();
  }

  /// Maps a Firebase [fb.User] to our domain [User].
  ///
  /// Returns `null` if [firebaseUser] is `null`.
  User? _mapUser(fb.User? firebaseUser) {
    if (firebaseUser == null) return null;

    final now = DateTime.now().toUtc();
    final createdAt = firebaseUser.metadata.creationTime?.toUtc() ?? now;
    final lastSignIn = firebaseUser.metadata.lastSignInTime?.toUtc() ?? now;

    return User(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: createdAt,
      updatedAt: lastSignIn,
    );
  }
}
