import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/repositories/task_repository.dart';
import 'package:todo_flutter_app/domain/use_cases/create_task.dart';

/// State for task creation operations.
class TaskCreationState {
  const TaskCreationState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  final bool isLoading;
  final AppFailure? error;
  final bool success;

  TaskCreationState copyWith({
    bool? isLoading,
    AppFailure? error,
    bool? success,
  }) {
    return TaskCreationState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      success: success ?? this.success,
    );
  }
}

/// Controller for creating new tasks.
///
/// Handles validation and persistence of new tasks.
class TaskCreationController extends StateNotifier<TaskCreationState> {
  TaskCreationController({
    required TaskRepository repository,
  }) : _repository = repository,
       _createTaskUseCase = const CreateTask(),
       super(const TaskCreationState());

  final TaskRepository _repository;
  final CreateTask _createTaskUseCase;

  /// Creates a new task with the given title and optional notes.
  ///
  /// Returns `true` if successful, `false` if validation/storage failed.
  Future<bool> createTask({
    required String title,
    String? notes,
    DateTime? dueAt,
    Priority priority = Priority.medium,
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);

    // Validate and create task using use case
    final result = _createTaskUseCase(
      title: title,
      notes: notes ?? '',
      dueAt: dueAt,
      priority: priority,
    );

    // Check if validation failed
    if (result is AppFailure) {
      state = state.copyWith(
        isLoading: false,
        error: result,
      );
      return false;
    }

    // Result is a Task
    final newTask = result as Task;

    // Persist to repository
    final (_, failure) = await _repository.createTask(newTask);

    if (failure != null) {
      state = state.copyWith(
        isLoading: false,
        error: failure,
      );
      return false;
    }

    state = state.copyWith(
      isLoading: false,
      success: true,
    );
    return true;
  }

  /// Resets the state after task creation.
  void reset() {
    state = const TaskCreationState();
  }
}
