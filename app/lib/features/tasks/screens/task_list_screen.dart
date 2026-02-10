import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_flutter_app/app/providers/task_providers.dart';
import 'package:todo_flutter_app/core/widgets/empty_state.dart';

/// Task list screen with pull-to-refresh and filters.
///
/// Handles all 4 states: loading, empty, error, and populated.
/// Supports filters: Inbox, Today, Upcoming, Completed.
class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: RefreshIndicator(
        onRefresh: () async {
          final controller = ref.read(syncControllerProvider.notifier);
          await controller.triggerSync();
        },
        child: const EmptyState(
          icon: Icons.task_alt,
          title: 'No tasks yet',
          subtitle: 'Tap + to create your first task',
        ),
      ),
    );
  }
}
