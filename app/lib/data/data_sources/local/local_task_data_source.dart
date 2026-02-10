import 'package:drift/drift.dart';

import 'package:todo_flutter_app/domain/entities/task.dart' as domain;
import 'package:todo_flutter_app/domain/entities/task_list.dart' as domain;

import 'app_database.dart';
import 'mappers.dart';

/// Local data source for tasks and task lists backed by Drift (SQLite).
///
/// All operations are synchronous (in-process SQLite) and wrapped in
/// [Future]s only for API consistency. This class does NOT handle
/// sync tracking or failure mapping — that's the repository's job.
class LocalTaskDataSource {
  LocalTaskDataSource(this._db);

  final AppDatabase _db;

  // ── Task CRUD ──────────────────────────────────────────

  /// Returns all tasks, optionally filtered by [listId].
  Future<List<domain.Task>> getTasks({String? listId}) async {
    final query = _db.select(_db.taskEntries);
    if (listId != null) {
      query.where((t) => t.listId.equals(listId));
    }
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Returns a single task by [id], or `null` if not found.
  Future<domain.Task?> getTaskById(String id) async {
    final query = _db.select(_db.taskEntries)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row?.toDomain();
  }

  /// Inserts a new task. Marks it as dirty for sync.
  Future<void> insertTask(domain.Task task) async {
    await _db.into(_db.taskEntries).insert(task.toCompanion());
  }

  /// Updates an existing task. Marks it as dirty for sync.
  Future<bool> updateTask(domain.Task task) async {
    final companion = TaskEntriesCompanion(
      title: Value(task.title),
      notes: Value(task.notes),
      isCompleted: Value(task.isCompleted),
      dueAt: Value(task.dueAt),
      priority: Value(task.priority),
      tags: Value(task.tags.join(',')),
      listId: Value(task.listId),
      updatedAt: Value(task.updatedAt),
      isDirty: const Value(true),
    );
    final count = await (_db.update(
      _db.taskEntries,
    )..where((t) => t.id.equals(task.id))).write(companion);
    return count > 0;
  }

  /// Deletes a task by [id]. Returns `true` if a row was deleted.
  Future<bool> deleteTask(String id) async {
    final count = await (_db.delete(
      _db.taskEntries,
    )..where((t) => t.id.equals(id))).go();
    return count > 0;
  }

  /// Watches all tasks as a reactive stream.
  Stream<List<domain.Task>> watchTasks() {
    return _db
        .select(_db.taskEntries)
        .watch()
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  // ── TaskList CRUD ──────────────────────────────────────

  /// Returns all task lists.
  Future<List<domain.TaskList>> getTaskLists() async {
    final rows = await _db.select(_db.taskListEntries).get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Returns a single task list by [id], or `null` if not found.
  Future<domain.TaskList?> getTaskListById(String id) async {
    final query = _db.select(_db.taskListEntries)
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row?.toDomain();
  }

  /// Inserts a new task list. Marks it as dirty for sync.
  Future<void> insertTaskList(domain.TaskList list) async {
    await _db.into(_db.taskListEntries).insert(list.toCompanion());
  }

  /// Updates an existing task list. Marks it as dirty for sync.
  Future<bool> updateTaskList(domain.TaskList list) async {
    final companion = TaskListEntriesCompanion(
      name: Value(list.name),
      colorHex: Value(list.colorHex),
      updatedAt: Value(list.updatedAt),
      isDirty: const Value(true),
    );
    final count = await (_db.update(
      _db.taskListEntries,
    )..where((t) => t.id.equals(list.id))).write(companion);
    return count > 0;
  }

  /// Deletes a task list by [id]. Returns `true` if a row was deleted.
  Future<bool> deleteTaskList(String id) async {
    final count = await (_db.delete(
      _db.taskListEntries,
    )..where((t) => t.id.equals(id))).go();
    return count > 0;
  }

  /// Watches all task lists as a reactive stream.
  Stream<List<domain.TaskList>> watchTaskLists() {
    return _db
        .select(_db.taskListEntries)
        .watch()
        .map((rows) => rows.map((row) => row.toDomain()).toList());
  }

  // ── Sync helpers ───────────────────────────────────────

  /// Returns all tasks that have been modified locally since last sync.
  Future<List<domain.Task>> getDirtyTasks() async {
    final query = _db.select(_db.taskEntries)
      ..where((t) => t.isDirty.equals(true));
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Returns all task lists that have been modified locally since last sync.
  Future<List<domain.TaskList>> getDirtyTaskLists() async {
    final query = _db.select(_db.taskListEntries)
      ..where((t) => t.isDirty.equals(true));
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Marks a task as synced (not dirty) with the current timestamp.
  Future<void> markTaskSynced(String id) async {
    await (_db.update(_db.taskEntries)..where((t) => t.id.equals(id))).write(
      TaskEntriesCompanion(
        isDirty: const Value(false),
        lastSyncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Marks a task list as synced (not dirty) with the current timestamp.
  Future<void> markTaskListSynced(String id) async {
    await (_db.update(
      _db.taskListEntries,
    )..where((t) => t.id.equals(id))).write(
      TaskListEntriesCompanion(
        isDirty: const Value(false),
        lastSyncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
