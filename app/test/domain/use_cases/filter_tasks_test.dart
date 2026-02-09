import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/use_cases/filter_tasks.dart';

void main() {
  final now = DateTime.utc(2026, 2, 9, 12, 0);

  // ── Helpers ─────────────────────────────────────────────

  Task makeTask({
    String id = 'task-1',
    String title = 'Task',
    bool isCompleted = false,
    DateTime? dueAt,
    Priority priority = Priority.none,
    String? listId,
  }) {
    return Task(
      id: id,
      title: title,
      isCompleted: isCompleted,
      dueAt: dueAt,
      priority: priority,
      listId: listId,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ── Test data ───────────────────────────────────────────

  final today = DateTime.utc(2026, 2, 9);
  final tomorrow = DateTime.utc(2026, 2, 10);
  final nextWeek = DateTime.utc(2026, 2, 16);
  final yesterday = DateTime.utc(2026, 2, 8);

  late List<Task> tasks;

  setUp(() {
    tasks = [
      makeTask(id: '1', title: 'Overdue', dueAt: yesterday),
      makeTask(id: '2', title: 'Today', dueAt: today),
      makeTask(id: '3', title: 'Tomorrow', dueAt: tomorrow),
      makeTask(id: '4', title: 'Next week', dueAt: nextWeek),
      makeTask(id: '5', title: 'No due date'),
      makeTask(id: '6', title: 'Completed', isCompleted: true),
      makeTask(
        id: '7',
        title: 'Completed with due',
        isCompleted: true,
        dueAt: today,
      ),
    ];
  });

  group('FilterTasks', () {
    late FilterTasks filterTasks;

    setUp(() {
      filterTasks = FilterTasks(clock: () => today);
    });

    test('inbox returns all incomplete tasks', () {
      final result = filterTasks(tasks, TaskFilter.inbox);

      expect(result.length, 5);
      expect(result.every((t) => !t.isCompleted), true);
    });

    test('today returns incomplete tasks due today or overdue', () {
      final result = filterTasks(tasks, TaskFilter.today);

      expect(result.length, 2);
      expect(result.map((t) => t.id), containsAll(['1', '2']));
    });

    test('upcoming returns incomplete tasks due in the future', () {
      final result = filterTasks(tasks, TaskFilter.upcoming);

      expect(result.length, 2);
      expect(result.map((t) => t.id), containsAll(['3', '4']));
    });

    test('completed returns only completed tasks', () {
      final result = filterTasks(tasks, TaskFilter.completed);

      expect(result.length, 2);
      expect(result.every((t) => t.isCompleted), true);
    });

    test('inbox excludes completed tasks', () {
      final result = filterTasks(tasks, TaskFilter.inbox);

      expect(result.any((t) => t.isCompleted), false);
    });

    test('today excludes future tasks', () {
      final result = filterTasks(tasks, TaskFilter.today);

      expect(result.any((t) => t.id == '3'), false);
      expect(result.any((t) => t.id == '4'), false);
    });

    test('upcoming excludes tasks with no due date', () {
      final result = filterTasks(tasks, TaskFilter.upcoming);

      expect(result.any((t) => t.id == '5'), false);
    });

    test('returns empty list when no tasks match', () {
      final allCompleted = [makeTask(id: '1', isCompleted: true)];

      final result = filterTasks(allCompleted, TaskFilter.inbox);

      expect(result, isEmpty);
    });
  });
}
