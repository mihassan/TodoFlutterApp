import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/data/data_sources/remote/firestore_task_data_source.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/entities/task_list.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreTaskDataSource dataSource;

  const uid = 'user-123';
  final now = DateTime.utc(2026, 2, 10, 12, 0);
  final later = DateTime.utc(2026, 2, 10, 14, 0);

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = FirestoreTaskDataSource(firestore: firestore, uid: uid);
  });

  // ── Helpers ──────────────────────────────────────────────

  Task makeTask({
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

  TaskList makeTaskList({
    String id = 'list-1',
    String name = 'Shopping',
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

  // ── Task CRUD ────────────────────────────────────────────

  group('FirestoreTaskDataSource — tasks', () {
    test('getTasks returns empty list when no tasks exist', () async {
      final tasks = await dataSource.getTasks();

      expect(tasks, isEmpty);
    });

    test('setTask and getTasks round-trips a task', () async {
      final task = makeTask();

      await dataSource.setTask(task);
      final tasks = await dataSource.getTasks();

      expect(tasks, hasLength(1));
      expect(tasks.first, task);
    });

    test('setTask preserves all fields', () async {
      final task = makeTask(
        title: 'Full task',
        notes: 'Detailed notes',
        isCompleted: true,
        dueAt: later,
        priority: Priority.high,
        tags: ['work', 'urgent'],
        listId: 'list-1',
        createdAt: now,
        updatedAt: later,
      );

      await dataSource.setTask(task);
      final result = await dataSource.getTaskById(task.id);

      expect(result, isNotNull);
      expect(result!.id, task.id);
      expect(result.title, task.title);
      expect(result.notes, task.notes);
      expect(result.isCompleted, task.isCompleted);
      expect(result.dueAt, task.dueAt);
      expect(result.priority, task.priority);
      expect(result.tags, task.tags);
      expect(result.listId, task.listId);
      expect(result.createdAt, task.createdAt);
      expect(result.updatedAt, task.updatedAt);
    });

    test('getTaskById returns task when found', () async {
      final task = makeTask(id: 'find-me');
      await dataSource.setTask(task);

      final result = await dataSource.getTaskById('find-me');

      expect(result, task);
    });

    test('getTaskById returns null when not found', () async {
      final result = await dataSource.getTaskById('nonexistent');

      expect(result, isNull);
    });

    test('setTask overwrites existing task (upsert)', () async {
      final original = makeTask(title: 'Original');
      await dataSource.setTask(original);

      final updated = makeTask(title: 'Updated', updatedAt: later);
      await dataSource.setTask(updated);

      final tasks = await dataSource.getTasks();
      expect(tasks, hasLength(1));
      expect(tasks.first.title, 'Updated');
    });

    test('updateTask modifies existing task', () async {
      final task = makeTask(title: 'Before');
      await dataSource.setTask(task);

      final modified = makeTask(title: 'After', updatedAt: later);
      await dataSource.updateTask(modified);

      final result = await dataSource.getTaskById(task.id);
      expect(result!.title, 'After');
    });

    test('deleteTask removes the task', () async {
      final task = makeTask();
      await dataSource.setTask(task);

      await dataSource.deleteTask(task.id);

      final result = await dataSource.getTaskById(task.id);
      expect(result, isNull);
    });

    test('deleteTask on nonexistent id does not throw', () async {
      // Firestore delete on non-existent doc is a no-op
      await expectLater(dataSource.deleteTask('nonexistent'), completes);
    });

    test('multiple tasks can be stored and retrieved', () async {
      final tasks = [
        makeTask(id: 't-1', title: 'Task 1'),
        makeTask(id: 't-2', title: 'Task 2'),
        makeTask(id: 't-3', title: 'Task 3'),
      ];
      for (final task in tasks) {
        await dataSource.setTask(task);
      }

      final result = await dataSource.getTasks();

      expect(result, hasLength(3));
      final titles = result.map((t) => t.title).toSet();
      expect(titles, {'Task 1', 'Task 2', 'Task 3'});
    });

    test('tasks are scoped to the user path', () async {
      await dataSource.setTask(makeTask(id: 'scoped-task'));

      // Verify the doc is at users/{uid}/tasks/{taskId}
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc('scoped-task')
          .get();
      expect(doc.exists, isTrue);
    });
  });

  // ── TaskList CRUD ────────────────────────────────────────

  group('FirestoreTaskDataSource — task lists', () {
    test('getTaskLists returns empty list when none exist', () async {
      final lists = await dataSource.getTaskLists();

      expect(lists, isEmpty);
    });

    test('setTaskList and getTaskLists round-trips a list', () async {
      final list = makeTaskList();

      await dataSource.setTaskList(list);
      final lists = await dataSource.getTaskLists();

      expect(lists, hasLength(1));
      expect(lists.first, list);
    });

    test('setTaskList preserves all fields', () async {
      final list = makeTaskList(
        name: 'Work Tasks',
        colorHex: '#4CAF50',
        createdAt: now,
        updatedAt: later,
      );

      await dataSource.setTaskList(list);
      final result = await dataSource.getTaskListById(list.id);

      expect(result, isNotNull);
      expect(result!.id, list.id);
      expect(result.name, list.name);
      expect(result.colorHex, list.colorHex);
      expect(result.createdAt, list.createdAt);
      expect(result.updatedAt, list.updatedAt);
    });

    test('getTaskListById returns list when found', () async {
      final list = makeTaskList(id: 'find-list');
      await dataSource.setTaskList(list);

      final result = await dataSource.getTaskListById('find-list');

      expect(result, list);
    });

    test('getTaskListById returns null when not found', () async {
      final result = await dataSource.getTaskListById('nonexistent');

      expect(result, isNull);
    });

    test('setTaskList overwrites existing list (upsert)', () async {
      final original = makeTaskList(name: 'Original');
      await dataSource.setTaskList(original);

      final updated = makeTaskList(name: 'Updated', updatedAt: later);
      await dataSource.setTaskList(updated);

      final lists = await dataSource.getTaskLists();
      expect(lists, hasLength(1));
      expect(lists.first.name, 'Updated');
    });

    test('updateTaskList modifies existing list', () async {
      final list = makeTaskList(name: 'Before');
      await dataSource.setTaskList(list);

      final modified = makeTaskList(name: 'After', updatedAt: later);
      await dataSource.updateTaskList(modified);

      final result = await dataSource.getTaskListById(list.id);
      expect(result!.name, 'After');
    });

    test('deleteTaskList removes the list', () async {
      final list = makeTaskList();
      await dataSource.setTaskList(list);

      await dataSource.deleteTaskList(list.id);

      final result = await dataSource.getTaskListById(list.id);
      expect(result, isNull);
    });

    test('multiple lists can be stored and retrieved', () async {
      final lists = [
        makeTaskList(id: 'l-1', name: 'List 1'),
        makeTaskList(id: 'l-2', name: 'List 2'),
        makeTaskList(id: 'l-3', name: 'List 3'),
      ];
      for (final list in lists) {
        await dataSource.setTaskList(list);
      }

      final result = await dataSource.getTaskLists();

      expect(result, hasLength(3));
      final names = result.map((l) => l.name).toSet();
      expect(names, {'List 1', 'List 2', 'List 3'});
    });

    test('lists are scoped to the user path', () async {
      await dataSource.setTaskList(makeTaskList(id: 'scoped-list'));

      // Verify the doc is at users/{uid}/lists/{listId}
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('lists')
          .doc('scoped-list')
          .get();
      expect(doc.exists, isTrue);
    });
  });

  // ── User isolation ───────────────────────────────────────

  group('FirestoreTaskDataSource — user isolation', () {
    test('different UIDs have separate task collections', () async {
      final dsUser1 = FirestoreTaskDataSource(
        firestore: firestore,
        uid: 'user-1',
      );
      final dsUser2 = FirestoreTaskDataSource(
        firestore: firestore,
        uid: 'user-2',
      );

      await dsUser1.setTask(makeTask(id: 'shared-id', title: 'User 1 task'));
      await dsUser2.setTask(makeTask(id: 'shared-id', title: 'User 2 task'));

      final user1Tasks = await dsUser1.getTasks();
      final user2Tasks = await dsUser2.getTasks();

      expect(user1Tasks, hasLength(1));
      expect(user1Tasks.first.title, 'User 1 task');
      expect(user2Tasks, hasLength(1));
      expect(user2Tasks.first.title, 'User 2 task');
    });

    test('different UIDs have separate list collections', () async {
      final dsUser1 = FirestoreTaskDataSource(
        firestore: firestore,
        uid: 'user-1',
      );
      final dsUser2 = FirestoreTaskDataSource(
        firestore: firestore,
        uid: 'user-2',
      );

      await dsUser1.setTaskList(
        makeTaskList(id: 'shared-id', name: 'User 1 list'),
      );
      await dsUser2.setTaskList(
        makeTaskList(id: 'shared-id', name: 'User 2 list'),
      );

      final user1Lists = await dsUser1.getTaskLists();
      final user2Lists = await dsUser2.getTaskLists();

      expect(user1Lists, hasLength(1));
      expect(user1Lists.first.name, 'User 1 list');
      expect(user2Lists, hasLength(1));
      expect(user2Lists.first.name, 'User 2 list');
    });
  });
}
