import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/use_cases/create_task.dart'
    show maxTitleLength;

/// Sentinel value indicating "no change" for nullable fields.
///
/// Needed to distinguish between "set to null" and "don't change" for
/// optional fields like [dueAt] and [listId].
class _Unchanged {
  const _Unchanged();
}

const _unchanged = _Unchanged();

/// Updates an existing [Task] with new field values.
///
/// Only fields that are explicitly provided are changed. Timestamps are
/// bumped automatically. Returns a [Task] on success, or a
/// [ValidationFailure] if validation fails.
class UpdateTask {
  /// Creates an [UpdateTask] use case.
  const UpdateTask({DateTime Function()? clock})
    : _clock = clock ?? _defaultClock;

  final DateTime Function() _clock;

  static DateTime _defaultClock() => DateTime.now().toUtc();

  /// Executes the use case.
  ///
  /// Pass only the fields you want to change. Returns the updated [Task]
  /// or a [ValidationFailure].
  Object call(
    Task task, {
    String? title,
    String? notes,
    Priority? priority,
    Object? dueAt = _unchanged,
    List<String>? tags,
    Object? listId = _unchanged,
  }) {
    // ── Validate title ────────────────────────────────────
    String? trimmedTitle;
    if (title != null) {
      trimmedTitle = title.trim();
      if (trimmedTitle.isEmpty) {
        return const RequiredField('Title');
      }
      if (trimmedTitle.length > maxTitleLength) {
        return const MaxLengthExceeded('Title', maxTitleLength);
      }
    }

    final now = _clock();

    return task.copyWith(
      title: trimmedTitle ?? task.title,
      notes: notes ?? task.notes,
      priority: priority ?? task.priority,
      dueAt: dueAt is _Unchanged ? task.dueAt : dueAt as DateTime?,
      tags: tags ?? task.tags,
      listId: listId is _Unchanged ? task.listId : listId as String?,
      updatedAt: now,
    );
  }
}
