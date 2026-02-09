/// Base class for all typed failures in the application.
///
/// Repositories map raw exceptions (Firebase, SQLite, network, etc.) into
/// these typed failures so that upper layers never see platform-specific
/// error types.
sealed class AppFailure {
  const AppFailure(this.message);

  /// Human-readable description of what went wrong.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

// ── Auth ────────────────────────────────────────────────

/// Failures originating from authentication operations.
sealed class AuthFailure extends AppFailure {
  const AuthFailure(super.message);
}

/// The email/password combination was invalid.
class InvalidCredentials extends AuthFailure {
  const InvalidCredentials() : super('Invalid email or password.');
}

/// The email address is already registered.
class EmailAlreadyInUse extends AuthFailure {
  const EmailAlreadyInUse() : super('Email is already in use.');
}

/// The password does not meet strength requirements.
class WeakPassword extends AuthFailure {
  const WeakPassword() : super('Password is too weak.');
}

/// The user's account has been disabled.
class AccountDisabled extends AuthFailure {
  const AccountDisabled() : super('Account has been disabled.');
}

/// A catch-all for unexpected auth errors.
class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure([super.message = 'An unknown auth error occurred.']);
}

// ── Network ─────────────────────────────────────────────

/// Failures related to network connectivity or remote service availability.
sealed class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

/// The device has no internet connection.
class NoConnection extends NetworkFailure {
  const NoConnection() : super('No internet connection.');
}

/// A request to a remote service timed out.
class RequestTimeout extends NetworkFailure {
  const RequestTimeout() : super('Request timed out.');
}

/// The remote server returned an unexpected error.
class ServerError extends NetworkFailure {
  const ServerError([super.message = 'Server error.']);
}

// ── Storage ─────────────────────────────────────────────

/// Failures originating from local or remote data storage.
sealed class StorageFailure extends AppFailure {
  const StorageFailure(super.message);
}

/// The requested record was not found.
class NotFound extends StorageFailure {
  const NotFound([super.message = 'Record not found.']);
}

/// A database read/write operation failed.
class DatabaseFailure extends StorageFailure {
  const DatabaseFailure([super.message = 'Database operation failed.']);
}

/// A file upload or download failed.
class FileStorageFailure extends StorageFailure {
  const FileStorageFailure([super.message = 'File storage operation failed.']);
}

// ── Validation ──────────────────────────────────────────

/// Failures caused by invalid user input.
sealed class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
}

/// A required field was left empty.
class RequiredField extends ValidationFailure {
  const RequiredField(String fieldName) : super('$fieldName is required.');
}

/// A field value exceeded its maximum allowed length.
class MaxLengthExceeded extends ValidationFailure {
  const MaxLengthExceeded(String fieldName, int maxLength)
    : super('$fieldName must be at most $maxLength characters.');
}

/// A field value did not match the expected format.
class InvalidFormat extends ValidationFailure {
  const InvalidFormat(String fieldName, [String? detail])
    : super(
        detail != null
            ? '$fieldName has an invalid format: $detail'
            : '$fieldName has an invalid format.',
      );
}
