import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/repositories/task_repository.dart';

/// State for task editing operations.
class TaskEditState {
  const TaskEditState({
    this.task,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.success = false,
  });

  final Task? task;
  final bool isLoading;
  final bool isSaving;
  final AppFailure? error;
  final bool success;

  TaskEditState copyWith({
    Task? task,
    bool? isLoading,
    bool? isSaving,
    AppFailure? error,
    bool? success,
  }) {
    return TaskEditState(
      task: task ?? this.task,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      success: success ?? this.success,
    );
  }
}

/// Controller for editing existing tasks.
///
/// Handles loading, validation, and persistence of task updates.
class TaskEditController extends StateNotifier<TaskEditState> {
  TaskEditController({required TaskRepository repository})
    : _repository = repository,
      super(const TaskEditState());

  final TaskRepository _repository;

  /// Loads a task by ID.
  ///
  /// Sets loading state and fetches the task from the repository.
  Future<void> loadTask(String taskId) async {
    state = state.copyWith(isLoading: true, error: null);

    final (task, failure) = await _repository.getTaskById(taskId);

    if (failure != null) {
      state = state.copyWith(isLoading: false, error: failure);
      return;
    }

    if (task == null) {
      state = state.copyWith(
        isLoading: false,
        error: const NotFound('Task not found'),
      );
      return;
    }

    state = state.copyWith(isLoading: false, task: task);
  }

  /// Updates the current task with new values.
  ///
  /// Only updates non-null fields. Returns `true` if successful.
  Future<bool> updateTask({
    String? title,
    String? notes,
    DateTime? dueAt,
    Priority? priority,
    bool? isCompleted,
  }) async {
    if (state.task == null) return false;

    state = state.copyWith(isSaving: true, error: null, success: false);

    // Create updated task
    final updatedTask = state.task!.copyWith(
      title: title ?? state.task!.title,
      notes: notes ?? state.task!.notes,
      dueAt: dueAt ?? state.task!.dueAt,
      priority: priority ?? state.task!.priority,
      isCompleted: isCompleted ?? state.task!.isCompleted,
      updatedAt: DateTime.now().toUtc(),
    );

    // Persist changes
    final (_, failure) = await _repository.updateTask(updatedTask);

    if (failure != null) {
      state = state.copyWith(isSaving: false, error: failure);
      return false;
    }

    state = state.copyWith(isSaving: false, task: updatedTask, success: true);
    return true;
  }

  /// Deletes the current task.
  ///
  /// Returns `true` if successful.
  Future<bool> deleteTask() async {
    if (state.task == null) return false;

    state = state.copyWith(isSaving: true, error: null);

    final failure = await _repository.deleteTask(state.task!.id);

    if (failure != null) {
      state = state.copyWith(isSaving: false, error: failure);
      return false;
    }

    state = state.copyWith(isSaving: false, success: true);
    return true;
  }

  /// Toggles task completion status.
  Future<bool> toggleCompletion() {
    return updateTask(
      isCompleted: state.task != null ? !state.task!.isCompleted : false,
    );
  }

  /// Resets the state.
  void reset() {
    state = const TaskEditState();
  }
}
