import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/data_sources/local/app_database.dart';
import 'package:todo_flutter_app/data/data_sources/local/local_attachment_data_source.dart';
import 'package:todo_flutter_app/data/data_sources/remote/firebase_storage_attachment_data_source.dart';
import 'package:todo_flutter_app/data/data_sources/remote/firestore_attachment_data_source.dart';
import 'package:todo_flutter_app/data/repositories/attachment_repository_impl.dart';
import 'package:todo_flutter_app/domain/entities/attachment.dart';

class MockFirebaseStorageAttachmentDataSource extends Mock
    implements FirebaseStorageAttachmentDataSource {}

class MockFirestoreAttachmentDataSource extends Mock
    implements FirestoreAttachmentDataSource {}

class FakeFile extends Fake implements File {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeFile());
    registerFallbackValue(
      Attachment(
        id: 'fallback',
        taskId: 'fallback',
        fileName: 'fallback.txt',
        mimeType: 'text/plain',
        sizeBytes: 0,
        localPath: '/fallback',
        createdAt: DateTime.now().toUtc(),
      ),
    );
    registerFallbackValue('');
    registerFallbackValue(<String, dynamic>{});
  });

  late AppDatabase db;
  late LocalAttachmentDataSource localDataSource;
  late MockFirebaseStorageAttachmentDataSource mockRemoteDataSource;
  late MockFirestoreAttachmentDataSource mockFirestoreDataSource;
  late AttachmentRepositoryImpl repository;

  const uid = 'user-123';
  const taskId = 'task-1';
  final now = DateTime.utc(2026, 2, 11, 12, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    localDataSource = LocalAttachmentDataSource(db);
    mockRemoteDataSource = MockFirebaseStorageAttachmentDataSource();
    mockFirestoreDataSource = MockFirestoreAttachmentDataSource();

    // Set up Firestore mock to return successful futures
    when(
      () => mockFirestoreDataSource.setAttachment(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockFirestoreDataSource.updateAttachment(any(), any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => mockFirestoreDataSource.deleteAttachment(any(), any()),
    ).thenAnswer((_) async {});

    repository = AttachmentRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: mockRemoteDataSource,
      firestoreDataSource: mockFirestoreDataSource,
      userId: uid,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Attachment makeAttachment({
    String id = 'attach-1',
    String taskId = taskId,
    String fileName = 'photo.jpg',
    String mimeType = 'image/jpeg',
    int sizeBytes = 1024,
    String localPath = '/local/path/photo.jpg',
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

  group('AttachmentRepositoryImpl — ', () {
    group('addAttachment — ', () {
      test('creates attachment with pending status locally', () async {
        // Act
        final (attachment, failure) = await repository.addAttachment(
          taskId: taskId,
          localFilePath: '/local/photo.jpg',
          fileName: 'photo.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 2048,
        );

        // Assert
        expect(failure, isNull);
        expect(attachment.status, AttachmentStatus.pending);
        expect(attachment.localPath, '/local/photo.jpg');
        expect(attachment.remoteUrl, isNull);

        // Verify saved locally
        final (found, _) = await repository.getAttachmentById(attachment.id);
        expect(found, isNotNull);
      });
    });

    group('syncUploads — ', () {
      test('completes with no pending attachments', () async {
        // Act
        final result = await repository.syncUploads();

        // Assert
        expect(result, isNull); // No error
      });

      test('uploads pending attachments with mock Firebase', () async {
        // Arrange
        final attachment = makeAttachment();
        await localDataSource.insertAttachment(attachment);

        // Mock the upload to return a URL
        when(
          () => mockRemoteDataSource.uploadAttachment(
            userId: uid,
            attachmentId: attachment.id,
            file: any(named: 'file'),
            mimeType: 'image/jpeg',
          ),
        ).thenAnswer(
          (_) async =>
              'https://storage.example.com/users/$uid/attachments/${attachment.id}',
        );

        // Create temporary file
        final file = File('/tmp/test_photo.jpg');
        file.createSync(recursive: true);
        file.writeAsBytesSync(Uint8List(100));

        // Update attachment with real file path
        final attachmentWithFile = attachment.copyWith(localPath: file.path);
        await localDataSource.updateAttachment(attachmentWithFile);

        // Act
        final result = await repository.syncUploads();

        // Assert
        expect(result, isNull);

        // Verify attachment was updated with remote URL
        final (updated, _) = await repository.getAttachmentById(attachment.id);
        expect(updated?.status, AttachmentStatus.uploaded);
        expect(updated?.remoteUrl, isNotNull);

        // Cleanup
        file.deleteSync();
      });

      test('marks failed attachments with failed status', () async {
        // Arrange
        final attachment = makeAttachment();
        await localDataSource.insertAttachment(attachment);

        // Mock upload to fail
        when(
          () => mockRemoteDataSource.uploadAttachment(
            userId: uid,
            attachmentId: attachment.id,
            file: any(named: 'file'),
            mimeType: 'image/jpeg',
          ),
        ).thenThrow(Exception('Upload failed'));

        // Create a file that exists but can't be uploaded
        final file = File('/tmp/test_photo_fail.jpg');
        file.createSync(recursive: true);

        final attachmentWithFile = attachment.copyWith(localPath: file.path);
        await localDataSource.updateAttachment(attachmentWithFile);

        // Act
        await repository.syncUploads();

        // Assert
        final (updated, _) = await repository.getAttachmentById(attachment.id);
        expect(updated?.status, AttachmentStatus.failed);

        // Cleanup
        file.deleteSync();
      });

      test('isUploading stream emits during sync', () async {
        // Arrange
        final attachment = makeAttachment();
        await localDataSource.insertAttachment(attachment);

        when(
          () => mockRemoteDataSource.uploadAttachment(
            userId: uid,
            attachmentId: attachment.id,
            file: any(named: 'file'),
            mimeType: 'image/jpeg',
          ),
        ).thenAnswer(
          (_) async =>
              'https://storage.example.com/users/$uid/attachments/${attachment.id}',
        );

        final file = File('/tmp/test_photo_stream.jpg');
        file.createSync(recursive: true);

        final attachmentWithFile = attachment.copyWith(localPath: file.path);
        await localDataSource.updateAttachment(attachmentWithFile);

        // Collect upload stream values
        final uploadingValues = <bool>[];
        final subscription = repository.isUploading.listen((value) {
          uploadingValues.add(value);
        });

        // Act
        await repository.syncUploads();

        // Give stream time to emit
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert: Should have emitted true and false
        expect(uploadingValues, contains(true));

        // Cleanup
        await subscription.cancel();
        file.deleteSync();
      });
    });

    group('deleteAttachment — ', () {
      test('removes attachment from local storage', () async {
        // Arrange
        final attachment = makeAttachment();
        await localDataSource.insertAttachment(attachment);

        // Act
        final failure = await repository.deleteAttachment(attachment.id);

        // Assert
        expect(failure, isNull);

        final (found, _) = await repository.getAttachmentById(attachment.id);
        expect(found, isNull);
      });

      test('returns NotFound for non-existent attachment', () async {
        // Act
        final failure = await repository.deleteAttachment('nonexistent');

        // Assert
        expect(failure, isA<NotFound>());
      });
    });
  });
}
