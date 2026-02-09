import 'package:todo_flutter_app/domain/entities/task.dart';

/// Available task filters for the task list UI.
enum TaskFilter {
  /// All incomplete tasks regardless of due date.
  inbox,

  /// Incomplete tasks due today or overdue.
  today,

  /// Incomplete tasks due in the future (after today).
  upcoming,

  /// Tasks that have been marked as completed.
  completed,
}

/// Filters a list of [Task]s according to a [TaskFilter].
///
/// Pure function — no side effects. Returns a new filtered list.
class FilterTasks {
  /// Creates a [FilterTasks] use case.
  ///
  /// [clock] provides the current date for "today" / "overdue" calculations.
  const FilterTasks({DateTime Function()? clock})
    : _clock = clock ?? _defaultClock;

  final DateTime Function() _clock;

  static DateTime _defaultClock() => DateTime.now().toUtc();

  /// Executes the filter.
  List<Task> call(List<Task> tasks, TaskFilter filter) {
    final now = _clock();
    final todayStart = DateTime.utc(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    return switch (filter) {
      TaskFilter.inbox => tasks.where((t) => !t.isCompleted).toList(),
      TaskFilter.today =>
        tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  t.dueAt != null &&
                  t.dueAt!.isBefore(tomorrowStart),
            )
            .toList(),
      TaskFilter.upcoming =>
        tasks
            .where(
              (t) =>
                  !t.isCompleted &&
                  t.dueAt != null &&
                  !t.dueAt!.isBefore(tomorrowStart),
            )
            .toList(),
      TaskFilter.completed => tasks.where((t) => t.isCompleted).toList(),
    };
  }
}
