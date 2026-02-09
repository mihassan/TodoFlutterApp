import 'package:todo_flutter_app/domain/entities/task.dart';

/// Toggles the completion status of a [Task].
///
/// If the task is incomplete it becomes completed, and vice versa.
/// The [updatedAt] timestamp is bumped automatically.
class CompleteTask {
  /// Creates a [CompleteTask] use case.
  const CompleteTask({DateTime Function()? clock})
    : _clock = clock ?? _defaultClock;

  final DateTime Function() _clock;

  static DateTime _defaultClock() => DateTime.now().toUtc();

  /// Executes the use case — returns the toggled task.
  Task call(Task task) {
    final now = _clock();
    return task.copyWith(isCompleted: !task.isCompleted, updatedAt: now);
  }
}
