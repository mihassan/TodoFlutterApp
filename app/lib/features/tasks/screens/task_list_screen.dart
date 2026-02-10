import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:todo_flutter_app/app/providers/task_providers.dart';
import 'package:todo_flutter_app/app/routes.dart';
import 'package:todo_flutter_app/core/widgets/empty_state.dart';
import 'package:todo_flutter_app/domain/use_cases/filter_tasks.dart';
import 'package:todo_flutter_app/features/tasks/widgets/task_creation_sheet.dart';

/// Task list screen with pull-to-refresh and filters.
///
/// Handles all 4 states: loading, empty, error, and populated.
/// Supports filters: Inbox, Today, Upcoming, Completed.
class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTasks = ref.watch(filteredTasksProvider);
    final currentFilter = ref.watch(taskFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks'), elevation: 0),
      body: Column(
        children: [
          // Filter tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                for (final filter in TaskFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_filterLabel(filter)),
                      selected: currentFilter == filter,
                      onSelected: (selected) {
                        ref.read(taskFilterProvider.notifier).state = filter;
                      },
                    ),
                  ),
              ],
            ),
          ),
          // Tasks list with pull-to-refresh
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final controller = ref.read(syncControllerProvider.notifier);
                await controller.triggerSync();
              },
              child: filteredTasks.when(
                loading: () => const _LoadingState(),
                error: (error, stackTrace) => _ErrorState(
                  error: error.toString(),
                  onRetry: () {
                    ref.invalidate(allTasksProvider);
                  },
                ),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return const _EmptyState();
                  }
                  return _PopulatedState(tasks: tasks);
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) => const TaskCreationSheet(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _filterLabel(TaskFilter filter) {
    return switch (filter) {
      TaskFilter.inbox => 'Inbox',
      TaskFilter.today => 'Today',
      TaskFilter.upcoming => 'Upcoming',
      TaskFilter.completed => 'Completed',
    };
  }
}

/// Loading state widget.
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Empty state widget.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.task_alt,
      title: 'No tasks yet',
      subtitle: 'Tap + to create your first task',
    );
  }
}

/// Error state widget.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Populated state widget showing the task list.
class _PopulatedState extends ConsumerWidget {
  const _PopulatedState({required this.tasks});

  final List<dynamic> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: tasks.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Dismissible(
            key: ValueKey(task.id),
            direction: DismissDirection.horizontal,
            onDismissed: (direction) async {
              final controller = ref.read(taskEditControllerProvider.notifier);
              if (direction == DismissDirection.startToEnd) {
                // Swipe left to right: Toggle completion
                await controller.loadTask(task.id);
                await controller.updateTask(isCompleted: !task.isCompleted);
                ref.invalidate(allTasksProvider);
              } else if (direction == DismissDirection.endToStart) {
                // Swipe right to left: Delete
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Task'),
                    content: const Text(
                      'Are you sure you want to delete this task?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await controller.deleteTask();
                  ref.invalidate(allTasksProvider);
                }
              }
            },
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              child: const Icon(Icons.check, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: Card(
              child: ListTile(
                title: Text(
                  task.title,
                  style: task.isCompleted
                      ? TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        )
                      : null,
                ),
                subtitle: task.notes != null && task.notes!.isNotEmpty
                    ? Text(
                        task.notes!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                trailing: Checkbox(
                  value: task.isCompleted,
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(taskEditControllerProvider.notifier)
                          .loadTask(task.id)
                          .then((_) {
                            ref
                                .read(taskEditControllerProvider.notifier)
                                .updateTask(isCompleted: value);
                            ref.invalidate(allTasksProvider);
                          });
                    }
                  },
                ),
                onTap: () {
                  context.push(AppRoutes.taskDetailPath(task.id));
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
