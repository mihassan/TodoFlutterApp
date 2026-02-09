import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/use_cases/create_task.dart';

void main() {
  final now = DateTime.utc(2026, 2, 9, 12, 0);

  group('CreateTask', () {
    late CreateTask createTask;

    setUp(() {
      createTask = CreateTask(clock: () => now);
    });

    test('creates a task with title and generated id', () {
      final result = createTask(title: 'Buy groceries');

      expect(result, isA<Task>());
      final task = result as Task;
      expect(task.id, isNotEmpty);
      expect(task.title, 'Buy groceries');
      expect(task.notes, '');
      expect(task.isCompleted, false);
      expect(task.priority, Priority.none);
      expect(task.tags, isEmpty);
      expect(task.listId, isNull);
      expect(task.dueAt, isNull);
      expect(task.createdAt, now);
      expect(task.updatedAt, now);
    });

    test('creates a task with all optional fields', () {
      final dueDate = DateTime.utc(2026, 2, 15);
      final result = createTask(
        title: 'Finish report',
        notes: 'Q4 financial report',
        priority: Priority.high,
        tags: ['work', 'urgent'],
        listId: 'list-1',
        dueAt: dueDate,
      );

      final task = result as Task;
      expect(task.title, 'Finish report');
      expect(task.notes, 'Q4 financial report');
      expect(task.priority, Priority.high);
      expect(task.tags, ['work', 'urgent']);
      expect(task.listId, 'list-1');
      expect(task.dueAt, dueDate);
    });

    test('generates unique ids for each task', () {
      final result1 = createTask(title: 'Task 1');
      final result2 = createTask(title: 'Task 2');

      final task1 = result1 as Task;
      final task2 = result2 as Task;
      expect(task1.id, isNot(equals(task2.id)));
    });

    test('returns ValidationFailure for empty title', () {
      final result = createTask(title: '');

      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).message, contains('Title'));
    });

    test('returns ValidationFailure for whitespace-only title', () {
      final result = createTask(title: '   ');

      expect(result, isA<ValidationFailure>());
    });

    test('returns ValidationFailure for title exceeding max length', () {
      final longTitle = 'a' * 201;
      final result = createTask(title: longTitle);

      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).message, contains('200'));
    });

    test('trims whitespace from title', () {
      final result = createTask(title: '  Buy groceries  ');

      final task = result as Task;
      expect(task.title, 'Buy groceries');
    });
  });
}
