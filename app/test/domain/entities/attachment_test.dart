import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/domain/entities/attachment.dart';

void main() {
  final now = DateTime.utc(2026, 2, 9, 12, 0);

  Attachment createAttachment({
    String id = 'att-1',
    String taskId = 'task-1',
    String fileName = 'photo.jpg',
    String mimeType = 'image/jpeg',
    int sizeBytes = 1024,
    String localPath = '/data/attachments/photo.jpg',
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

  group('Attachment entity', () {
    test('creates with required fields and defaults', () {
      final attachment = createAttachment();

      expect(attachment.id, 'att-1');
      expect(attachment.taskId, 'task-1');
      expect(attachment.fileName, 'photo.jpg');
      expect(attachment.mimeType, 'image/jpeg');
      expect(attachment.sizeBytes, 1024);
      expect(attachment.localPath, '/data/attachments/photo.jpg');
      expect(attachment.remoteUrl, isNull);
      expect(attachment.status, AttachmentStatus.pending);
      expect(attachment.createdAt, now);
    });

    test('creates with remote URL and uploaded status', () {
      final attachment = createAttachment(
        remoteUrl: 'https://storage.example.com/photo.jpg',
        status: AttachmentStatus.uploaded,
      );

      expect(attachment.remoteUrl, 'https://storage.example.com/photo.jpg');
      expect(attachment.status, AttachmentStatus.uploaded);
    });

    test('supports value equality', () {
      final a1 = createAttachment();
      final a2 = createAttachment();

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
    });

    test('is not equal when fields differ', () {
      final a1 = createAttachment();
      final a2 = createAttachment(fileName: 'document.pdf');

      expect(a1, isNot(equals(a2)));
    });

    test('copyWith creates a modified copy', () {
      final attachment = createAttachment();
      final uploaded = attachment.copyWith(
        status: AttachmentStatus.uploaded,
        remoteUrl: 'https://storage.example.com/photo.jpg',
      );

      expect(uploaded.status, AttachmentStatus.uploaded);
      expect(uploaded.remoteUrl, 'https://storage.example.com/photo.jpg');
      expect(uploaded.id, attachment.id);
      expect(uploaded.fileName, attachment.fileName);
    });

    test('toString includes class name and fields', () {
      final attachment = createAttachment();

      expect(attachment.toString(), contains('Attachment'));
      expect(attachment.toString(), contains('photo.jpg'));
    });
  });

  group('AttachmentStatus enum', () {
    test('has four values', () {
      expect(AttachmentStatus.values.length, 4);
    });

    test('values represent upload lifecycle', () {
      expect(AttachmentStatus.values, [
        AttachmentStatus.pending,
        AttachmentStatus.uploading,
        AttachmentStatus.uploaded,
        AttachmentStatus.failed,
      ]);
    });
  });
}
