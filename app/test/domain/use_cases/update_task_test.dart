import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/use_cases/update_task.dart';

void main() {
  final now = DateTime.utc(2026, 2, 9, 12, 0);
  final later = DateTime.utc(2026, 2, 9, 14, 0);

  Task sampleTask() => Task(
    id: 'task-1',
    title: 'Buy groceries',
    createdAt: now,
    updatedAt: now,
  );

  group('UpdateTask', () {
    late UpdateTask updateTask;

    setUp(() {
      updateTask = UpdateTask(clock: () => later);
    });

    test('updates title and bumps updatedAt', () {
      final result = updateTask(sampleTask(), title: 'Buy vegetables');

      final task = result as Task;
      expect(task.title, 'Buy vegetables');
      expect(task.updatedAt, later);
      expect(task.createdAt, now); // unchanged
    });

    test('updates notes', () {
      final result = updateTask(sampleTask(), notes: 'Organic only');

      final task = result as Task;
      expect(task.notes, 'Organic only');
      expect(task.updatedAt, later);
    });

    test('updates priority', () {
      final result = updateTask(sampleTask(), priority: Priority.high);

      final task = result as Task;
      expect(task.priority, Priority.high);
    });

    test('updates dueAt', () {
      final dueDate = DateTime.utc(2026, 3, 1);
      final result = updateTask(sampleTask(), dueAt: dueDate);

      final task = result as Task;
      expect(task.dueAt, dueDate);
    });

    test('updates tags', () {
      final result = updateTask(sampleTask(), tags: ['shopping']);

      final task = result as Task;
      expect(task.tags, ['shopping']);
    });

    test('updates listId', () {
      final result = updateTask(sampleTask(), listId: 'list-2');

      final task = result as Task;
      expect(task.listId, 'list-2');
    });

    test('updates multiple fields at once', () {
      final result = updateTask(
        sampleTask(),
        title: 'Updated',
        notes: 'New notes',
        priority: Priority.low,
      );

      final task = result as Task;
      expect(task.title, 'Updated');
      expect(task.notes, 'New notes');
      expect(task.priority, Priority.low);
      expect(task.updatedAt, later);
    });

    test('returns ValidationFailure for empty title', () {
      final result = updateTask(sampleTask(), title: '');

      expect(result, isA<ValidationFailure>());
    });

    test('returns ValidationFailure for title exceeding max length', () {
      final longTitle = 'a' * 201;
      final result = updateTask(sampleTask(), title: longTitle);

      expect(result, isA<ValidationFailure>());
    });

    test('trims whitespace from title', () {
      final result = updateTask(sampleTask(), title: '  Updated title  ');

      final task = result as Task;
      expect(task.title, 'Updated title');
    });

    test('preserves id and createdAt', () {
      final result = updateTask(sampleTask(), title: 'Updated');

      final task = result as Task;
      expect(task.id, 'task-1');
      expect(task.createdAt, now);
    });
  });
}
