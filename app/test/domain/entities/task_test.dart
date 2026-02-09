import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';

void main() {
  final now = DateTime.utc(2026, 2, 9, 12, 0);

  Task createTask({
    String id = 'task-1',
    String title = 'Buy groceries',
    String notes = '',
    bool isCompleted = false,
    DateTime? dueAt,
    Priority priority = Priority.none,
    List<String> tags = const [],
    String? listId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title,
      notes: notes,
      isCompleted: isCompleted,
      dueAt: dueAt,
      priority: priority,
      tags: tags,
      listId: listId,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  group('Task entity', () {
    test('creates with required fields and defaults', () {
      final task = createTask();

      expect(task.id, 'task-1');
      expect(task.title, 'Buy groceries');
      expect(task.notes, '');
      expect(task.isCompleted, false);
      expect(task.dueAt, isNull);
      expect(task.priority, Priority.none);
      expect(task.tags, isEmpty);
      expect(task.listId, isNull);
      expect(task.createdAt, now);
      expect(task.updatedAt, now);
    });

    test('creates with all fields specified', () {
      final dueDate = DateTime.utc(2026, 2, 15);
      final task = createTask(
        notes: 'Milk, eggs, bread',
        isCompleted: true,
        dueAt: dueDate,
        priority: Priority.high,
        tags: ['shopping', 'urgent'],
        listId: 'list-1',
      );

      expect(task.notes, 'Milk, eggs, bread');
      expect(task.isCompleted, true);
      expect(task.dueAt, dueDate);
      expect(task.priority, Priority.high);
      expect(task.tags, ['shopping', 'urgent']);
      expect(task.listId, 'list-1');
    });

    test('supports value equality', () {
      final task1 = createTask();
      final task2 = createTask();

      expect(task1, equals(task2));
      expect(task1.hashCode, equals(task2.hashCode));
    });

    test('is not equal when fields differ', () {
      final task1 = createTask();
      final task2 = createTask(title: 'Different title');

      expect(task1, isNot(equals(task2)));
    });

    test('copyWith creates a modified copy', () {
      final task = createTask();
      final completed = task.copyWith(isCompleted: true);

      expect(completed.isCompleted, true);
      expect(completed.id, task.id);
      expect(completed.title, task.title);
    });

    test('copyWith preserves unmodified fields', () {
      final task = createTask(
        notes: 'original notes',
        priority: Priority.medium,
        tags: ['tag1'],
      );
      final updated = task.copyWith(title: 'Updated title');

      expect(updated.title, 'Updated title');
      expect(updated.notes, 'original notes');
      expect(updated.priority, Priority.medium);
      expect(updated.tags, ['tag1']);
    });

    test('toString includes class name and fields', () {
      final task = createTask();

      expect(task.toString(), contains('Task'));
      expect(task.toString(), contains('Buy groceries'));
    });
  });

  group('Priority enum', () {
    test('has four values in order', () {
      expect(Priority.values.length, 4);
      expect(Priority.values[0], Priority.none);
      expect(Priority.values[1], Priority.low);
      expect(Priority.values[2], Priority.medium);
      expect(Priority.values[3], Priority.high);
    });

    test('index reflects ordering', () {
      expect(Priority.none.index, lessThan(Priority.low.index));
      expect(Priority.low.index, lessThan(Priority.medium.index));
      expect(Priority.medium.index, lessThan(Priority.high.index));
    });
  });
}
