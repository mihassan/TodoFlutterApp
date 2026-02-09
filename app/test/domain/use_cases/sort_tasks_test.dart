import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/use_cases/sort_tasks.dart';

void main() {
  final now = DateTime.utc(2026, 2, 9, 12, 0);

  Task makeTask({
    String id = 'task-1',
    String title = 'Task',
    DateTime? dueAt,
    Priority priority = Priority.none,
    DateTime? createdAt,
  }) {
    return Task(
      id: id,
      title: title,
      dueAt: dueAt,
      priority: priority,
      createdAt: createdAt ?? now,
      updatedAt: now,
    );
  }

  group('SortTasks', () {
    late SortTasks sortTasks;

    setUp(() {
      sortTasks = const SortTasks();
    });

    group('by due date', () {
      test('sorts tasks with due dates earliest first', () {
        final tasks = [
          makeTask(id: '1', dueAt: DateTime.utc(2026, 2, 15)),
          makeTask(id: '2', dueAt: DateTime.utc(2026, 2, 10)),
          makeTask(id: '3', dueAt: DateTime.utc(2026, 2, 20)),
        ];

        final result = sortTasks(tasks, TaskSortField.dueDate);

        expect(result.map((t) => t.id), ['2', '1', '3']);
      });

      test('puts tasks without due date at the end', () {
        final tasks = [
          makeTask(id: '1'),
          makeTask(id: '2', dueAt: DateTime.utc(2026, 2, 10)),
          makeTask(id: '3'),
        ];

        final result = sortTasks(tasks, TaskSortField.dueDate);

        expect(result.first.id, '2');
        expect(result.last.dueAt, isNull);
      });

      test('sorts descending when specified', () {
        final tasks = [
          makeTask(id: '1', dueAt: DateTime.utc(2026, 2, 10)),
          makeTask(id: '2', dueAt: DateTime.utc(2026, 2, 15)),
        ];

        final result = sortTasks(
          tasks,
          TaskSortField.dueDate,
          ascending: false,
        );

        expect(result.map((t) => t.id), ['2', '1']);
      });
    });

    group('by priority', () {
      test('sorts highest priority first by default', () {
        final tasks = [
          makeTask(id: '1', priority: Priority.low),
          makeTask(id: '2', priority: Priority.high),
          makeTask(id: '3', priority: Priority.medium),
          makeTask(id: '4', priority: Priority.none),
        ];

        final result = sortTasks(tasks, TaskSortField.priority);

        expect(result.map((t) => t.id), ['2', '3', '1', '4']);
      });

      test('sorts lowest priority first when ascending', () {
        final tasks = [
          makeTask(id: '1', priority: Priority.high),
          makeTask(id: '2', priority: Priority.low),
        ];

        final result = sortTasks(
          tasks,
          TaskSortField.priority,
          ascending: true,
        );

        expect(result.map((t) => t.id), ['2', '1']);
      });
    });

    group('by title', () {
      test('sorts alphabetically ascending', () {
        final tasks = [
          makeTask(id: '1', title: 'Charlie'),
          makeTask(id: '2', title: 'Alpha'),
          makeTask(id: '3', title: 'Bravo'),
        ];

        final result = sortTasks(tasks, TaskSortField.title);

        expect(result.map((t) => t.id), ['2', '3', '1']);
      });

      test('is case-insensitive', () {
        final tasks = [
          makeTask(id: '1', title: 'banana'),
          makeTask(id: '2', title: 'Apple'),
        ];

        final result = sortTasks(tasks, TaskSortField.title);

        expect(result.map((t) => t.id), ['2', '1']);
      });
    });

    group('by created date', () {
      test('sorts newest first by default', () {
        final tasks = [
          makeTask(id: '1', createdAt: DateTime.utc(2026, 2, 8)),
          makeTask(id: '2', createdAt: DateTime.utc(2026, 2, 10)),
          makeTask(id: '3', createdAt: DateTime.utc(2026, 2, 9)),
        ];

        final result = sortTasks(tasks, TaskSortField.createdAt);

        expect(result.map((t) => t.id), ['2', '3', '1']);
      });

      test('sorts oldest first when ascending', () {
        final tasks = [
          makeTask(id: '1', createdAt: DateTime.utc(2026, 2, 10)),
          makeTask(id: '2', createdAt: DateTime.utc(2026, 2, 8)),
        ];

        final result = sortTasks(
          tasks,
          TaskSortField.createdAt,
          ascending: true,
        );

        expect(result.map((t) => t.id), ['2', '1']);
      });
    });

    test('does not mutate original list', () {
      final tasks = [
        makeTask(id: '1', title: 'B'),
        makeTask(id: '2', title: 'A'),
      ];

      final result = sortTasks(tasks, TaskSortField.title);

      expect(tasks.first.id, '1'); // original unchanged
      expect(result.first.id, '2'); // sorted
    });

    test('returns empty list for empty input', () {
      final result = sortTasks([], TaskSortField.title);

      expect(result, isEmpty);
    });
  });
}
