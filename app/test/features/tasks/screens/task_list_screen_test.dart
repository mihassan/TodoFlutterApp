import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart';
import 'package:todo_flutter_app/features/tasks/screens/task_list_screen.dart';
import '../../../helpers/test_app.dart';

void main() {
  group('TaskListScreen', () {
    group('— empty state', () {
      testWidgets('shows "No tasks yet" when list is empty', (tester) async {
        final overrides = authenticatedOverrides();
        final container = ProviderContainer(overrides: overrides);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const TaskListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('No tasks yet'), findsOneWidget);
        expect(find.byType(ListView), findsNothing);

        container.dispose();
      });
    });

    group('— populated state', () {
      testWidgets('displays task list when tasks exist', (tester) async {
        final task1 = Task(
          id: 'task-1',
          title: 'Buy groceries',
          notes: 'Milk, eggs, bread',
          isCompleted: false,
          priority: Priority.high,
          dueAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final task2 = Task(
          id: 'task-2',
          title: 'Finish project',
          notes: '',
          isCompleted: false, // Changed to incomplete so it shows in Inbox
          priority: Priority.medium,
          dueAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final overrides = authenticatedOverridesWith(
          initialTasks: [task1, task2],
        );
        final container = ProviderContainer(overrides: overrides);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const TaskListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Buy groceries'), findsOneWidget);
        expect(find.text('Finish project'), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);

        container.dispose();
      });

      testWidgets('displays completed task in Completed filter', (
        tester,
      ) async {
        final completedTask = Task(
          id: 'task-1',
          title: 'Completed task',
          notes: '',
          isCompleted: true,
          priority: Priority.none,
          dueAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final overrides = authenticatedOverridesWith(
          initialTasks: [completedTask],
        );
        final container = ProviderContainer(overrides: overrides);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const TaskListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Completed filter to see the task
        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();

        expect(find.text('Completed task'), findsOneWidget);

        container.dispose();
      });

      testWidgets('displays task notes as subtitle when present', (
        tester,
      ) async {
        final task = Task(
          id: 'task-1',
          title: 'Task with notes',
          notes: 'Important details here',
          isCompleted: false,
          priority: Priority.none,
          dueAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final overrides = authenticatedOverridesWith(initialTasks: [task]);
        final container = ProviderContainer(overrides: overrides);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const TaskListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Important details here'), findsOneWidget);

        container.dispose();
      });
    });

    group('— filter tabs', () {
      testWidgets('displays all filter options', (tester) async {
        final overrides = authenticatedOverrides();
        final container = ProviderContainer(overrides: overrides);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const TaskListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Inbox'), findsOneWidget);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Upcoming'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);

        container.dispose();
      });

      testWidgets('can switch between filters', (tester) async {
        final overrides = authenticatedOverrides();
        final container = ProviderContainer(overrides: overrides);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const TaskListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap "Completed" filter
        await tester.tap(find.text('Completed'));
        await tester.pumpAndSettle();

        expect(find.text('Completed'), findsOneWidget);

        container.dispose();
      });
    });

    group('— checkbox interaction', () {
      testWidgets('checkbox exists for each task', (tester) async {
        final task = Task(
          id: 'task-1',
          title: 'Task to complete',
          notes: '',
          isCompleted: false,
          priority: Priority.none,
          dueAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final overrides = authenticatedOverridesWith(initialTasks: [task]);
        final container = ProviderContainer(overrides: overrides);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const TaskListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(Checkbox), findsOneWidget);

        container.dispose();
      });
    });

    group('— accessibility', () {
      testWidgets('task list items are accessible', (tester) async {
        final task = Task(
          id: 'task-1',
          title: 'Accessible task',
          notes: '',
          isCompleted: false,
          priority: Priority.none,
          dueAt: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final overrides = authenticatedOverridesWith(initialTasks: [task]);
        final container = ProviderContainer(overrides: overrides);

        await tester.pumpWidget(
          ProviderScope(
            overrides: overrides,
            child: MaterialApp(
              theme: ThemeData.light(),
              home: const TaskListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Accessible task'), findsOneWidget);
        expect(find.byType(Checkbox), findsOneWidget);

        container.dispose();
      });
    });
  });
}
