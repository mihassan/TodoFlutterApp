import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/entities/task_list.dart';

/// Repository interface for task management operations.
///
/// Abstracts away local (Drift) and remote (Firestore) data sources
/// and returns typed [AppFailure] objects instead of raw exceptions.
///
/// Implementations follow an offline-first pattern:
/// - Writes go to local DB immediately
/// - Reads aggregate local + recently-synced remote data
/// - Sync engine pushes changes to Firestore in the background
///
/// Implementations must:
/// - Map database/network exceptions to [AppFailure] subclasses
/// - Ensure user isolation (only return tasks for authenticated user's UID)
/// - Never throw exceptions; always return failures or success values
abstract interface class TaskRepository {
  /// Returns the current list of tasks for the authenticated user.
  ///
  /// Reads from local DB; does not make network requests.
  /// Returns an empty list if no tasks exist.
  /// Fails if the user is not authenticated.
  Future<(List<Task>, StorageFailure?)> getTasks();

  /// Returns a single task by ID.
  ///
  /// Returns `null` if the task does not exist; fails if the user
  /// is not authenticated or lacks permission.
  Future<(Task?, StorageFailure?)> getTaskById(String taskId);

  /// Returns all [TaskList]s for the authenticated user.
  ///
  /// Reads from local DB; does not make network requests.
  /// Returns an empty list if no task lists exist.
  Future<(List<TaskList>, StorageFailure?)> getTaskLists();

  /// Creates a new task in the local DB.
  ///
  /// The task is enqueued for sync to Firestore. Returns the created
  /// [Task] on success, or a [StorageFailure] if the operation fails.
  Future<(Task, StorageFailure?)> createTask(Task task);

  /// Updates an existing task in the local DB.
  ///
  /// The change is enqueued for sync. Returns the updated [Task],
  /// or a [StorageFailure] if not found or operation fails.
  Future<(Task, StorageFailure?)> updateTask(Task task);

  /// Deletes a task from the local DB.
  ///
  /// The deletion is enqueued for sync. Returns `null` on success,
  /// or a [StorageFailure] if not found or operation fails.
  Future<StorageFailure?> deleteTask(String taskId);

  /// Creates a new [TaskList] in the local DB.
  ///
  /// The list is enqueued for sync. Returns the created [TaskList],
  /// or a [StorageFailure] if the operation fails.
  Future<(TaskList, StorageFailure?)> createTaskList(TaskList list);

  /// Updates an existing [TaskList] in the local DB.
  ///
  /// The change is enqueued for sync. Returns the updated [TaskList],
  /// or a [StorageFailure] if not found or operation fails.
  Future<(TaskList, StorageFailure?)> updateTaskList(TaskList list);

  /// Deletes a [TaskList] from the local DB.
  ///
  /// Associated tasks may be re-parented to Inbox (null listId) or
  /// deleted depending on implementation. The deletion is enqueued for sync.
  /// Returns `null` on success, or a [StorageFailure] if not found or fails.
  Future<StorageFailure?> deleteTaskList(String listId);

  /// Synchronizes local changes with Firestore.
  ///
  /// Pushes all locally-modified tasks/lists to Firestore, then pulls
  /// any remote changes not yet synced. Uses last-write-wins conflict resolution.
  /// Returns `null` on success, or a [NetworkFailure] if the operation fails.
  ///
  /// Automatically called on:
  /// - App startup
  /// - Pull-to-refresh
  /// - Network regain
  /// - Periodic background sync (Workmanager)
  Future<NetworkFailure?> sync();

  /// Triggers a one-time sync (usually called by UI for pull-to-refresh).
  ///
  /// Wrapper around [sync] that may include additional logging or metrics.
  Future<NetworkFailure?> syncOnDemand();

  /// Returns the current sync status.
  ///
  /// Useful for displaying a "syncing..." indicator.
  /// Emits `true` when a sync is in progress.
  Stream<bool> get isSyncing;
}
