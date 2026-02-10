import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/data_sources/local/app_database.dart';
import 'package:todo_flutter_app/data/data_sources/local/local_sync_queue_data_source.dart';
import 'package:todo_flutter_app/data/data_sources/local/local_task_data_source.dart';
import 'package:todo_flutter_app/data/data_sources/remote/firestore_task_data_source.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/entities/task_list.dart';
import 'package:todo_flutter_app/domain/repositories/task_repository.dart';

/// Production implementation of [TaskRepository].
///
/// Follows an offline-first pattern:
/// - Reads come from the local Drift database
/// - Writes go to local first (marked dirty), then synced to Firestore
/// - [sync] pushes dirty records to Firestore and pulls remote changes
///
/// The full sync engine (push queue, pull reconciliation, retry) is
/// implemented in Phase 9. This class provides the local CRUD operations
/// and a basic push/pull sync skeleton.
class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({
    required LocalTaskDataSource localDataSource,
    required FirestoreTaskDataSource remoteDataSource,
    required LocalSyncQueueDataSource syncQueueDataSource,
  }) : _local = localDataSource,
       _remote = remoteDataSource,
       _syncQueue = syncQueueDataSource;

  final LocalTaskDataSource _local;
  final FirestoreTaskDataSource _remote;
  final LocalSyncQueueDataSource _syncQueue;

  final _syncController = StreamController<bool>.broadcast();
  bool _isSyncingNow = false;

  // ── Task CRUD (local-first) ────────────────────────────

  @override
  Future<(List<Task>, StorageFailure?)> getTasks() async {
    try {
      final tasks = await _local.getTasks();
      return (tasks, null);
    } on Exception catch (e) {
      return (const <Task>[], DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<(Task?, StorageFailure?)> getTaskById(String taskId) async {
    try {
      final task = await _local.getTaskById(taskId);
      return (task, null);
    } on Exception catch (e) {
      return (null, DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<(List<TaskList>, StorageFailure?)> getTaskLists() async {
    try {
      final lists = await _local.getTaskLists();
      return (lists, null);
    } on Exception catch (e) {
      return (const <TaskList>[], DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<(Task, StorageFailure?)> createTask(Task task) async {
    try {
      await _local.insertTask(task);
      await _syncQueue.enqueue(
        entityType: 'task',
        entityId: task.id,
        operation: 'create',
      );
      return (task, null);
    } on Exception catch (e) {
      return (task, DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<(Task, StorageFailure?)> updateTask(Task task) async {
    try {
      final updated = await _local.updateTask(task);
      if (!updated) {
        return (task, const NotFound('Task not found.'));
      }
      await _syncQueue.enqueue(
        entityType: 'task',
        entityId: task.id,
        operation: 'update',
      );
      return (task, null);
    } on Exception catch (e) {
      return (task, DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<StorageFailure?> deleteTask(String taskId) async {
    try {
      final deleted = await _local.deleteTask(taskId);
      if (!deleted) {
        return const NotFound('Task not found.');
      }
      await _syncQueue.enqueue(
        entityType: 'task',
        entityId: taskId,
        operation: 'delete',
      );
      return null;
    } on Exception catch (e) {
      return DatabaseFailure(e.toString());
    }
  }

  @override
  Future<(TaskList, StorageFailure?)> createTaskList(TaskList list) async {
    try {
      await _local.insertTaskList(list);
      await _syncQueue.enqueue(
        entityType: 'taskList',
        entityId: list.id,
        operation: 'create',
      );
      return (list, null);
    } on Exception catch (e) {
      return (list, DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<(TaskList, StorageFailure?)> updateTaskList(TaskList list) async {
    try {
      final updated = await _local.updateTaskList(list);
      if (!updated) {
        return (list, const NotFound('Task list not found.'));
      }
      await _syncQueue.enqueue(
        entityType: 'taskList',
        entityId: list.id,
        operation: 'update',
      );
      return (list, null);
    } on Exception catch (e) {
      return (list, DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<StorageFailure?> deleteTaskList(String listId) async {
    try {
      final deleted = await _local.deleteTaskList(listId);
      if (!deleted) {
        return const NotFound('Task list not found.');
      }
      await _syncQueue.enqueue(
        entityType: 'taskList',
        entityId: listId,
        operation: 'delete',
      );
      return null;
    } on Exception catch (e) {
      return DatabaseFailure(e.toString());
    }
  }

  // ── Sync ───────────────────────────────────────────────

  @override
  Future<NetworkFailure?> sync() async {
    if (_isSyncingNow) return null;

    _isSyncingNow = true;
    _syncController.add(true);

    try {
      // Phase 1: Push dirty tasks to Firestore
      await _processSyncQueue();
      await _pushDirtyTasks();
      await _pushDirtyTaskLists();

      // Phase 2: Pull remote changes into local DB
      await _pullRemoteTasks();
      await _pullRemoteTaskLists();

      return null;
    } on FirebaseException catch (e) {
      return ServerError('Sync failed: ${e.message}');
    } on Exception catch (e) {
      return ServerError('Sync failed: $e');
    } finally {
      _isSyncingNow = false;
      _syncController.add(false);
    }
  }

  @override
  Future<NetworkFailure?> syncOnDemand() => sync();

  @override
  Stream<bool> get isSyncing => _syncController.stream;

  // ── Push helpers ───────────────────────────────────────

  Future<void> _pushDirtyTasks() async {
    final dirtyTasks = await _local.getDirtyTasks();
    for (final task in dirtyTasks) {
      await _remote.setTask(task);
      await _local.markTaskSynced(task.id);
    }
  }

  Future<void> _pushDirtyTaskLists() async {
    final dirtyLists = await _local.getDirtyTaskLists();
    for (final list in dirtyLists) {
      await _remote.setTaskList(list);
      await _local.markTaskListSynced(list.id);
    }
  }

  // ── Pull helpers ───────────────────────────────────────

  Future<void> _pullRemoteTasks() async {
    final remoteTasks = await _remote.getTasks();
    for (final remoteTask in remoteTasks) {
      final localTask = await _local.getTaskById(remoteTask.id);
      if (localTask == null) {
        // New remote task — insert locally
        await _local.insertTask(remoteTask);
        await _local.markTaskSynced(remoteTask.id);
      } else if (!_isLocalDirty(localTask, remoteTask)) {
        // Remote is newer (or equal) and local isn't dirty — update
        await _local.updateTask(remoteTask);
        await _local.markTaskSynced(remoteTask.id);
      }
      // If local is dirty, skip — local changes take precedence (push first)
    }
  }

  Future<void> _pullRemoteTaskLists() async {
    final remoteLists = await _remote.getTaskLists();
    for (final remoteList in remoteLists) {
      final localList = await _local.getTaskListById(remoteList.id);
      if (localList == null) {
        // New remote list — insert locally
        await _local.insertTaskList(remoteList);
        await _local.markTaskListSynced(remoteList.id);
      } else if (!_isLocalListDirty(localList, remoteList)) {
        // Remote is newer (or equal) and local isn't dirty — update
        await _local.updateTaskList(remoteList);
        await _local.markTaskListSynced(remoteList.id);
      }
    }
  }

  // ── Sync queue processing ───────────────────────────────

  Future<void> _processSyncQueue() async {
    final entries = await _syncQueue.getPendingEntries();
    for (final entry in entries) {
      try {
        await _applySyncQueueEntry(entry);
        await _syncQueue.remove(entry.id);
      } on Exception {
        await _syncQueue.incrementRetryCount(entry.id);
        rethrow;
      }
    }
  }

  Future<void> _applySyncQueueEntry(SyncQueueData entry) async {
    switch (entry.entityType) {
      case 'task':
        return _applyTaskQueueEntry(entry);
      case 'taskList':
        return _applyTaskListQueueEntry(entry);
      default:
        throw StateError('Unknown sync entity type: ${entry.entityType}');
    }
  }

  Future<void> _applyTaskQueueEntry(SyncQueueData entry) async {
    if (entry.operation == 'delete') {
      await _remote.deleteTask(entry.entityId);
      return;
    }

    final task = await _local.getTaskById(entry.entityId);
    if (task == null) return;

    await _remote.setTask(task);
    await _local.markTaskSynced(task.id);
  }

  Future<void> _applyTaskListQueueEntry(SyncQueueData entry) async {
    if (entry.operation == 'delete') {
      await _remote.deleteTaskList(entry.entityId);
      return;
    }

    final list = await _local.getTaskListById(entry.entityId);
    if (list == null) return;

    await _remote.setTaskList(list);
    await _local.markTaskListSynced(list.id);
  }

  /// Checks whether the local version should take precedence.
  ///
  /// In last-write-wins, the record with the later [updatedAt] wins.
  /// If the local record was updated after the remote, we keep the local.
  bool _isLocalDirty(Task local, Task remote) {
    return local.updatedAt.isAfter(remote.updatedAt);
  }

  bool _isLocalListDirty(TaskList local, TaskList remote) {
    return local.updatedAt.isAfter(remote.updatedAt);
  }
}
