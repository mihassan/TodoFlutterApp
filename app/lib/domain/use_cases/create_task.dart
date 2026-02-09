import 'package:uuid/uuid.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';

/// Maximum allowed length for a task title.
const maxTitleLength = 200;

/// Creates a new [Task] with a generated UUID and validated fields.
///
/// Returns a [Task] on success, or a [ValidationFailure] if the title is
/// invalid.
class CreateTask {
  /// Creates a [CreateTask] use case.
  ///
  /// [clock] provides the current UTC time. Defaults to [DateTime.now] but
  /// can be overridden for testing.
  const CreateTask({DateTime Function()? clock})
    : _clock = clock ?? _defaultClock;

  final DateTime Function() _clock;

  static DateTime _defaultClock() => DateTime.now().toUtc();

  static const _uuid = Uuid();

  /// Executes the use case.
  ///
  /// Returns a [Task] if valid, or a [ValidationFailure] if validation fails.
  Object call({
    required String title,
    String notes = '',
    Priority priority = Priority.none,
    List<String> tags = const [],
    String? listId,
    DateTime? dueAt,
  }) {
    final trimmedTitle = title.trim();

    if (trimmedTitle.isEmpty) {
      return const RequiredField('Title');
    }
    if (trimmedTitle.length > maxTitleLength) {
      return const MaxLengthExceeded('Title', maxTitleLength);
    }

    final now = _clock();

    return Task(
      id: _uuid.v4(),
      title: trimmedTitle,
      notes: notes,
      priority: priority,
      tags: tags,
      listId: listId,
      dueAt: dueAt,
      createdAt: now,
      updatedAt: now,
    );
  }
}
