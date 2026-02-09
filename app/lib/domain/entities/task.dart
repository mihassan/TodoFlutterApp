import 'package:freezed_annotation/freezed_annotation.dart';

import 'priority.dart';

part 'task.freezed.dart';

/// A single todo task.
///
/// Domain entity — contains no persistence or serialization logic.
/// JSON serialization is handled by data-layer DTOs.
@freezed
abstract class Task with _$Task {
  const factory Task({
    /// Unique identifier (UUID v4).
    required String id,

    /// Short title describing the task.
    required String title,

    /// Optional longer description or notes.
    @Default('') String notes,

    /// Whether the task has been completed.
    @Default(false) bool isCompleted,

    /// Optional due date/time (UTC).
    DateTime? dueAt,

    /// Task priority level.
    @Default(Priority.none) Priority priority,

    /// Free-form tags for categorisation.
    @Default([]) List<String> tags,

    /// ID of the [TaskList] this task belongs to (null = Inbox).
    String? listId,

    /// When the task was created (UTC).
    required DateTime createdAt,

    /// When the task was last modified (UTC).
    required DateTime updatedAt,
  }) = _Task;
}
