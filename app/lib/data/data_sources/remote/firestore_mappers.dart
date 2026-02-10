import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:todo_flutter_app/domain/entities/priority.dart';
import 'package:todo_flutter_app/domain/entities/task.dart' as domain;
import 'package:todo_flutter_app/domain/entities/task_list.dart' as domain;

/// Mapper functions to convert between Firestore documents and domain entities.
///
/// Firestore stores dates as [Timestamp] and enums as [String]. These mappers
/// handle the conversion at the data-layer boundary.

// ── Task ─────────────────────────────────────────────────

/// Converts a Firestore document snapshot to a domain [Task].
///
/// The document ID is used as the task ID.
domain.Task taskFromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data()!;
  return domain.Task(
    id: doc.id,
    title: data['title'] as String,
    notes: (data['notes'] as String?) ?? '',
    isCompleted: (data['isCompleted'] as bool?) ?? false,
    dueAt: (data['dueAt'] as Timestamp?)?.toDate().toUtc(),
    priority: _parsePriority(data['priority'] as String?),
    tags:
        (data['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
        [],
    listId: data['listId'] as String?,
    createdAt: (data['createdAt'] as Timestamp).toDate().toUtc(),
    updatedAt: (data['updatedAt'] as Timestamp).toDate().toUtc(),
  );
}

/// Converts a domain [Task] to a Firestore-compatible map.
Map<String, dynamic> taskToFirestore(domain.Task task) {
  return {
    'title': task.title,
    'notes': task.notes,
    'isCompleted': task.isCompleted,
    'dueAt': task.dueAt != null ? Timestamp.fromDate(task.dueAt!) : null,
    'priority': task.priority.name,
    'tags': task.tags,
    'listId': task.listId,
    'createdAt': Timestamp.fromDate(task.createdAt),
    'updatedAt': Timestamp.fromDate(task.updatedAt),
  };
}

// ── TaskList ─────────────────────────────────────────────

/// Converts a Firestore document snapshot to a domain [TaskList].
///
/// The document ID is used as the task list ID.
domain.TaskList taskListFromFirestore(
  DocumentSnapshot<Map<String, dynamic>> doc,
) {
  final data = doc.data()!;
  return domain.TaskList(
    id: doc.id,
    name: data['name'] as String,
    colorHex: data['colorHex'] as String?,
    createdAt: (data['createdAt'] as Timestamp).toDate().toUtc(),
    updatedAt: (data['updatedAt'] as Timestamp).toDate().toUtc(),
  );
}

/// Converts a domain [TaskList] to a Firestore-compatible map.
Map<String, dynamic> taskListToFirestore(domain.TaskList list) {
  return {
    'name': list.name,
    'colorHex': list.colorHex,
    'createdAt': Timestamp.fromDate(list.createdAt),
    'updatedAt': Timestamp.fromDate(list.updatedAt),
  };
}

// ── Helpers ──────────────────────────────────────────────

Priority _parsePriority(String? value) {
  if (value == null) return Priority.none;
  return Priority.values.firstWhere(
    (p) => p.name == value,
    orElse: () => Priority.none,
  );
}
