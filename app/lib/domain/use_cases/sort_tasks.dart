import 'package:todo_flutter_app/domain/entities/task.dart';

/// Available fields for sorting tasks.
enum TaskSortField {
  /// Sort by due date (earliest first by default).
  dueDate,

  /// Sort by priority (highest first by default).
  priority,

  /// Sort alphabetically by title (A-Z by default).
  title,

  /// Sort by creation date (newest first by default).
  createdAt,
}

/// Sorts a list of [Task]s by a given field.
///
/// Returns a new sorted list — the original is not mutated.
class SortTasks {
  const SortTasks();

  /// Executes the sort.
  ///
  /// Default sort direction varies by field:
  /// - [TaskSortField.dueDate]: ascending (earliest first), nulls last
  /// - [TaskSortField.priority]: descending (highest first)
  /// - [TaskSortField.title]: ascending (A-Z)
  /// - [TaskSortField.createdAt]: descending (newest first)
  ///
  /// Override with [ascending] to force a direction.
  List<Task> call(List<Task> tasks, TaskSortField field, {bool? ascending}) {
    if (tasks.isEmpty) return [];

    final sorted = List<Task>.from(tasks);

    final isAscending = ascending ?? _defaultAscending(field);

    sorted.sort((a, b) {
      final cmp = _compare(a, b, field);
      return isAscending ? cmp : -cmp;
    });

    return sorted;
  }

  bool _defaultAscending(TaskSortField field) {
    return switch (field) {
      TaskSortField.dueDate => true,
      TaskSortField.priority => false,
      TaskSortField.title => true,
      TaskSortField.createdAt => false,
    };
  }

  int _compare(Task a, Task b, TaskSortField field) {
    return switch (field) {
      TaskSortField.dueDate => _compareDueDate(a, b),
      TaskSortField.priority => a.priority.index.compareTo(b.priority.index),
      TaskSortField.title => a.title.toLowerCase().compareTo(
        b.title.toLowerCase(),
      ),
      TaskSortField.createdAt => a.createdAt.compareTo(b.createdAt),
    };
  }

  /// Compares due dates, putting nulls at the end.
  int _compareDueDate(Task a, Task b) {
    if (a.dueAt == null && b.dueAt == null) return 0;
    if (a.dueAt == null) return 1; // a goes after b
    if (b.dueAt == null) return -1; // b goes after a
    return a.dueAt!.compareTo(b.dueAt!);
  }
}
