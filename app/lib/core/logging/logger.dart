import 'dart:developer' as developer;

/// Structured logger for debugging (debug mode only, no PII).
///
/// Uses dart:developer Timeline API for structured logging.
/// All logs are stripped in release mode via conditional compilation.
class AppLogger {
  static const String _logPrefix = '[TodoApp]';

  /// Logs an info-level message with optional metadata.
  static void info(String message, {Map<String, dynamic>? metadata}) {
    if (!_isDebugMode) return;
    developer.log(
      message,
      name: '$_logPrefix.info',
      level: 800, // INFO level
      time: DateTime.now(),
    );
    if (metadata != null) {
      developer.log(
        'Metadata: ${_sanitizeMetadata(metadata)}',
        name: '$_logPrefix.info',
        level: 800,
      );
    }
  }

  /// Logs a debug-level message (verbose, development only).
  static void debug(String message, {Map<String, dynamic>? metadata}) {
    if (!_isDebugMode) return;
    developer.log(
      message,
      name: '$_logPrefix.debug',
      level: 700, // DEBUG level
    );
  }

  /// Logs a warning-level message (potential issues).
  static void warning(String message, {Map<String, dynamic>? metadata}) {
    if (!_isDebugMode) return;
    developer.log(
      message,
      name: '$_logPrefix.warning',
      level: 900, // WARNING level
    );
    if (metadata != null) {
      developer.log(
        'Metadata: ${_sanitizeMetadata(metadata)}',
        name: '$_logPrefix.warning',
        level: 900,
      );
    }
  }

  /// Logs an error-level message with exception and stack trace.
  static void error(
    String message,
    Object exception,
    StackTrace stackTrace, {
    Map<String, dynamic>? metadata,
  }) {
    if (!_isDebugMode) return;
    developer.log(
      '$message: $exception',
      name: '$_logPrefix.error',
      level: 1000, // ERROR level
      error: exception,
      stackTrace: stackTrace,
    );
    if (metadata != null) {
      developer.log(
        'Metadata: ${_sanitizeMetadata(metadata)}',
        name: '$_logPrefix.error',
        level: 1000,
      );
    }
  }

  /// Sanitizes metadata to remove PII (emails, phone numbers, tokens).
  static Map<String, dynamic> _sanitizeMetadata(Map<String, dynamic> metadata) {
    final sanitized = <String, dynamic>{};
    for (final entry in metadata.entries) {
      if (_isPII(entry.key)) {
        sanitized[entry.key] = '***REDACTED***';
      } else if (entry.value is String && _isPIIValue(entry.value as String)) {
        sanitized[entry.key] = '***REDACTED***';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }

  /// Checks if a key name suggests PII.
  static bool _isPII(String key) {
    final lowerKey = key.toLowerCase();
    return lowerKey.contains('email') ||
        lowerKey.contains('phone') ||
        lowerKey.contains('token') ||
        lowerKey.contains('password') ||
        lowerKey.contains('secret') ||
        lowerKey.contains('uid') ||
        lowerKey.contains('id');
  }

  /// Checks if a value looks like PII (email, token, etc.).
  static bool _isPIIValue(String value) {
    // Email pattern
    if (value.contains('@') && value.contains('.')) return true;
    // Hex token pattern (32+ hex chars)
    if (RegExp(r'^[a-f0-9]{32,}$').hasMatch(value)) return true;
    return false;
  }

  /// Checks if running in debug mode.
  static bool get _isDebugMode {
    bool isDebugMode = false;
    assert(isDebugMode = true);
    return isDebugMode;
  }
}
