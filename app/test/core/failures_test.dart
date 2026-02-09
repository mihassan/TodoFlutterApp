import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/core/failures.dart';

void main() {
  group('AuthFailure', () {
    test('InvalidCredentials has descriptive message', () {
      const failure = InvalidCredentials();

      expect(failure.message, 'Invalid email or password.');
      expect(failure, isA<AuthFailure>());
      expect(failure, isA<AppFailure>());
    });

    test('EmailAlreadyInUse has descriptive message', () {
      const failure = EmailAlreadyInUse();

      expect(failure.message, 'Email is already in use.');
    });

    test('WeakPassword has descriptive message', () {
      const failure = WeakPassword();

      expect(failure.message, 'Password is too weak.');
    });

    test('AccountDisabled has descriptive message', () {
      const failure = AccountDisabled();

      expect(failure.message, 'Account has been disabled.');
    });

    test('UnknownAuthFailure has default message', () {
      const failure = UnknownAuthFailure();

      expect(failure.message, 'An unknown auth error occurred.');
    });

    test('UnknownAuthFailure accepts custom message', () {
      const failure = UnknownAuthFailure('Custom auth error');

      expect(failure.message, 'Custom auth error');
    });

    test('toString includes type and message', () {
      const failure = InvalidCredentials();

      expect(
        failure.toString(),
        'InvalidCredentials: Invalid email or password.',
      );
    });
  });

  group('NetworkFailure', () {
    test('NoConnection has descriptive message', () {
      const failure = NoConnection();

      expect(failure.message, 'No internet connection.');
      expect(failure, isA<NetworkFailure>());
      expect(failure, isA<AppFailure>());
    });

    test('RequestTimeout has descriptive message', () {
      const failure = RequestTimeout();

      expect(failure.message, 'Request timed out.');
    });

    test('ServerError has default message', () {
      const failure = ServerError();

      expect(failure.message, 'Server error.');
    });

    test('ServerError accepts custom message', () {
      const failure = ServerError('503 Service Unavailable');

      expect(failure.message, '503 Service Unavailable');
    });
  });

  group('StorageFailure', () {
    test('NotFound has default message', () {
      const failure = NotFound();

      expect(failure.message, 'Record not found.');
      expect(failure, isA<StorageFailure>());
      expect(failure, isA<AppFailure>());
    });

    test('NotFound accepts custom message', () {
      const failure = NotFound('Task not found.');

      expect(failure.message, 'Task not found.');
    });

    test('DatabaseFailure has default message', () {
      const failure = DatabaseFailure();

      expect(failure.message, 'Database operation failed.');
    });

    test('FileStorageFailure has default message', () {
      const failure = FileStorageFailure();

      expect(failure.message, 'File storage operation failed.');
    });
  });

  group('ValidationFailure', () {
    test('RequiredField includes field name', () {
      const failure = RequiredField('Title');

      expect(failure.message, 'Title is required.');
      expect(failure, isA<ValidationFailure>());
      expect(failure, isA<AppFailure>());
    });

    test('MaxLengthExceeded includes field name and limit', () {
      const failure = MaxLengthExceeded('Title', 100);

      expect(failure.message, 'Title must be at most 100 characters.');
    });

    test('InvalidFormat includes field name', () {
      const failure = InvalidFormat('Email');

      expect(failure.message, 'Email has an invalid format.');
    });

    test('InvalidFormat includes detail when provided', () {
      const failure = InvalidFormat('Email', 'must contain @');

      expect(failure.message, 'Email has an invalid format: must contain @');
    });
  });

  group('sealed class hierarchy', () {
    test('can exhaustively switch on AuthFailure', () {
      const AuthFailure failure = InvalidCredentials();

      final result = switch (failure) {
        InvalidCredentials() => 'invalid',
        EmailAlreadyInUse() => 'duplicate',
        WeakPassword() => 'weak',
        AccountDisabled() => 'disabled',
        UnknownAuthFailure() => 'unknown',
      };

      expect(result, 'invalid');
    });

    test('can exhaustively switch on NetworkFailure', () {
      const NetworkFailure failure = NoConnection();

      final result = switch (failure) {
        NoConnection() => 'offline',
        RequestTimeout() => 'timeout',
        ServerError() => 'server',
      };

      expect(result, 'offline');
    });

    test('can exhaustively switch on StorageFailure', () {
      const StorageFailure failure = NotFound();

      final result = switch (failure) {
        NotFound() => 'missing',
        DatabaseFailure() => 'db',
        FileStorageFailure() => 'file',
      };

      expect(result, 'missing');
    });

    test('can exhaustively switch on ValidationFailure', () {
      const ValidationFailure failure = RequiredField('Title');

      final result = switch (failure) {
        RequiredField() => 'required',
        MaxLengthExceeded() => 'too long',
        InvalidFormat() => 'bad format',
      };

      expect(result, 'required');
    });
  });
}
