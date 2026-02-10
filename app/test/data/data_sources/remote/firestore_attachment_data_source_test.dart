import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/data_sources/remote/firestore_attachment_data_source.dart';
import 'package:todo_flutter_app/domain/entities/attachment.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late FirestoreAttachmentDataSource dataSource;
  const userId = 'test-user-id';
  const taskId = 'test-task-id';

  setUp(() {
    firestore = FakeFirebaseFirestore();
    dataSource = FirestoreAttachmentDataSource(
      firestore: firestore,
      userId: userId,
    );
  });

  group('FirestoreAttachmentDataSource', () {
    group('getAttachmentsByTaskId', () {
      test('returns empty list when no attachments exist', () async {
        final result = await dataSource.getAttachmentsByTaskId(taskId);
        expect(result, isEmpty);
      });

      test('returns all attachments for a task ordered by createdAt', () async {
        // Arrange: Insert 3 attachments with different creation times
        final now = DateTime.now().toUtc();
        final att1 = Attachment(
          id: 'att-1',
          taskId: taskId,
          fileName: 'file1.txt',
          mimeType: 'text/plain',
          sizeBytes: 100,
          localPath: '/local/file1.txt',
          status: AttachmentStatus.uploaded,
          createdAt: now,
        );
        final att2 = Attachment(
          id: 'att-2',
          taskId: taskId,
          fileName: 'file2.txt',
          mimeType: 'text/plain',
          sizeBytes: 200,
          localPath: '/local/file2.txt',
          status: AttachmentStatus.pending,
          createdAt: now.add(const Duration(seconds: 1)),
        );
        final att3 = Attachment(
          id: 'att-3',
          taskId: taskId,
          fileName: 'file3.txt',
          mimeType: 'text/plain',
          sizeBytes: 300,
          localPath: '/local/file3.txt',
          status: AttachmentStatus.uploaded,
          remoteUrl: 'https://example.com/file3.txt',
          createdAt: now.add(const Duration(seconds: 2)),
        );

        // Add in non-sequential order
        await firestore
            .collection('users/$userId/tasks/$taskId/attachments')
            .doc(att2.id)
            .set({
              'taskId': att2.taskId,
              'fileName': att2.fileName,
              'mimeType': att2.mimeType,
              'sizeBytes': att2.sizeBytes,
              'localPath': att2.localPath,
              'remoteUrl': att2.remoteUrl,
              'status': att2.status.name,
              'createdAt': Timestamp.fromDate(att2.createdAt),
            });
        await firestore
            .collection('users/$userId/tasks/$taskId/attachments')
            .doc(att1.id)
            .set({
              'taskId': att1.taskId,
              'fileName': att1.fileName,
              'mimeType': att1.mimeType,
              'sizeBytes': att1.sizeBytes,
              'localPath': att1.localPath,
              'remoteUrl': att1.remoteUrl,
              'status': att1.status.name,
              'createdAt': Timestamp.fromDate(att1.createdAt),
            });
        await firestore
            .collection('users/$userId/tasks/$taskId/attachments')
            .doc(att3.id)
            .set({
              'taskId': att3.taskId,
              'fileName': att3.fileName,
              'mimeType': att3.mimeType,
              'sizeBytes': att3.sizeBytes,
              'localPath': att3.localPath,
              'remoteUrl': att3.remoteUrl,
              'status': att3.status.name,
              'createdAt': Timestamp.fromDate(att3.createdAt),
            });

        // Act
        final result = await dataSource.getAttachmentsByTaskId(taskId);

        // Assert: Should be ordered by createdAt (ascending)
        expect(result.length, 3);
        expect(result[0].id, 'att-1');
        expect(result[1].id, 'att-2');
        expect(result[2].id, 'att-3');
      });

      test('does not return attachments from other tasks', () async {
        // Arrange
        const otherTaskId = 'other-task-id';
        final now = DateTime.now().toUtc();
        await firestore
            .collection('users/$userId/tasks/$otherTaskId/attachments')
            .doc('att-other')
            .set({
              'taskId': otherTaskId,
              'fileName': 'other.txt',
              'mimeType': 'text/plain',
              'sizeBytes': 100,
              'localPath': '/local/other.txt',
              'status': AttachmentStatus.uploaded.name,
              'createdAt': Timestamp.fromDate(now),
            });

        // Act
        final result = await dataSource.getAttachmentsByTaskId(taskId);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getAttachmentById', () {
      test('returns attachment by ID', () async {
        // Arrange
        final now = DateTime.now().toUtc();
        const attachmentId = 'att-123';
        const remoteUrl = 'https://example.com/file.jpg';
        await firestore
            .collection('users/$userId/tasks/$taskId/attachments')
            .doc(attachmentId)
            .set({
              'taskId': taskId,
              'fileName': 'photo.jpg',
              'mimeType': 'image/jpeg',
              'sizeBytes': 5000,
              'localPath': '/local/photo.jpg',
              'remoteUrl': remoteUrl,
              'status': AttachmentStatus.uploaded.name,
              'createdAt': Timestamp.fromDate(now),
            });

        // Act
        final result = await dataSource.getAttachmentById(taskId, attachmentId);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, attachmentId);
        expect(result.fileName, 'photo.jpg');
        expect(result.mimeType, 'image/jpeg');
        expect(result.sizeBytes, 5000);
        expect(result.status, AttachmentStatus.uploaded);
        expect(result.remoteUrl, remoteUrl);
      });

      test('returns null when attachment does not exist', () async {
        // Act
        final result = await dataSource.getAttachmentById(
          taskId,
          'nonexistent',
        );

        // Assert
        expect(result, isNull);
      });

      test('uses correct task context', () async {
        // Arrange: Create attachment in different task
        const otherTaskId = 'other-task';
        const attachmentId = 'att-123';
        final now = DateTime.now().toUtc();
        await firestore
            .collection('users/$userId/tasks/$otherTaskId/attachments')
            .doc(attachmentId)
            .set({
              'taskId': otherTaskId,
              'fileName': 'other.jpg',
              'mimeType': 'image/jpeg',
              'sizeBytes': 5000,
              'localPath': '/local/other.jpg',
              'status': AttachmentStatus.uploaded.name,
              'createdAt': Timestamp.fromDate(now),
            });

        // Act
        final result = await dataSource.getAttachmentById(taskId, attachmentId);

        // Assert: Should not find it because it's in a different task
        expect(result, isNull);
      });
    });

    group('setAttachment', () {
      test('creates a new attachment document', () async {
        // Arrange
        final now = DateTime.now().toUtc();
        final attachment = Attachment(
          id: 'att-123',
          taskId: taskId,
          fileName: 'document.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 50000,
          localPath: '/local/document.pdf',
          status: AttachmentStatus.pending,
          createdAt: now,
        );

        // Act
        await dataSource.setAttachment(attachment);

        // Assert: Verify it was saved
        final doc = await firestore
            .collection('users/$userId/tasks/$taskId/attachments')
            .doc(attachment.id)
            .get();
        expect(doc.exists, true);
        expect(doc.data()!['fileName'], 'document.pdf');
        expect(doc.data()!['status'], AttachmentStatus.pending.name);
      });

      test('overwrites existing attachment', () async {
        // Arrange: Create initial attachment
        final now = DateTime.now().toUtc();
        final initial = Attachment(
          id: 'att-123',
          taskId: taskId,
          fileName: 'v1.txt',
          mimeType: 'text/plain',
          sizeBytes: 100,
          localPath: '/local/v1.txt',
          status: AttachmentStatus.pending,
          createdAt: now,
        );
        await dataSource.setAttachment(initial);

        // Act: Overwrite with updated version
        final updated = Attachment(
          id: 'att-123',
          taskId: taskId,
          fileName: 'v2.txt',
          mimeType: 'text/plain',
          sizeBytes: 200,
          localPath: '/local/v2.txt',
          remoteUrl: 'https://example.com/v2.txt',
          status: AttachmentStatus.uploaded,
          createdAt: now,
        );
        await dataSource.setAttachment(updated);

        // Assert
        final doc = await firestore
            .collection('users/$userId/tasks/$taskId/attachments')
            .doc('att-123')
            .get();
        expect(doc.data()!['fileName'], 'v2.txt');
        expect(doc.data()!['status'], AttachmentStatus.uploaded.name);
        expect(doc.data()!['remoteUrl'], 'https://example.com/v2.txt');
      });
    });

    group('updateAttachment', () {
      test('updates specific fields', () async {
        // Arrange: Create attachment
        final now = DateTime.now().toUtc();
        final attachment = Attachment(
          id: 'att-123',
          taskId: taskId,
          fileName: 'file.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 5000,
          localPath: '/local/file.jpg',
          status: AttachmentStatus.uploading,
          createdAt: now,
        );
        await dataSource.setAttachment(attachment);

        // Act: Update only status and remoteUrl
        const remoteUrl = 'https://example.com/file.jpg';
        await dataSource.updateAttachment(taskId, 'att-123', {
          'status': AttachmentStatus.uploaded.name,
          'remoteUrl': remoteUrl,
        });

        // Assert: Only those fields should be updated
        final doc = await firestore
            .collection('users/$userId/tasks/$taskId/attachments')
            .doc('att-123')
            .get();
        expect(doc.data()!['status'], AttachmentStatus.uploaded.name);
        expect(doc.data()!['remoteUrl'], remoteUrl);
        // Other fields remain unchanged
        expect(doc.data()!['fileName'], 'file.jpg');
        expect(doc.data()!['sizeBytes'], 5000);
      });

      test('throws error when document does not exist', () async {
        // Act & Assert: Firestore throws when updating nonexistent doc
        expect(
          () async => await dataSource.updateAttachment(taskId, 'nonexistent', {
            'status': 'uploaded',
          }),
          throwsA(isA<ServerError>()),
        );
      });
    });

    group('deleteAttachment', () {
      test('deletes an attachment document', () async {
        // Arrange: Create attachment
        final now = DateTime.now().toUtc();
        const attachmentId = 'att-to-delete';
        final attachment = Attachment(
          id: attachmentId,
          taskId: taskId,
          fileName: 'temp.txt',
          mimeType: 'text/plain',
          sizeBytes: 100,
          localPath: '/local/temp.txt',
          status: AttachmentStatus.failed,
          createdAt: now,
        );
        await dataSource.setAttachment(attachment);

        // Verify it exists
        var doc = await firestore
            .collection('users/$userId/tasks/$taskId/attachments')
            .doc(attachmentId)
            .get();
        expect(doc.exists, true);

        // Act
        await dataSource.deleteAttachment(taskId, attachmentId);

        // Assert: Document should be deleted
        doc = await firestore
            .collection('users/$userId/tasks/$taskId/attachments')
            .doc(attachmentId)
            .get();
        expect(doc.exists, false);
      });

      test('does not throw when deleting nonexistent attachment', () async {
        // Act & Assert: Should not throw
        await dataSource.deleteAttachment(taskId, 'nonexistent');
      });
    });
  });
}
