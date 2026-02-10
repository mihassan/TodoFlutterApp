import 'package:drift/drift.dart';

import 'app_database.dart';

/// Local data source for the sync queue backed by Drift (SQLite).
///
/// The sync queue tracks local changes that need to be pushed to Firestore.
/// Each entry records the entity type, entity ID, and the operation performed.
/// The sync engine processes these in FIFO order.
class LocalSyncQueueDataSource {
  LocalSyncQueueDataSource(this._db);

  final AppDatabase _db;

  /// Returns all pending sync entries, ordered oldest-first (FIFO).
  Future<List<SyncQueueData>> getPendingEntries() async {
    final query = _db.select(_db.syncQueue)
      ..orderBy([(q) => OrderingTerm.asc(q.id)]);
    return query.get();
  }

  /// Enqueues a new sync operation.
  ///
  /// [entityType] is one of 'task', 'taskList', 'attachment'.
  /// [operation] is one of 'create', 'update', 'delete'.
  Future<void> enqueue({
    required String entityType,
    required String entityId,
    required String operation,
  }) async {
    await _db
        .into(_db.syncQueue)
        .insert(
          SyncQueueCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            operation: operation,
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  /// Removes a sync entry after successful remote write.
  Future<void> remove(int id) async {
    await (_db.delete(_db.syncQueue)..where((q) => q.id.equals(id))).go();
  }

  /// Increments the retry count for a failed sync entry.
  Future<void> incrementRetryCount(int id) async {
    await (_db.update(_db.syncQueue)..where((q) => q.id.equals(id))).write(
      SyncQueueCompanion.custom(
        retryCount: _db.syncQueue.retryCount + const Constant(1),
      ),
    );
  }

  /// Removes all entries from the sync queue (e.g., on sign-out).
  Future<void> clear() async {
    await _db.delete(_db.syncQueue).go();
  }

  /// Returns the number of pending sync entries.
  Future<int> count() async {
    final entries = await getPendingEntries();
    return entries.length;
  }
}
