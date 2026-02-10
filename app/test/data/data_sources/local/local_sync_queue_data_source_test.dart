import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter_app/data/data_sources/local/app_database.dart';
import 'package:todo_flutter_app/data/data_sources/local/local_sync_queue_data_source.dart';

void main() {
  late AppDatabase db;
  late LocalSyncQueueDataSource dataSource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = LocalSyncQueueDataSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('LocalSyncQueueDataSource', () {
    test('getPendingEntries returns empty list when queue is empty', () async {
      final entries = await dataSource.getPendingEntries();
      expect(entries, isEmpty);
    });

    test('enqueue adds entry to queue', () async {
      await dataSource.enqueue(
        entityType: 'task',
        entityId: 'task-1',
        operation: 'create',
      );

      final entries = await dataSource.getPendingEntries();
      expect(entries, hasLength(1));
      expect(entries.first.entityType, 'task');
      expect(entries.first.entityId, 'task-1');
      expect(entries.first.operation, 'create');
      expect(entries.first.retryCount, 0);
    });

    test('entries are returned in FIFO order', () async {
      await dataSource.enqueue(
        entityType: 'task',
        entityId: 'task-1',
        operation: 'create',
      );
      await dataSource.enqueue(
        entityType: 'taskList',
        entityId: 'list-1',
        operation: 'update',
      );
      await dataSource.enqueue(
        entityType: 'task',
        entityId: 'task-2',
        operation: 'delete',
      );

      final entries = await dataSource.getPendingEntries();
      expect(entries, hasLength(3));
      expect(entries[0].entityId, 'task-1');
      expect(entries[1].entityId, 'list-1');
      expect(entries[2].entityId, 'task-2');
    });

    test('remove deletes entry from queue', () async {
      await dataSource.enqueue(
        entityType: 'task',
        entityId: 'task-1',
        operation: 'create',
      );
      final entries = await dataSource.getPendingEntries();
      final entryId = entries.first.id;

      await dataSource.remove(entryId);

      final remaining = await dataSource.getPendingEntries();
      expect(remaining, isEmpty);
    });

    test('incrementRetryCount increases count by 1', () async {
      await dataSource.enqueue(
        entityType: 'task',
        entityId: 'task-1',
        operation: 'create',
      );
      final entries = await dataSource.getPendingEntries();
      final entryId = entries.first.id;

      await dataSource.incrementRetryCount(entryId);

      final updated = await dataSource.getPendingEntries();
      expect(updated.first.retryCount, 1);

      await dataSource.incrementRetryCount(entryId);
      final updated2 = await dataSource.getPendingEntries();
      expect(updated2.first.retryCount, 2);
    });

    test('clear removes all entries', () async {
      await dataSource.enqueue(
        entityType: 'task',
        entityId: 'task-1',
        operation: 'create',
      );
      await dataSource.enqueue(
        entityType: 'task',
        entityId: 'task-2',
        operation: 'update',
      );

      await dataSource.clear();

      final entries = await dataSource.getPendingEntries();
      expect(entries, isEmpty);
    });

    test('count returns number of pending entries', () async {
      expect(await dataSource.count(), 0);

      await dataSource.enqueue(
        entityType: 'task',
        entityId: 'task-1',
        operation: 'create',
      );
      expect(await dataSource.count(), 1);

      await dataSource.enqueue(
        entityType: 'task',
        entityId: 'task-2',
        operation: 'create',
      );
      expect(await dataSource.count(), 2);
    });

    test('remove only deletes specified entry', () async {
      await dataSource.enqueue(
        entityType: 'task',
        entityId: 'task-1',
        operation: 'create',
      );
      await dataSource.enqueue(
        entityType: 'task',
        entityId: 'task-2',
        operation: 'update',
      );

      final entries = await dataSource.getPendingEntries();
      await dataSource.remove(entries.first.id);

      final remaining = await dataSource.getPendingEntries();
      expect(remaining, hasLength(1));
      expect(remaining.first.entityId, 'task-2');
    });
  });
}
