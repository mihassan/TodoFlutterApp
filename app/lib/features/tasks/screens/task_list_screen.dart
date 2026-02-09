import 'package:flutter/material.dart';

import 'package:todo_flutter_app/core/widgets/empty_state.dart';

/// Placeholder task list screen.
///
/// Will be replaced with a full list + filters in Phase 10.
class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: const EmptyState(
        icon: Icons.task_alt,
        title: 'No tasks yet',
        subtitle: 'Tap + to create your first task',
      ),
    );
  }
}
