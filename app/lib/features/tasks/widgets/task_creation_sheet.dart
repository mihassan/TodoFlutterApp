import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_flutter_app/app/providers/task_providers.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';

/// Bottom sheet for creating a new task.
///
/// Displays a form with title, notes, due date, and priority fields.
/// Handles validation and submission.
class TaskCreationSheet extends ConsumerStatefulWidget {
  const TaskCreationSheet({super.key});

  @override
  ConsumerState<TaskCreationSheet> createState() => _TaskCreationSheetState();
}

class _TaskCreationSheetState extends ConsumerState<TaskCreationSheet> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  DateTime? _selectedDueDate;
  Priority _selectedPriority = Priority.medium;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _submitTask() async {
    final controller = ref.read(taskCreationControllerProvider.notifier);

    final success = await controller.createTask(
      title: _titleController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      dueAt: _selectedDueDate,
      priority: _selectedPriority,
    );

    if (!mounted) return;

    if (success) {
      // Refresh task list and close sheet
      ref.invalidate(allTasksProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      controller.reset();
    } else {
      // Show error via ScaffoldMessenger
      final state = ref.read(taskCreationControllerProvider);
      if (state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final creationState = ref.watch(taskCreationControllerProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create Task', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            // Title field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Task Title *',
                hintText: 'What do you need to do?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              enabled: !creationState.isLoading,
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            // Notes field
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes',
                hintText: 'Add details (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              enabled: !creationState.isLoading,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            // Due date picker
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'Select due date',
                    button: true,
                    enabled: !creationState.isLoading,
                    onTap: creationState.isLoading ? null : _selectDueDate,
                    child: OutlinedButton.icon(
                      onPressed: creationState.isLoading
                          ? null
                          : _selectDueDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDueDate == null
                            ? 'No due date'
                            : 'Due: ${_formatDate(_selectedDueDate!)}',
                      ),
                    ),
                  ),
                ),
                if (_selectedDueDate != null)
                  Semantics(
                    label: 'Clear due date',
                    button: true,
                    enabled: !creationState.isLoading,
                    onTap: creationState.isLoading
                        ? null
                        : () {
                            setState(() {
                              _selectedDueDate = null;
                            });
                          },
                    child: IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear due date',
                      onPressed: creationState.isLoading
                          ? null
                          : () {
                              setState(() {
                                _selectedDueDate = null;
                              });
                            },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Priority selector
            Row(
              children: [
                const Text('Priority:'),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<Priority>(
                    segments: const <ButtonSegment<Priority>>[
                      ButtonSegment<Priority>(
                        value: Priority.low,
                        label: Text('Low'),
                      ),
                      ButtonSegment<Priority>(
                        value: Priority.medium,
                        label: Text('Med'),
                      ),
                      ButtonSegment<Priority>(
                        value: Priority.high,
                        label: Text('High'),
                      ),
                    ],
                    selected: <Priority>{_selectedPriority},
                    onSelectionChanged: creationState.isLoading
                        ? null
                        : (Set<Priority> newSelection) {
                            setState(() {
                              _selectedPriority = newSelection.first;
                            });
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Submit button
            Semantics(
              label: 'Create new task',
              button: true,
              enabled: !creationState.isLoading,
              onTap: creationState.isLoading ? null : _submitTask,
              child: ElevatedButton(
                onPressed: creationState.isLoading ? null : _submitTask,
                child: creationState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
