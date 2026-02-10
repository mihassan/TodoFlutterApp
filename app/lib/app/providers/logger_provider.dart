import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todo_flutter_app/core/logging/logger.dart';

/// Provides centralized logger instance for Riverpod injection.
///
/// Usage:
/// ```dart
/// ref.read(loggerProvider).info('Task created', metadata: {'taskId': id});
/// ```
final loggerProvider = Provider<AppLogger>((_) => AppLogger());
