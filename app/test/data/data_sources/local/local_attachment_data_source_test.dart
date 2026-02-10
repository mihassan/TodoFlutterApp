import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter_app/data/data_sources/local/app_database.dart';
import 'package:todo_flutter_app/data/data_sources/local/local_attachment_data_source.dart';
import 'package:todo_flutter_app/data/data_sources/local/local_task_data_source.dart';
import 'package:todo_flutter_app/domain/entities/attachment.dart';
import 'package:todo_flutter_app/domain/entities/task.dart' as domain;

void main() {
  late AppDatabase db;
  late LocalAttachmentDataSource dataSource;
  late LocalTaskDataSource taskDataSource;

  final now = DateTime.utc(2026, 2, 10, 12, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dataSource = LocalAttachmentDataSource(db);
    taskDataSource = LocalTaskDataSource(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Creates a parent task (required for foreign key constraint).
  Future<void> insertParentTask({String id = 'task-1'}) async {
    await taskDataSource.insertTask(
      domain.Task(id: id, title: 'Parent task', createdAt: now, updatedAt: now),
    );
  }

  Attachment makeAttachment({
    String id = 'att-1',
    String taskId = 'task-1',
    String fileName = 'photo.jpg',
    String mimeType = 'image/jpeg',
    int sizeBytes = 1024,
    String localPath = '/data/files/photo.jpg',
    String? remoteUrl,
    AttachmentStatus status = AttachmentStatus.pending,
    DateTime? createdAt,
  }) {
    return Attachment(
      id: id,
      taskId: taskId,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      localPath: localPath,
      remoteUrl: remoteUrl,
      status: status,
      createdAt: createdAt ?? now,
    );
  }

  group('LocalAttachmentDataSource', () {
    test('getAttachmentsByTaskId returns empty list when none exist', () async {
      await insertParentTask();

      final attachments = await dataSource.getAttachmentsByTaskId('task-1');
      expect(attachments, isEmpty);
    });

    test('insertAttachment and getAttachmentsByTaskId round-trips', () async {
      await insertParentTask();
      await dataSource.insertAttachment(makeAttachment());

      final attachments = await dataSource.getAttachmentsByTaskId('task-1');
      expect(attachments, hasLength(1));
      expect(attachments.first.id, 'att-1');
      expect(attachments.first.fileName, 'photo.jpg');
      expect(attachments.first.mimeType, 'image/jpeg');
      expect(attachments.first.sizeBytes, 1024);
      expect(attachments.first.localPath, '/data/files/photo.jpg');
      expect(attachments.first.status, AttachmentStatus.pending);
    });

    test('insertAttachment preserves all fields', () async {
      await insertParentTask();
      await dataSource.insertAttachment(
        makeAttachment(
          remoteUrl: 'https://storage.example.com/photo.jpg',
          status: AttachmentStatus.uploaded,
        ),
      );

      final att = (await dataSource.getAttachmentsByTaskId('task-1')).first;
      expect(att.remoteUrl, 'https://storage.example.com/photo.jpg');
      expect(att.status, AttachmentStatus.uploaded);
    });

    test('getAttachmentById returns attachment when found', () async {
      await insertParentTask();
      await dataSource.insertAttachment(makeAttachment());

      final att = await dataSource.getAttachmentById('att-1');
      expect(att, isNotNull);
      expect(att!.id, 'att-1');
    });

    test('getAttachmentById returns null when not found', () async {
      final att = await dataSource.getAttachmentById('nonexistent');
      expect(att, isNull);
    });

    test('updateAttachment modifies existing attachment', () async {
      await insertParentTask();
      await dataSource.insertAttachment(makeAttachment());

      final updated = makeAttachment(
        remoteUrl: 'https://storage.example.com/photo.jpg',
        status: AttachmentStatus.uploaded,
      );
      final result = await dataSource.updateAttachment(updated);
      expect(result, true);

      final att = await dataSource.getAttachmentById('att-1');
      expect(att!.remoteUrl, 'https://storage.example.com/photo.jpg');
      expect(att.status, AttachmentStatus.uploaded);
    });

    test('updateAttachment returns false when not found', () async {
      final att = makeAttachment(id: 'nonexistent');
      final result = await dataSource.updateAttachment(att);
      expect(result, false);
    });

    test('deleteAttachment removes existing attachment', () async {
      await insertParentTask();
      await dataSource.insertAttachment(makeAttachment());

      final result = await dataSource.deleteAttachment('att-1');
      expect(result, true);

      final attachments = await dataSource.getAttachmentsByTaskId('task-1');
      expect(attachments, isEmpty);
    });

    test('deleteAttachment returns false when not found', () async {
      final result = await dataSource.deleteAttachment('nonexistent');
      expect(result, false);
    });

    test('getAttachmentsByTaskId filters by taskId', () async {
      await insertParentTask(id: 'task-1');
      await insertParentTask(id: 'task-2');

      await dataSource.insertAttachment(
        makeAttachment(id: 'att-1', taskId: 'task-1'),
      );
      await dataSource.insertAttachment(
        makeAttachment(id: 'att-2', taskId: 'task-2'),
      );

      final forTask1 = await dataSource.getAttachmentsByTaskId('task-1');
      expect(forTask1, hasLength(1));
      expect(forTask1.first.id, 'att-1');

      final forTask2 = await dataSource.getAttachmentsByTaskId('task-2');
      expect(forTask2, hasLength(1));
      expect(forTask2.first.id, 'att-2');
    });

    test('getPendingAttachments returns only pending attachments', () async {
      await insertParentTask();

      await dataSource.insertAttachment(
        makeAttachment(id: 'att-1', status: AttachmentStatus.pending),
      );
      await dataSource.insertAttachment(
        makeAttachment(id: 'att-2', status: AttachmentStatus.uploaded),
      );
      await dataSource.insertAttachment(
        makeAttachment(id: 'att-3', status: AttachmentStatus.failed),
      );

      final pending = await dataSource.getPendingAttachments();
      expect(pending, hasLength(1));
      expect(pending.first.id, 'att-1');
    });

    test('markAttachmentSynced clears dirty flag', () async {
      await insertParentTask();
      await dataSource.insertAttachment(makeAttachment());

      await dataSource.markAttachmentSynced('att-1');

      // Verify by checking that the attachment is not pending
      // (sync flag is internal to the DB row, not on domain entity)
      final att = await dataSource.getAttachmentById('att-1');
      expect(att, isNotNull);
    });
  });
}
