import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/repositories/fake_task_repository.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/entities/task_list.dart';
import 'package:todo_flutter_app/domain/repositories/task_repository.dart';

void main() {
  group('TaskRepository — ', () {
    late TaskRepository taskRepo;

    setUp(() {
      taskRepo = FakeTaskRepository();
    });

    group('get tasks — ', () {
      test('returns empty list initially', () async {
        // Act
        final (tasks, failure) = await taskRepo.getTasks();

        // Assert
        expect(failure, isNull);
        expect(tasks, isEmpty);
      });

      test('returns all created tasks', () async {
        // Arrange
        final task1 = Task(
          id: '1',
          title: 'Buy milk',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        final task2 = Task(
          id: '2',
          title: 'Walk dog',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        await taskRepo.createTask(task1);
        await taskRepo.createTask(task2);

        // Act
        final (tasks, failure) = await taskRepo.getTasks();

        // Assert
        expect(failure, isNull);
        expect(tasks.length, 2);
        expect(tasks.map((t) => t.title).toList(), contains('Buy milk'));
        expect(tasks.map((t) => t.title).toList(), contains('Walk dog'));
      });
    });

    group('create task — ', () {
      test('adds a task to the list', () async {
        // Arrange
        final task = Task(
          id: '1',
          title: 'New task',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        // Act
        final (createdTask, failure) = await taskRepo.createTask(task);

        // Assert
        expect(failure, isNull);
        expect(createdTask.title, 'New task');

        final (tasks, _) = await taskRepo.getTasks();
        expect(tasks.length, 1);
        expect(tasks.first.id, '1');
      });
    });

    group('get task by id — ', () {
      test('returns the task if found', () async {
        // Arrange
        final task = Task(
          id: '1',
          title: 'Find me',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await taskRepo.createTask(task);

        // Act
        final (found, failure) = await taskRepo.getTaskById('1');

        // Assert
        expect(failure, isNull);
        expect(found, isNotNull);
        expect(found!.title, 'Find me');
      });

      test('returns null if not found', () async {
        // Act
        final (found, failure) = await taskRepo.getTaskById('nonexistent');

        // Assert
        expect(failure, isNull);
        expect(found, isNull);
      });
    });

    group('update task — ', () {
      test('updates an existing task', () async {
        // Arrange
        final task = Task(
          id: '1',
          title: 'Original',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await taskRepo.createTask(task);

        // Act
        final updatedTask = task.copyWith(title: 'Updated');
        final (result, failure) = await taskRepo.updateTask(updatedTask);

        // Assert
        expect(failure, isNull);
        expect(result.title, 'Updated');

        final (found, _) = await taskRepo.getTaskById('1');
        expect(found!.title, 'Updated');
      });

      test('fails if task does not exist', () async {
        // Arrange
        final task = Task(
          id: 'nonexistent',
          title: 'Ghost',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        // Act
        final (result, failure) = await taskRepo.updateTask(task);

        // Assert
        expect(failure, isA<NotFound>());
      });
    });

    group('delete task — ', () {
      test('removes a task', () async {
        // Arrange
        final task = Task(
          id: '1',
          title: 'Delete me',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await taskRepo.createTask(task);

        // Act
        final failure = await taskRepo.deleteTask('1');

        // Assert
        expect(failure, isNull);

        final (tasks, _) = await taskRepo.getTasks();
        expect(tasks, isEmpty);
      });

      test('fails if task does not exist', () async {
        // Act
        final failure = await taskRepo.deleteTask('nonexistent');

        // Assert
        expect(failure, isA<NotFound>());
      });
    });

    group('task lists — ', () {
      test('get task lists returns empty initially', () async {
        // Act
        final (lists, failure) = await taskRepo.getTaskLists();

        // Assert
        expect(failure, isNull);
        expect(lists, isEmpty);
      });

      test('create task list adds to list', () async {
        // Arrange
        final list = TaskList(
          id: '1',
          name: 'Work',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );

        // Act
        final (createdList, failure) = await taskRepo.createTaskList(list);

        // Assert
        expect(failure, isNull);
        expect(createdList.name, 'Work');

        final (lists, _) = await taskRepo.getTaskLists();
        expect(lists.length, 1);
      });

      test('update task list works', () async {
        // Arrange
        final list = TaskList(
          id: '1',
          name: 'Work',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await taskRepo.createTaskList(list);

        // Act
        final updated = list.copyWith(name: 'Personal');
        final (result, failure) = await taskRepo.updateTaskList(updated);

        // Assert
        expect(failure, isNull);
        expect(result.name, 'Personal');
      });

      test('delete task list works', () async {
        // Arrange
        final list = TaskList(
          id: '1',
          name: 'Work',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await taskRepo.createTaskList(list);

        // Act
        final failure = await taskRepo.deleteTaskList('1');

        // Assert
        expect(failure, isNull);

        final (lists, _) = await taskRepo.getTaskLists();
        expect(lists, isEmpty);
      });
    });

    group('sync — ', () {
      test('completes successfully', () async {
        // Act
        final failure = await taskRepo.sync();

        // Assert
        expect(failure, isNull);
      });

      test('sync on demand completes successfully', () async {
        // Act
        final failure = await taskRepo.syncOnDemand();

        // Assert
        expect(failure, isNull);
      });

      test('is syncing stream emits true during sync', () async {
        // Arrange
        final states = <bool>[];
        taskRepo.isSyncing.listen((state) {
          states.add(state);
        });

        // Act
        await taskRepo.sync();

        // Allow async processing
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert: should have emitted [false, true, false]
        expect(states, contains(true));
      });
    });
  });
}
