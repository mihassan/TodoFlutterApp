import 'package:flutter_test/flutter_test.dart';
import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/repositories/fake_attachment_repository.dart';
import 'package:todo_flutter_app/domain/entities/attachment.dart';
import 'package:todo_flutter_app/domain/repositories/attachment_repository.dart';

void main() {
  group('AttachmentRepository — ', () {
    late AttachmentRepository attachmentRepo;

    setUp(() {
      attachmentRepo = FakeAttachmentRepository();
    });

    group('get attachments by task id — ', () {
      test('returns empty list initially', () async {
        // Act
        final (attachments, failure) = await attachmentRepo
            .getAttachmentsByTaskId('task1');

        // Assert
        expect(failure, isNull);
        expect(attachments, isEmpty);
      });

      test('returns only attachments for the given task', () async {
        // Arrange
        await attachmentRepo.addAttachment(
          taskId: 'task1',
          localFilePath: '/path/to/file1.jpg',
          fileName: 'photo1.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1024,
        );

        await attachmentRepo.addAttachment(
          taskId: 'task2',
          localFilePath: '/path/to/file2.jpg',
          fileName: 'photo2.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 2048,
        );

        // Act
        final (attachments, failure) = await attachmentRepo
            .getAttachmentsByTaskId('task1');

        // Assert
        expect(failure, isNull);
        expect(attachments.length, 1);
        expect(attachments.first.fileName, 'photo1.jpg');
      });
    });

    group('add attachment — ', () {
      test('creates a new attachment with pending status', () async {
        // Act
        final (attachment, failure) = await attachmentRepo.addAttachment(
          taskId: 'task1',
          localFilePath: '/path/to/file.jpg',
          fileName: 'photo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1024,
        );

        // Assert
        expect(failure, isNull);
        expect(attachment.fileName, 'photo.jpg');
        expect(attachment.status, AttachmentStatus.pending);
        expect(attachment.localPath, '/path/to/file.jpg');
        expect(attachment.remoteUrl, isNull);
      });
    });

    group('get attachment by id — ', () {
      test('returns the attachment if found', () async {
        // Arrange
        final (added, _) = await attachmentRepo.addAttachment(
          taskId: 'task1',
          localFilePath: '/path/to/file.jpg',
          fileName: 'photo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1024,
        );

        // Act
        final (found, failure) = await attachmentRepo.getAttachmentById(
          added.id,
        );

        // Assert
        expect(failure, isNull);
        expect(found, isNotNull);
        expect(found!.fileName, 'photo.jpg');
      });

      test('returns null if not found', () async {
        // Act
        final (found, failure) = await attachmentRepo.getAttachmentById(
          'nonexistent',
        );

        // Assert
        expect(failure, isNull);
        expect(found, isNull);
      });
    });

    group('update attachment — ', () {
      test('updates an existing attachment', () async {
        // Arrange
        final (added, _) = await attachmentRepo.addAttachment(
          taskId: 'task1',
          localFilePath: '/path/to/file.jpg',
          fileName: 'photo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1024,
        );

        // Act
        final updated = added.copyWith(
          status: AttachmentStatus.uploaded,
          remoteUrl: 'https://example.com/photo.jpg',
        );

        final (result, failure) = await attachmentRepo.updateAttachment(
          updated,
        );

        // Assert
        expect(failure, isNull);
        expect(result.status, AttachmentStatus.uploaded);
        expect(result.remoteUrl, 'https://example.com/photo.jpg');
      });

      test('fails if attachment does not exist', () async {
        // Arrange
        final now = DateTime.now().toUtc();
        final phantom = Attachment(
          id: 'nonexistent',
          taskId: 'task1',
          fileName: 'ghost.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1024,
          localPath: '/path/to/ghost.jpg',
          createdAt: now,
        );

        // Act
        final (result, failure) = await attachmentRepo.updateAttachment(
          phantom,
        );

        // Assert
        expect(failure, isA<NotFound>());
      });
    });

    group('delete attachment — ', () {
      test('removes an attachment', () async {
        // Arrange
        final (added, _) = await attachmentRepo.addAttachment(
          taskId: 'task1',
          localFilePath: '/path/to/file.jpg',
          fileName: 'photo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1024,
        );

        // Act
        final failure = await attachmentRepo.deleteAttachment(added.id);

        // Assert
        expect(failure, isNull);

        final (found, _) = await attachmentRepo.getAttachmentById(added.id);
        expect(found, isNull);
      });

      test('fails if attachment does not exist', () async {
        // Act
        final failure = await attachmentRepo.deleteAttachment('nonexistent');

        // Assert
        expect(failure, isA<NotFound>());
      });
    });

    group('sync uploads — ', () {
      test('completes successfully', () async {
        // Arrange
        await attachmentRepo.addAttachment(
          taskId: 'task1',
          localFilePath: '/path/to/file.jpg',
          fileName: 'photo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1024,
        );

        // Act
        final failure = await attachmentRepo.syncUploads();

        // Assert
        expect(failure, isNull);
      });

      test('marks pending attachments as uploaded', () async {
        // Arrange
        final (added, _) = await attachmentRepo.addAttachment(
          taskId: 'task1',
          localFilePath: '/path/to/file.jpg',
          fileName: 'photo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 1024,
        );

        // Act
        await attachmentRepo.syncUploads();

        // Assert
        final (found, _) = await attachmentRepo.getAttachmentById(added.id);
        expect(found!.status, AttachmentStatus.uploaded);
        expect(found.remoteUrl, isNotNull);
      });

      test('is uploading stream emits true during sync', () async {
        // Arrange
        final states = <bool>[];
        attachmentRepo.isUploading.listen((state) {
          states.add(state);
        });

        // Act
        await attachmentRepo.syncUploads();

        // Allow async processing
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert: should have emitted [false, true, false]
        expect(states, contains(true));
      });
    });
  });
}
