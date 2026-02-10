import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:todo_flutter_app/app/providers/attachment_providers.dart';
import 'package:todo_flutter_app/app/providers/task_providers.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';
import '../widgets/attachment_list_section.dart';
import '../widgets/add_attachment_button.dart';

/// Screen for viewing and editing a task.
///
/// Displays task details with options to edit and delete.
class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({required this.taskId, super.key});

  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  DateTime? _selectedDueDate;
  Priority? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();

    // Load task on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskEditControllerProvider.notifier).loadTask(widget.taskId);
    });
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
      initialDate: _selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    final controller = ref.read(taskEditControllerProvider.notifier);

    final success = await controller.updateTask(
      title: _titleController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      dueAt: _selectedDueDate,
      priority: _selectedPriority,
    );

    if (!mounted) return;

    if (success) {
      ref.invalidate(allTasksProvider);
      Navigator.of(context).pop();
    } else {
      final state = ref.read(taskEditControllerProvider);
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

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
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

    if (confirmed != true) return;

    final controller = ref.read(taskEditControllerProvider.notifier);
    final success = await controller.deleteTask();

    if (!mounted) return;

    if (success) {
      ref.invalidate(allTasksProvider);
      Navigator.of(context).pop();
    } else {
      final state = ref.read(taskEditControllerProvider);
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

  Widget _buildAttachmentsSection() {
    final attachmentsAsync = ref.watch(
      attachmentsByTaskIdProvider(widget.taskId),
    );
    final isUploadingAsync = ref.watch(isUploadingProvider);

    return attachmentsAsync.when(
      data: (attachments) => Column(
        children: [
          AttachmentListSection(
            attachments: attachments,
            onRetry: (id) {
              // TODO: Add retry method to repository in Phase 11.6
            },
            onDelete: (id) async {
              await ref.read(attachmentRepositoryProvider).deleteAttachment(id);
            },
          ),
          const SizedBox(height: 12),
          AddAttachmentButton(
            onFileSelected: (path) async {
              // Extract file metadata from path
              final file = XFile(path);
              final fileName = file.name;
              final mimeType = _getMimeType(fileName);
              final sizeBytes = await file.length();

              // Add attachment to repository
              await ref
                  .read(attachmentRepositoryProvider)
                  .addAttachment(
                    taskId: widget.taskId,
                    localFilePath: path,
                    fileName: fileName,
                    mimeType: mimeType,
                    sizeBytes: sizeBytes,
                  );
            },
            isUploading: isUploadingAsync.when(
              data: (uploading) => uploading,
              loading: () => false,
              error: (_, __) => false,
            ),
          ),
        ],
      ),
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, st) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Failed to load attachments: $err',
          style: TextStyle(color: Colors.red.shade600),
        ),
      ),
    );
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'txt':
        return 'text/plain';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final editState = ref.watch(taskEditControllerProvider);

    // Initialize controllers when task loads
    if (editState.task != null && _titleController.text.isEmpty) {
      _titleController.text = editState.task!.title;
      _notesController.text = editState.task!.notes;
      _selectedDueDate = editState.task!.dueAt;
      _selectedPriority = editState.task!.priority;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          if (editState.task != null)
            Semantics(
              label: 'Delete task',
              button: true,
              enabled: !editState.isSaving,
              onTap: editState.isSaving ? null : _deleteTask,
              child: IconButton(
                icon: const Icon(Icons.delete),
                tooltip: 'Delete task',
                onPressed: editState.isSaving ? null : _deleteTask,
              ),
            ),
        ],
      ),
      body: editState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : editState.error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(editState.error.toString()),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Completion checkbox
                  Semantics(
                    label: 'Toggle task completion',
                    button: true,
                    enabled: !editState.isSaving,
                    child: CheckboxListTile(
                      title: const Text('Completed'),
                      value: editState.task?.isCompleted ?? false,
                      onChanged: editState.isSaving
                          ? null
                          : (value) {
                              if (value != null) {
                                ref
                                    .read(taskEditControllerProvider.notifier)
                                    .updateTask(isCompleted: value);
                              }
                            },
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Title field
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    enabled: !editState.isSaving,
                  ),
                  const SizedBox(height: 12),
                  // Notes field
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    enabled: !editState.isSaving,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 12),
                  // Attachments section
                  _buildAttachmentsSection(),
                  const SizedBox(height: 12),
                  // Due date
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: editState.isSaving ? null : _selectDueDate,
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _selectedDueDate == null
                                ? 'No due date'
                                : 'Due: ${_formatDate(_selectedDueDate!)}',
                          ),
                        ),
                      ),
                      if (_selectedDueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: editState.isSaving
                              ? null
                              : () {
                                  setState(() {
                                    _selectedDueDate = null;
                                  });
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Priority selector
                  if (_selectedPriority != null)
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
                            selected: <Priority>{_selectedPriority!},
                            onSelectionChanged: editState.isSaving
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
                  const SizedBox(height: 24),
                  // Save button
                  ElevatedButton(
                    onPressed: editState.isSaving ? null : _saveTask,
                    child: editState.isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Task'),
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
