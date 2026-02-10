import 'package:drift/drift.dart';

import 'package:todo_flutter_app/domain/entities/attachment.dart' as domain;

import 'app_database.dart';
import 'mappers.dart';

/// Local data source for attachments backed by Drift (SQLite).
///
/// Manages attachment metadata in the local database. Actual file
/// storage and upload are handled by the repository layer.
class LocalAttachmentDataSource {
  LocalAttachmentDataSource(this._db);

  final AppDatabase _db;

  /// Returns all attachments for a given [taskId].
  Future<List<domain.Attachment>> getAttachmentsByTaskId(String taskId) async {
    final query = _db.select(_db.attachmentEntries)
      ..where((a) => a.taskId.equals(taskId));
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Returns a single attachment by [id], or `null` if not found.
  Future<domain.Attachment?> getAttachmentById(String id) async {
    final query = _db.select(_db.attachmentEntries)
      ..where((a) => a.id.equals(id));
    final row = await query.getSingleOrNull();
    return row?.toDomain();
  }

  /// Inserts a new attachment. Marks it as dirty for sync.
  Future<void> insertAttachment(domain.Attachment attachment) async {
    await _db.into(_db.attachmentEntries).insert(attachment.toCompanion());
  }

  /// Updates an existing attachment.
  Future<bool> updateAttachment(domain.Attachment attachment) async {
    final companion = AttachmentEntriesCompanion(
      fileName: Value(attachment.fileName),
      mimeType: Value(attachment.mimeType),
      sizeBytes: Value(attachment.sizeBytes),
      localPath: Value(attachment.localPath),
      remoteUrl: Value(attachment.remoteUrl),
      status: Value(attachment.status),
      isDirty: const Value(true),
    );
    final count = await (_db.update(
      _db.attachmentEntries,
    )..where((a) => a.id.equals(attachment.id))).write(companion);
    return count > 0;
  }

  /// Deletes an attachment by [id]. Returns `true` if a row was deleted.
  Future<bool> deleteAttachment(String id) async {
    final count = await (_db.delete(
      _db.attachmentEntries,
    )..where((a) => a.id.equals(id))).go();
    return count > 0;
  }

  /// Returns all attachments with [AttachmentStatus.pending] status.
  Future<List<domain.Attachment>> getPendingAttachments() async {
    final query = _db.select(_db.attachmentEntries)
      ..where((a) => a.status.equalsValue(domain.AttachmentStatus.pending));
    final rows = await query.get();
    return rows.map((row) => row.toDomain()).toList();
  }

  /// Marks an attachment as synced (not dirty) with the current timestamp.
  Future<void> markAttachmentSynced(String id) async {
    await (_db.update(
      _db.attachmentEntries,
    )..where((a) => a.id.equals(id))).write(
      AttachmentEntriesCompanion(
        isDirty: const Value(false),
        lastSyncedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
