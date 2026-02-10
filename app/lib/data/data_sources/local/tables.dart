import 'package:drift/drift.dart';

import '../../../domain/entities/attachment.dart';
import '../../../domain/entities/priority.dart';

/// Drift table for [Task] entities.
///
/// Maps to the domain `Task` entity. Includes sync tracking fields
/// (`isDirty`, `lastSyncedAt`) for offline-first sync support.
class TaskEntries extends Table {
  /// Primary key — UUID v4 string.
  TextColumn get id => text()();

  /// Short title describing the task.
  TextColumn get title => text().withLength(min: 1, max: 500)();

  /// Optional longer description or notes.
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Whether the task has been completed.
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();

  /// Optional due date/time (stored as UTC millis).
  DateTimeColumn get dueAt => dateTime().nullable()();

  /// Task priority level (stored as text enum name).
  TextColumn get priority =>
      textEnum<Priority>().withDefault(Constant(Priority.none.name))();

  /// Comma-separated tags for categorisation.
  ///
  /// Stored as a single text field; converted to/from `List<String>` in
  /// the data source layer.
  TextColumn get tags => text().withDefault(const Constant(''))();

  /// Foreign key to the [TaskListEntries] table (null = Inbox).
  TextColumn get listId => text().nullable().references(TaskListEntries, #id)();

  /// When the task was created (UTC).
  DateTimeColumn get createdAt => dateTime()();

  /// When the task was last modified (UTC).
  DateTimeColumn get updatedAt => dateTime()();

  // ── Sync tracking ──────────────────────────────────────

  /// Whether this record has been modified locally since last sync.
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  /// When this record was last successfully synced (null = never synced).
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for [TaskList] entities.
class TaskListEntries extends Table {
  /// Primary key — UUID v4 string.
  TextColumn get id => text()();

  /// Display name chosen by the user.
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Optional colour hex string (e.g. '#FF5733').
  TextColumn get colorHex => text().nullable()();

  /// When the list was created (UTC).
  DateTimeColumn get createdAt => dateTime()();

  /// When the list was last modified (UTC).
  DateTimeColumn get updatedAt => dateTime()();

  // ── Sync tracking ──────────────────────────────────────

  /// Whether this record has been modified locally since last sync.
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  /// When this record was last successfully synced (null = never synced).
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for [Attachment] entities.
class AttachmentEntries extends Table {
  /// Primary key — UUID v4 string.
  TextColumn get id => text()();

  /// Foreign key to the [TaskEntries] table.
  TextColumn get taskId => text().references(TaskEntries, #id)();

  /// Original file name (e.g. 'photo.jpg').
  TextColumn get fileName => text()();

  /// MIME type (e.g. 'image/jpeg').
  TextColumn get mimeType => text()();

  /// File size in bytes.
  IntColumn get sizeBytes => integer()();

  /// Local file system path (available offline).
  TextColumn get localPath => text()();

  /// Remote download URL (null until uploaded).
  TextColumn get remoteUrl => text().nullable()();

  /// Current upload status (stored as text enum name).
  TextColumn get status => textEnum<AttachmentStatus>().withDefault(
    Constant(AttachmentStatus.pending.name),
  )();

  /// When the attachment was created (UTC).
  DateTimeColumn get createdAt => dateTime()();

  // ── Sync tracking ──────────────────────────────────────

  /// Whether this record has been modified locally since last sync.
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  /// When this record was last successfully synced (null = never synced).
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Sync queue table for tracking pending operations.
///
/// Each row represents a local change that needs to be pushed to Firestore.
/// The sync engine processes these in order, removing them after successful
/// remote writes.
class SyncQueue extends Table {
  /// Auto-incrementing ID for ordering.
  IntColumn get id => integer().autoIncrement()();

  /// The type of entity ('task', 'taskList', 'attachment').
  TextColumn get entityType => text()();

  /// The ID of the entity that changed.
  TextColumn get entityId => text()();

  /// The operation: 'create', 'update', or 'delete'.
  TextColumn get operation => text()();

  /// When this sync entry was created (UTC).
  DateTimeColumn get createdAt => dateTime()();

  /// Number of failed sync attempts (for retry-with-backoff).
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}
