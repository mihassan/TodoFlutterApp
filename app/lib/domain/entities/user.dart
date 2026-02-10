import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';

/// An authenticated user in the application.
///
/// Domain entity — contains no persistence or serialization logic.
/// Represents the minimal user profile needed for the app.
@freezed
abstract class User with _$User {
  const factory User({
    /// Unique identifier from the auth provider (Firebase UID).
    required String uid,

    /// Email address (always present for email/password and Google sign-in).
    required String email,

    /// Display name if available (nullable).
    String? displayName,

    /// URL to profile photo if available (nullable).
    String? photoUrl,

    /// When the user account was created (UTC).
    required DateTime createdAt,

    /// When the user profile was last updated (UTC).
    required DateTime updatedAt,
  }) = _User;
}
