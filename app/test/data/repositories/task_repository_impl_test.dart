import 'package:drift/native.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/data_sources/local/app_database.dart';
import 'package:todo_flutter_app/data/data_sources/local/local_task_data_source.dart';
import 'package:todo_flutter_app/data/data_sources/remote/firestore_task_data_source.dart';
import 'package:todo_flutter_app/data/repositories/task_repository_impl.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/entities/task_list.dart';

void main() {
  late AppDatabase db;
  late LocalTaskDataSource localDataSource;
  late FakeFirebaseFirestore firestore;
  late FirestoreTaskDataSource remoteDataSource;
  late TaskRepositoryImpl repository;

  const uid = 'user-123';
  final now = DateTime.utc(2026, 2, 10, 12, 0);
  final later = DateTime.utc(2026, 2, 10, 14, 0);
  final evenLater = DateTime.utc(2026, 2, 10, 16, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    localDataSource = LocalTaskDataSource(db);
    firestore = FakeFirebaseFirestore();
    remoteDataSource = FirestoreTaskDataSource(firestore: firestore, uid: uid);
    repository = TaskRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );
  });

  tearDown(() async {
    await db.close();
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

  group('TaskRepositoryImpl — task CRUD', () {
    test('getTasks returns empty list initially', () async {
      final (tasks, failure) = await repository.getTasks();

      expect(tasks, isEmpty);
      expect(failure, isNull);
    });

    test('createTask stores task locally and returns it', () async {
      final task = makeTask();

      final (result, failure) = await repository.createTask(task);

      expect(result, task);
      expect(failure, isNull);

      final (tasks, _) = await repository.getTasks();
      expect(tasks, hasLength(1));
      expect(tasks.first.title, task.title);
    });

    test('getTaskById returns task when found', () async {
      final task = makeTask(id: 'find-me');
      await repository.createTask(task);

      final (result, failure) = await repository.getTaskById('find-me');

      expect(result, isNotNull);
      expect(result!.title, task.title);
      expect(failure, isNull);
    });

    test('getTaskById returns null when not found', () async {
      final (result, failure) = await repository.getTaskById('nonexistent');

      expect(result, isNull);
      expect(failure, isNull);
    });

    test('updateTask modifies existing task', () async {
      final task = makeTask(title: 'Before');
      await repository.createTask(task);

      final modified = makeTask(title: 'After', updatedAt: later);
      final (result, failure) = await repository.updateTask(modified);

      expect(result.title, 'After');
      expect(failure, isNull);

      final (retrieved, _) = await repository.getTaskById(task.id);
      expect(retrieved!.title, 'After');
    });

    test('updateTask returns NotFound for nonexistent task', () async {
      final task = makeTask(id: 'nonexistent');

      final (_, failure) = await repository.updateTask(task);

      expect(failure, isA<NotFound>());
    });

    test('deleteTask removes the task', () async {
      final task = makeTask();
      await repository.createTask(task);

      final failure = await repository.deleteTask(task.id);

      expect(failure, isNull);

      final (tasks, _) = await repository.getTasks();
      expect(tasks, isEmpty);
    });

    test('deleteTask returns NotFound for nonexistent task', () async {
      final failure = await repository.deleteTask('nonexistent');

      expect(failure, isA<NotFound>());
    });
  });

  // ── TaskList CRUD ────────────────────────────────────────

  group('TaskRepositoryImpl — task list CRUD', () {
    test('getTaskLists returns empty list initially', () async {
      final (lists, failure) = await repository.getTaskLists();

      expect(lists, isEmpty);
      expect(failure, isNull);
    });

    test('createTaskList stores list locally', () async {
      final list = makeTaskList();

      final (result, failure) = await repository.createTaskList(list);

      expect(result, list);
      expect(failure, isNull);

      final (lists, _) = await repository.getTaskLists();
      expect(lists, hasLength(1));
    });

    test('updateTaskList modifies existing list', () async {
      final list = makeTaskList(name: 'Before');
      await repository.createTaskList(list);

      final modified = makeTaskList(name: 'After', updatedAt: later);
      final (result, failure) = await repository.updateTaskList(modified);

      expect(result.name, 'After');
      expect(failure, isNull);
    });

    test('updateTaskList returns NotFound for nonexistent list', () async {
      final list = makeTaskList(id: 'nonexistent');

      final (_, failure) = await repository.updateTaskList(list);

      expect(failure, isA<NotFound>());
    });

    test('deleteTaskList removes the list', () async {
      final list = makeTaskList();
      await repository.createTaskList(list);

      final failure = await repository.deleteTaskList(list.id);

      expect(failure, isNull);

      final (lists, _) = await repository.getTaskLists();
      expect(lists, isEmpty);
    });

    test('deleteTaskList returns NotFound for nonexistent list', () async {
      final failure = await repository.deleteTaskList('nonexistent');

      expect(failure, isA<NotFound>());
    });
  });

  // ── Sync — push ──────────────────────────────────────────

  group('TaskRepositoryImpl — sync push', () {
    test('sync pushes dirty tasks to Firestore', () async {
      final task = makeTask(id: 'push-task', title: 'Push me');
      await repository.createTask(task);

      final failure = await repository.sync();

      expect(failure, isNull);

      // Verify task exists in Firestore
      final remoteTasks = await remoteDataSource.getTasks();
      expect(remoteTasks, hasLength(1));
      expect(remoteTasks.first.title, 'Push me');
    });

    test('sync pushes dirty task lists to Firestore', () async {
      final list = makeTaskList(id: 'push-list', name: 'Push list');
      await repository.createTaskList(list);

      final failure = await repository.sync();

      expect(failure, isNull);

      final remoteLists = await remoteDataSource.getTaskLists();
      expect(remoteLists, hasLength(1));
      expect(remoteLists.first.name, 'Push list');
    });

    test('sync marks tasks as clean after push', () async {
      final task = makeTask(id: 'clean-after-push');
      await repository.createTask(task);

      await repository.sync();

      // After sync, the task should no longer be dirty
      final dirtyTasks = await localDataSource.getDirtyTasks();
      expect(dirtyTasks, isEmpty);
    });

    test('sync marks task lists as clean after push', () async {
      final list = makeTaskList(id: 'clean-list-after-push');
      await repository.createTaskList(list);

      await repository.sync();

      final dirtyLists = await localDataSource.getDirtyTaskLists();
      expect(dirtyLists, isEmpty);
    });
  });

  // ── Sync — pull ──────────────────────────────────────────

  group('TaskRepositoryImpl — sync pull', () {
    test('sync pulls new remote tasks into local DB', () async {
      // Add a task directly to Firestore (simulating another device)
      final remoteTask = makeTask(id: 'remote-task', title: 'From cloud');
      await remoteDataSource.setTask(remoteTask);

      await repository.sync();

      final (tasks, failure) = await repository.getTasks();
      expect(failure, isNull);
      expect(tasks, hasLength(1));
      expect(tasks.first.title, 'From cloud');
    });

    test('sync pulls new remote task lists into local DB', () async {
      final remoteList = makeTaskList(id: 'remote-list', name: 'Cloud list');
      await remoteDataSource.setTaskList(remoteList);

      await repository.sync();

      final (lists, failure) = await repository.getTaskLists();
      expect(failure, isNull);
      expect(lists, hasLength(1));
      expect(lists.first.name, 'Cloud list');
    });

    test('sync updates local task when remote is newer', () async {
      // Create a task locally, push it, then update it remotely
      final task = makeTask(id: 'update-me', title: 'Original');
      await repository.createTask(task);
      await repository.sync(); // Push to Firestore, mark clean

      // Simulate remote update (another device)
      final remoteUpdated = makeTask(
        id: 'update-me',
        title: 'Updated remotely',
        updatedAt: later,
      );
      await remoteDataSource.setTask(remoteUpdated);

      // Sync again to pull
      await repository.sync();

      final (retrieved, _) = await repository.getTaskById('update-me');
      expect(retrieved!.title, 'Updated remotely');
    });

    test('sync does NOT overwrite local dirty task '
        '(local changes take precedence)', () async {
      // Create and push a task
      final task = makeTask(id: 'conflict', title: 'Original');
      await repository.createTask(task);
      await repository.sync();

      // Now modify the task locally (makes it dirty again)
      final localUpdate = makeTask(
        id: 'conflict',
        title: 'Local edit',
        updatedAt: evenLater,
      );
      await repository.updateTask(localUpdate);

      // Simulate a remote update at an earlier time
      final remoteUpdate = makeTask(
        id: 'conflict',
        title: 'Remote edit',
        updatedAt: later,
      );
      await remoteDataSource.setTask(remoteUpdate);

      // Sync — local dirty task with later updatedAt should win
      await repository.sync();

      final (retrieved, _) = await repository.getTaskById('conflict');
      expect(retrieved!.title, 'Local edit');
    });
  });

  // ── Sync — status ────────────────────────────────────────

  group('TaskRepositoryImpl — sync status', () {
    test('isSyncing emits true then false during sync', () async {
      final emissions = <bool>[];
      final subscription = repository.isSyncing.listen(emissions.add);

      await repository.sync();

      // Give the stream time to deliver events
      await Future<void>.delayed(Duration.zero);

      expect(emissions, [true, false]);

      await subscription.cancel();
    });

    test('syncOnDemand delegates to sync', () async {
      final task = makeTask(id: 'on-demand-task');
      await repository.createTask(task);

      final failure = await repository.syncOnDemand();

      expect(failure, isNull);

      final remoteTasks = await remoteDataSource.getTasks();
      expect(remoteTasks, hasLength(1));
    });

    test('concurrent sync calls are prevented', () async {
      // Start two syncs simultaneously
      final task1 = makeTask(id: 'concurrent-1');
      final task2 = makeTask(id: 'concurrent-2');
      await repository.createTask(task1);
      await repository.createTask(task2);

      // Both should complete without error
      final results = await Future.wait([repository.sync(), repository.sync()]);

      expect(results[0], isNull);
      expect(results[1], isNull);
    });
  });

  // ── Sync — full round trip ───────────────────────────────

  group('TaskRepositoryImpl — sync round trip', () {
    test('push + pull cycle keeps data consistent', () async {
      // Create multiple items locally
      final task1 = makeTask(id: 't-1', title: 'Task 1');
      final task2 = makeTask(id: 't-2', title: 'Task 2');
      final list1 = makeTaskList(id: 'l-1', name: 'List 1');
      await repository.createTask(task1);
      await repository.createTask(task2);
      await repository.createTaskList(list1);

      // Sync pushes everything
      await repository.sync();

      // Verify remote has all data
      final remoteTasks = await remoteDataSource.getTasks();
      final remoteLists = await remoteDataSource.getTaskLists();
      expect(remoteTasks, hasLength(2));
      expect(remoteLists, hasLength(1));

      // Create a new repo instance with fresh local DB but same Firestore
      final db2 = AppDatabase(NativeDatabase.memory());
      final localDs2 = LocalTaskDataSource(db2);
      final repo2 = TaskRepositoryImpl(
        localDataSource: localDs2,
        remoteDataSource: remoteDataSource,
      );

      // Sync pulls everything into the new local DB
      await repo2.sync();

      final (pulledTasks, taskFailure) = await repo2.getTasks();
      final (pulledLists, listFailure) = await repo2.getTaskLists();
      expect(taskFailure, isNull);
      expect(listFailure, isNull);
      expect(pulledTasks, hasLength(2));
      expect(pulledLists, hasLength(1));

      final titles = pulledTasks.map((t) => t.title).toSet();
      expect(titles, {'Task 1', 'Task 2'});
      expect(pulledLists.first.name, 'List 1');

      await db2.close();
    });
  });
}
