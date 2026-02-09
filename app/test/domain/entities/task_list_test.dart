import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/domain/entities/task_list.dart';

void main() {
  final now = DateTime.utc(2026, 2, 9, 12, 0);

  TaskList createTaskList({
    String id = 'list-1',
    String name = 'Work',
    String? colorHex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskList(
      id: id,
      name: name,
      colorHex: colorHex,
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  group('TaskList entity', () {
    test('creates with required fields and defaults', () {
      final list = createTaskList();

      expect(list.id, 'list-1');
      expect(list.name, 'Work');
      expect(list.colorHex, isNull);
      expect(list.createdAt, now);
      expect(list.updatedAt, now);
    });

    test('creates with optional colorHex', () {
      final list = createTaskList(colorHex: '#FF5733');

      expect(list.colorHex, '#FF5733');
    });

    test('supports value equality', () {
      final list1 = createTaskList();
      final list2 = createTaskList();

      expect(list1, equals(list2));
      expect(list1.hashCode, equals(list2.hashCode));
    });

    test('is not equal when fields differ', () {
      final list1 = createTaskList();
      final list2 = createTaskList(name: 'Shopping');

      expect(list1, isNot(equals(list2)));
    });

    test('copyWith creates a modified copy', () {
      final list = createTaskList();
      final renamed = list.copyWith(name: 'Personal');

      expect(renamed.name, 'Personal');
      expect(renamed.id, list.id);
    });

    test('toString includes class name and fields', () {
      final list = createTaskList();

      expect(list.toString(), contains('TaskList'));
      expect(list.toString(), contains('Work'));
    });
  });
}
