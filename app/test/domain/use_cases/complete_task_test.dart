import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/use_cases/complete_task.dart';

void main() {
  final now = DateTime.utc(2026, 2, 9, 12, 0);
  final later = DateTime.utc(2026, 2, 9, 14, 0);

  Task sampleTask({bool isCompleted = false}) => Task(
    id: 'task-1',
    title: 'Buy groceries',
    priority: Priority.medium,
    isCompleted: isCompleted,
    createdAt: now,
    updatedAt: now,
  );

  group('CompleteTask', () {
    late CompleteTask completeTask;

    setUp(() {
      completeTask = CompleteTask(clock: () => later);
    });

    test('marks an incomplete task as completed', () {
      final task = sampleTask();
      final result = completeTask(task);

      expect(result.isCompleted, true);
      expect(result.updatedAt, later);
    });

    test('preserves all other fields when completing', () {
      final task = sampleTask();
      final result = completeTask(task);

      expect(result.id, 'task-1');
      expect(result.title, 'Buy groceries');
      expect(result.priority, Priority.medium);
      expect(result.createdAt, now);
    });

    test('marks a completed task as incomplete (toggle)', () {
      final task = sampleTask(isCompleted: true);
      final result = completeTask(task);

      expect(result.isCompleted, false);
      expect(result.updatedAt, later);
    });
  });
}
