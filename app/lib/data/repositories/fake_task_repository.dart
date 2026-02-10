import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/entities/task_list.dart';
import 'package:todo_flutter_app/domain/repositories/task_repository.dart';

/// A fake implementation of [TaskRepository] for testing.
///
/// Stores tasks and task lists in memory. Does not sync to Firestore.
/// Useful for unit tests and widget tests.
class FakeTaskRepository implements TaskRepository {
  /// Creates a [FakeTaskRepository].
  ///
  /// Optionally provide initial [tasks] and [taskLists].
  FakeTaskRepository({List<Task>? tasks, List<TaskList>? taskLists})
    : _tasks = tasks ?? [],
      _taskLists = taskLists ?? [],
      _isSyncingNotifier = _SyncingNotifier();

  final List<Task> _tasks;
  final List<TaskList> _taskLists;
  final _SyncingNotifier _isSyncingNotifier;

  @override
  Future<(List<Task>, StorageFailure?)> getTasks() async {
    return (_tasks, null);
  }

  @override
  Future<(Task?, StorageFailure?)> getTaskById(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      return (task, null);
    } catch (e) {
      return (null, null); // Return null if not found, not an error
    }
  }

  @override
  Future<(List<TaskList>, StorageFailure?)> getTaskLists() async {
    return (_taskLists, null);
  }

  @override
  Future<(Task, StorageFailure?)> createTask(Task task) async {
    _tasks.add(task);
    return (task, null);
  }

  @override
  Future<(Task, StorageFailure?)> updateTask(Task task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) {
      return (task, const NotFound());
    }
    _tasks[index] = task;
    return (task, null);
  }

  @override
  Future<StorageFailure?> deleteTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) {
      return const NotFound();
    }
    _tasks.removeAt(index);
    return null;
  }

  @override
  Future<(TaskList, StorageFailure?)> createTaskList(TaskList list) async {
    _taskLists.add(list);
    return (list, null);
  }

  @override
  Future<(TaskList, StorageFailure?)> updateTaskList(TaskList list) async {
    final index = _taskLists.indexWhere((l) => l.id == list.id);
    if (index == -1) {
      return (list, const NotFound());
    }
    _taskLists[index] = list;
    return (list, null);
  }

  @override
  Future<StorageFailure?> deleteTaskList(String listId) async {
    final index = _taskLists.indexWhere((l) => l.id == listId);
    if (index == -1) {
      return const NotFound();
    }
    _taskLists.removeAt(index);
    return null;
  }

  @override
  Future<NetworkFailure?> sync() async {
    _isSyncingNotifier.startSync();
    await Future.delayed(const Duration(milliseconds: 100));
    _isSyncingNotifier.endSync();
    return null;
  }

  @override
  Future<NetworkFailure?> syncOnDemand() async {
    return sync();
  }

  @override
  Stream<bool> get isSyncing => _isSyncingNotifier.stream;
}

/// Helper notifier for sync status streaming.
class _SyncingNotifier {
  final List<void Function(bool)> _listeners = [];

  void startSync() {
    _notifyListeners(true);
  }

  void endSync() {
    _notifyListeners(false);
  }

  Stream<bool> get stream {
    return Stream.multi((controller) {
      // Emit initial state
      controller.add(false);

      void listener(bool isSyncing) {
        controller.add(isSyncing);
      }

      _listeners.add(listener);
      controller.onCancel = () {
        _listeners.remove(listener);
      };
    });
  }

  void _notifyListeners(bool isSyncing) {
    for (final listener in _listeners) {
      listener(isSyncing);
    }
  }
}
