import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter_app/data/data_sources/local/app_database.dart';
import 'package:todo_flutter_app/data/data_sources/local/local_task_data_source.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/domain/entities/task_list.dart';

void main() {
  late AppDatabase db;
  late LocalTaskDataSource dataSource;

  final now = DateTime.utc(2026, 2, 10, 12, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = LocalTaskDataSource(db);
  });

  tearDown(() async {
    await db.close();
  });

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

  group('LocalTaskDataSource — tasks', () {
    test('getTasks returns empty list when no tasks exist', () async {
      final tasks = await dataSource.getTasks();
      expect(tasks, isEmpty);
    });

    test('insertTask and getTasks round-trips a task', () async {
      final task = makeTask();
      await dataSource.insertTask(task);

      final tasks = await dataSource.getTasks();
      expect(tasks, hasLength(1));
      expect(tasks.first.id, 'task-1');
      expect(tasks.first.title, 'Buy groceries');
      expect(tasks.first.isCompleted, false);
      expect(tasks.first.priority, Priority.none);
    });

    test('insertTask preserves all fields', () async {
      final task = makeTask(
        notes: 'Milk, eggs, bread',
        isCompleted: true,
        dueAt: DateTime.utc(2026, 2, 15),
        priority: Priority.high,
        tags: ['shopping', 'weekly'],
        listId: null,
      );
      await dataSource.insertTask(task);

      final result = (await dataSource.getTasks()).first;
      expect(result.notes, 'Milk, eggs, bread');
      expect(result.isCompleted, true);
      expect(result.dueAt, DateTime.utc(2026, 2, 15));
      expect(result.priority, Priority.high);
      expect(result.tags, ['shopping', 'weekly']);
      expect(result.listId, isNull);
    });

    test('getTaskById returns task when found', () async {
      await dataSource.insertTask(makeTask());

      final task = await dataSource.getTaskById('task-1');
      expect(task, isNotNull);
      expect(task!.id, 'task-1');
    });

    test('getTaskById returns null when not found', () async {
      final task = await dataSource.getTaskById('nonexistent');
      expect(task, isNull);
    });

    test('updateTask modifies existing task', () async {
      await dataSource.insertTask(makeTask());

      final updated = makeTask(
        title: 'Buy veggies',
        notes: 'Broccoli, spinach',
        updatedAt: now.add(const Duration(hours: 1)),
      );
      final result = await dataSource.updateTask(updated);
      expect(result, true);

      final task = await dataSource.getTaskById('task-1');
      expect(task!.title, 'Buy veggies');
      expect(task.notes, 'Broccoli, spinach');
    });

    test('updateTask returns false when task not found', () async {
      final task = makeTask(id: 'nonexistent');
      final result = await dataSource.updateTask(task);
      expect(result, false);
    });

    test('deleteTask removes existing task', () async {
      await dataSource.insertTask(makeTask());

      final result = await dataSource.deleteTask('task-1');
      expect(result, true);

      final tasks = await dataSource.getTasks();
      expect(tasks, isEmpty);
    });

    test('deleteTask returns false when task not found', () async {
      final result = await dataSource.deleteTask('nonexistent');
      expect(result, false);
    });

    test('getTasks filters by listId', () async {
      // Need to create the task list first due to foreign key
      await dataSource.insertTaskList(makeTaskList(id: 'list-a'));

      await dataSource.insertTask(makeTask(id: 'task-1', listId: 'list-a'));
      await dataSource.insertTask(makeTask(id: 'task-2', listId: null));

      final filtered = await dataSource.getTasks(listId: 'list-a');
      expect(filtered, hasLength(1));
      expect(filtered.first.id, 'task-1');
    });

    test('insertTask with tags serialises and deserialises', () async {
      await dataSource.insertTask(
        makeTask(tags: ['urgent', 'home', 'weekend']),
      );

      final task = (await dataSource.getTasks()).first;
      expect(task.tags, ['urgent', 'home', 'weekend']);
    });

    test('insertTask with empty tags returns empty list', () async {
      await dataSource.insertTask(makeTask(tags: []));

      final task = (await dataSource.getTasks()).first;
      expect(task.tags, isEmpty);
    });

    test('multiple tasks can be inserted and retrieved', () async {
      await dataSource.insertTask(makeTask(id: 'task-1'));
      await dataSource.insertTask(makeTask(id: 'task-2', title: 'Walk dog'));
      await dataSource.insertTask(makeTask(id: 'task-3', title: 'Read book'));

      final tasks = await dataSource.getTasks();
      expect(tasks, hasLength(3));
    });
  });

  group('LocalTaskDataSource — task lists', () {
    test('getTaskLists returns empty list when none exist', () async {
      final lists = await dataSource.getTaskLists();
      expect(lists, isEmpty);
    });

    test('insertTaskList and getTaskLists round-trips', () async {
      await dataSource.insertTaskList(makeTaskList());

      final lists = await dataSource.getTaskLists();
      expect(lists, hasLength(1));
      expect(lists.first.id, 'list-1');
      expect(lists.first.name, 'Shopping');
    });

    test('insertTaskList preserves optional colorHex', () async {
      await dataSource.insertTaskList(makeTaskList(colorHex: '#FF5733'));

      final list = (await dataSource.getTaskLists()).first;
      expect(list.colorHex, '#FF5733');
    });

    test('getTaskListById returns list when found', () async {
      await dataSource.insertTaskList(makeTaskList());

      final list = await dataSource.getTaskListById('list-1');
      expect(list, isNotNull);
      expect(list!.name, 'Shopping');
    });

    test('getTaskListById returns null when not found', () async {
      final list = await dataSource.getTaskListById('nonexistent');
      expect(list, isNull);
    });

    test('updateTaskList modifies existing list', () async {
      await dataSource.insertTaskList(makeTaskList());

      final updated = makeTaskList(
        name: 'Grocery Shopping',
        colorHex: '#00FF00',
        updatedAt: now.add(const Duration(hours: 1)),
      );
      final result = await dataSource.updateTaskList(updated);
      expect(result, true);

      final list = await dataSource.getTaskListById('list-1');
      expect(list!.name, 'Grocery Shopping');
      expect(list.colorHex, '#00FF00');
    });

    test('updateTaskList returns false when not found', () async {
      final list = makeTaskList(id: 'nonexistent');
      final result = await dataSource.updateTaskList(list);
      expect(result, false);
    });

    test('deleteTaskList removes existing list', () async {
      await dataSource.insertTaskList(makeTaskList());

      final result = await dataSource.deleteTaskList('list-1');
      expect(result, true);

      final lists = await dataSource.getTaskLists();
      expect(lists, isEmpty);
    });

    test('deleteTaskList returns false when not found', () async {
      final result = await dataSource.deleteTaskList('nonexistent');
      expect(result, false);
    });
  });

  group('LocalTaskDataSource — sync tracking', () {
    test('newly inserted task is dirty', () async {
      await dataSource.insertTask(makeTask());

      final dirty = await dataSource.getDirtyTasks();
      expect(dirty, hasLength(1));
      expect(dirty.first.id, 'task-1');
    });

    test('markTaskSynced clears dirty flag', () async {
      await dataSource.insertTask(makeTask());
      await dataSource.markTaskSynced('task-1');

      final dirty = await dataSource.getDirtyTasks();
      expect(dirty, isEmpty);
    });

    test('updateTask re-marks task as dirty', () async {
      await dataSource.insertTask(makeTask());
      await dataSource.markTaskSynced('task-1');

      // Update should mark dirty again
      await dataSource.updateTask(
        makeTask(
          title: 'Updated',
          updatedAt: now.add(const Duration(hours: 1)),
        ),
      );

      final dirty = await dataSource.getDirtyTasks();
      expect(dirty, hasLength(1));
    });

    test('newly inserted task list is dirty', () async {
      await dataSource.insertTaskList(makeTaskList());

      final dirty = await dataSource.getDirtyTaskLists();
      expect(dirty, hasLength(1));
    });

    test('markTaskListSynced clears dirty flag', () async {
      await dataSource.insertTaskList(makeTaskList());
      await dataSource.markTaskListSynced('list-1');

      final dirty = await dataSource.getDirtyTaskLists();
      expect(dirty, isEmpty);
    });
  });

  group('LocalTaskDataSource — watchTasks', () {
    test('emits updated list when tasks change', () async {
      // Start watching before any changes
      final stream = dataSource.watchTasks();

      // Insert a task and verify emission
      await dataSource.insertTask(makeTask());

      // The stream should eventually emit a list with one task
      await expectLater(
        stream,
        emitsThrough(
          predicate<List<Task>>(
            (tasks) => tasks.length == 1 && tasks.first.id == 'task-1',
          ),
        ),
      );
    });
  });

  group('LocalTaskDataSource — watchTaskLists', () {
    test('emits updated list when task lists change', () async {
      final stream = dataSource.watchTaskLists();

      await dataSource.insertTaskList(makeTaskList());

      await expectLater(
        stream,
        emitsThrough(
          predicate<List<TaskList>>(
            (lists) => lists.length == 1 && lists.first.id == 'list-1',
          ),
        ),
      );
    });
  });
}
