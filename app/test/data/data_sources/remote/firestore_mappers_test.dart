import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/data/data_sources/remote/firestore_mappers.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/entities/task_list.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  final now = DateTime.utc(2026, 2, 10, 12, 0);
  final later = DateTime.utc(2026, 2, 10, 14, 0);

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  // ── Helpers ──────────────────────────────────────────────

  /// Writes [data] to a Firestore doc and returns the snapshot.
  Future<DocumentSnapshot<Map<String, dynamic>>> writeAndRead(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await firestore.collection(collection).doc(docId).set(data);
    return firestore.collection(collection).doc(docId).get();
  }

  // ── Task mappers ─────────────────────────────────────────

  group('taskToFirestore', () {
    test('converts all fields to Firestore-compatible map', () {
      final task = Task(
        id: 'task-1',
        title: 'Buy groceries',
        notes: 'Milk, eggs, bread',
        isCompleted: true,
        dueAt: later,
        priority: Priority.high,
        tags: ['shopping', 'urgent'],
        listId: 'list-1',
        createdAt: now,
        updatedAt: later,
      );

      final map = taskToFirestore(task);

      expect(map['title'], 'Buy groceries');
      expect(map['notes'], 'Milk, eggs, bread');
      expect(map['isCompleted'], true);
      expect(map['dueAt'], isA<Timestamp>());
      expect((map['dueAt'] as Timestamp).toDate().toUtc(), later);
      expect(map['priority'], 'high');
      expect(map['tags'], ['shopping', 'urgent']);
      expect(map['listId'], 'list-1');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('sets dueAt to null when absent', () {
      final task = Task(
        id: 'task-1',
        title: 'Test',
        createdAt: now,
        updatedAt: now,
      );

      final map = taskToFirestore(task);

      expect(map['dueAt'], isNull);
    });

    test('sets listId to null when absent', () {
      final task = Task(
        id: 'task-1',
        title: 'Test',
        createdAt: now,
        updatedAt: now,
      );

      final map = taskToFirestore(task);

      expect(map['listId'], isNull);
    });

    test('does not include id in the map (uses doc ID)', () {
      final task = Task(
        id: 'task-1',
        title: 'Test',
        createdAt: now,
        updatedAt: now,
      );

      final map = taskToFirestore(task);

      expect(map.containsKey('id'), isFalse);
    });
  });

  group('taskFromFirestore', () {
    test('converts Firestore document to Task with all fields', () async {
      final doc = await writeAndRead('tasks', 'task-1', {
        'title': 'Buy groceries',
        'notes': 'Milk, eggs, bread',
        'isCompleted': true,
        'dueAt': Timestamp.fromDate(later),
        'priority': 'high',
        'tags': ['shopping', 'urgent'],
        'listId': 'list-1',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(later),
      });

      final task = taskFromFirestore(doc);

      expect(task.id, 'task-1');
      expect(task.title, 'Buy groceries');
      expect(task.notes, 'Milk, eggs, bread');
      expect(task.isCompleted, true);
      expect(task.dueAt, later);
      expect(task.priority, Priority.high);
      expect(task.tags, ['shopping', 'urgent']);
      expect(task.listId, 'list-1');
      expect(task.createdAt, now);
      expect(task.updatedAt, later);
    });

    test('uses defaults for optional fields', () async {
      final doc = await writeAndRead('tasks', 'task-2', {
        'title': 'Minimal',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      final task = taskFromFirestore(doc);

      expect(task.notes, '');
      expect(task.isCompleted, false);
      expect(task.dueAt, isNull);
      expect(task.priority, Priority.none);
      expect(task.tags, isEmpty);
      expect(task.listId, isNull);
    });

    test('parses all priority values', () async {
      for (final priority in Priority.values) {
        final doc = await writeAndRead('tasks', 'task-${priority.name}', {
          'title': 'Priority ${priority.name}',
          'priority': priority.name,
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });

        final task = taskFromFirestore(doc);

        expect(task.priority, priority);
      }
    });

    test('falls back to Priority.none for unknown priority', () async {
      final doc = await writeAndRead('tasks', 'task-bad-priority', {
        'title': 'Bad priority',
        'priority': 'critical',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      final task = taskFromFirestore(doc);

      expect(task.priority, Priority.none);
    });

    test('falls back to Priority.none when priority is null', () async {
      final doc = await writeAndRead('tasks', 'task-null-priority', {
        'title': 'Null priority',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      final task = taskFromFirestore(doc);

      expect(task.priority, Priority.none);
    });
  });

  group('Task roundtrip', () {
    test('Task survives toFirestore → Firestore doc → fromFirestore', () async {
      final original = Task(
        id: 'roundtrip-1',
        title: 'Roundtrip test',
        notes: 'Should survive the trip',
        isCompleted: true,
        dueAt: later,
        priority: Priority.medium,
        tags: ['a', 'b', 'c'],
        listId: 'list-1',
        createdAt: now,
        updatedAt: later,
      );

      final map = taskToFirestore(original);
      final doc = await writeAndRead('tasks', original.id, map);
      final restored = taskFromFirestore(doc);

      expect(restored, original);
    });

    test('Task with minimal fields survives roundtrip', () async {
      final original = Task(
        id: 'roundtrip-2',
        title: 'Minimal roundtrip',
        createdAt: now,
        updatedAt: now,
      );

      final map = taskToFirestore(original);
      final doc = await writeAndRead('tasks', original.id, map);
      final restored = taskFromFirestore(doc);

      expect(restored, original);
    });
  });

  // ── TaskList mappers ─────────────────────────────────────

  group('taskListToFirestore', () {
    test('converts all fields to Firestore-compatible map', () {
      final list = TaskList(
        id: 'list-1',
        name: 'Shopping',
        colorHex: '#FF5722',
        createdAt: now,
        updatedAt: later,
      );

      final map = taskListToFirestore(list);

      expect(map['name'], 'Shopping');
      expect(map['colorHex'], '#FF5722');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
    });

    test('sets colorHex to null when absent', () {
      final list = TaskList(
        id: 'list-1',
        name: 'Test',
        createdAt: now,
        updatedAt: now,
      );

      final map = taskListToFirestore(list);

      expect(map['colorHex'], isNull);
    });

    test('does not include id in the map', () {
      final list = TaskList(
        id: 'list-1',
        name: 'Test',
        createdAt: now,
        updatedAt: now,
      );

      final map = taskListToFirestore(list);

      expect(map.containsKey('id'), isFalse);
    });
  });

  group('taskListFromFirestore', () {
    test('converts Firestore document to TaskList', () async {
      final doc = await writeAndRead('lists', 'list-1', {
        'name': 'Shopping',
        'colorHex': '#FF5722',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(later),
      });

      final list = taskListFromFirestore(doc);

      expect(list.id, 'list-1');
      expect(list.name, 'Shopping');
      expect(list.colorHex, '#FF5722');
      expect(list.createdAt, now);
      expect(list.updatedAt, later);
    });

    test('handles null colorHex', () async {
      final doc = await writeAndRead('lists', 'list-2', {
        'name': 'Work',
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });

      final list = taskListFromFirestore(doc);

      expect(list.colorHex, isNull);
    });
  });

  group('TaskList roundtrip', () {
    test(
      'TaskList survives toFirestore → Firestore doc → fromFirestore',
      () async {
        final original = TaskList(
          id: 'roundtrip-list-1',
          name: 'Roundtrip list',
          colorHex: '#4CAF50',
          createdAt: now,
          updatedAt: later,
        );

        final map = taskListToFirestore(original);
        final doc = await writeAndRead('lists', original.id, map);
        final restored = taskListFromFirestore(doc);

        expect(restored, original);
      },
    );

    test('TaskList with null colorHex survives roundtrip', () async {
      final original = TaskList(
        id: 'roundtrip-list-2',
        name: 'Minimal list',
        createdAt: now,
        updatedAt: now,
      );

      final map = taskListToFirestore(original);
      final doc = await writeAndRead('lists', original.id, map);
      final restored = taskListFromFirestore(doc);

      expect(restored, original);
    });
  });
}
