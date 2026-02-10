import 'package:drift/drift.dart';

import 'package:todo_flutter_app/domain/entities/attachment.dart' as domain;
import 'package:todo_flutter_app/domain/entities/task.dart' as domain;
import 'package:todo_flutter_app/domain/entities/task_list.dart' as domain;

import 'app_database.dart';

/// Extension methods to convert between Drift data classes and domain entities.
///
/// These mappers live in the data layer and are the only place that knows
/// about both the Drift-generated types and the domain entities.

// ── Task ─────────────────────────────────────────────────

/// Converts a Drift [TaskEntry] to a domain [Task].
extension TaskEntryToDomain on TaskEntry {
  domain.Task toDomain() {
    return domain.Task(
      id: id,
      title: title,
      notes: notes,
      isCompleted: isCompleted,
      dueAt: dueAt?.toUtc(),
      priority: priority,
      tags: tags.isEmpty ? [] : tags.split(','),
      listId: listId,
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
    );
  }
}

/// Converts a domain [Task] to a Drift [TaskEntriesCompanion] for inserts.
extension TaskToCompanion on domain.Task {
  TaskEntriesCompanion toCompanion() {
    return TaskEntriesCompanion.insert(
      id: id,
      title: title,
      notes: Value(notes),
      isCompleted: Value(isCompleted),
      dueAt: Value(dueAt),
      priority: Value(priority),
      tags: Value(tags.join(',')),
      listId: Value(listId),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ── TaskList ─────────────────────────────────────────────

/// Converts a Drift [TaskListEntry] to a domain [TaskList].
extension TaskListEntryToDomain on TaskListEntry {
  domain.TaskList toDomain() {
    return domain.TaskList(
      id: id,
      name: name,
      colorHex: colorHex,
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt.toUtc(),
    );
  }
}

/// Converts a domain [TaskList] to a Drift [TaskListEntriesCompanion].
extension TaskListToCompanion on domain.TaskList {
  TaskListEntriesCompanion toCompanion() {
    return TaskListEntriesCompanion.insert(
      id: id,
      name: name,
      colorHex: Value(colorHex),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ── Attachment ───────────────────────────────────────────

/// Converts a Drift [AttachmentEntry] to a domain [Attachment].
extension AttachmentEntryToDomain on AttachmentEntry {
  domain.Attachment toDomain() {
    return domain.Attachment(
      id: id,
      taskId: taskId,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      localPath: localPath,
      remoteUrl: remoteUrl,
      status: status,
      createdAt: createdAt.toUtc(),
    );
  }
}

/// Converts a domain [Attachment] to a Drift [AttachmentEntriesCompanion].
extension AttachmentToCompanion on domain.Attachment {
  AttachmentEntriesCompanion toCompanion() {
    return AttachmentEntriesCompanion.insert(
      id: id,
      taskId: taskId,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      localPath: localPath,
      remoteUrl: Value(remoteUrl),
      status: Value(status),
      createdAt: createdAt,
    );
  }
}
