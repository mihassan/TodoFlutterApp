import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/domain/entities/attachment.dart';
import 'package:todo_flutter_app/features/tasks/widgets/attachment_tile.dart';

void main() {
  group('AttachmentTile', () {
    testWidgets('displays filename and size', (tester) async {
      final attachment = Attachment(
        id: 'att1',
        taskId: 'task1',
        fileName: 'document.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 1024 * 500, // 500 KB
        localPath: '/tmp/document.pdf',
        status: AttachmentStatus.uploaded,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AttachmentTile(attachment: attachment)),
        ),
      );

      expect(find.text('document.pdf'), findsOneWidget);
      expect(find.text('500 KB'), findsOneWidget);
    });

    testWidgets('displays pending status badge', (tester) async {
      final attachment = Attachment(
        id: 'att1',
        taskId: 'task1',
        fileName: 'photo.jpg',
        mimeType: 'image/jpeg',
        sizeBytes: 2048 * 1024,
        localPath: '/tmp/photo.jpg',
        status: AttachmentStatus.pending,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AttachmentTile(attachment: attachment)),
        ),
      );

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('displays uploading status with progress indicator', (
      tester,
    ) async {
      final attachment = Attachment(
        id: 'att1',
        taskId: 'task1',
        fileName: 'video.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 50 * 1024 * 1024,
        localPath: '/tmp/video.mp4',
        status: AttachmentStatus.uploading,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AttachmentTile(attachment: attachment)),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Uploading'), findsOneWidget);
    });

    testWidgets('displays uploaded status', (tester) async {
      final attachment = Attachment(
        id: 'att1',
        taskId: 'task1',
        fileName: 'backup.zip',
        mimeType: 'application/zip',
        sizeBytes: 100 * 1024 * 1024,
        localPath: '/tmp/backup.zip',
        remoteUrl: 'https://firestore.googleapis.com/...',
        status: AttachmentStatus.uploaded,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AttachmentTile(attachment: attachment)),
        ),
      );

      expect(find.text('Uploaded'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('displays failed status with retry button', (tester) async {
      final attachment = Attachment(
        id: 'att1',
        taskId: 'task1',
        fileName: 'broken.doc',
        mimeType: 'application/msword',
        sizeBytes: 512 * 1024,
        localPath: '/tmp/broken.doc',
        status: AttachmentStatus.failed,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentTile(
              attachment: attachment,
              onRetry: () {},
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Failed'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('calls onDelete when delete button tapped', (tester) async {
      bool deleteCalled = false;
      final attachment = Attachment(
        id: 'att1',
        taskId: 'task1',
        fileName: 'test.txt',
        mimeType: 'text/plain',
        sizeBytes: 256,
        localPath: '/tmp/test.txt',
        status: AttachmentStatus.uploaded,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentTile(
              attachment: attachment,
              onDelete: () => deleteCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });
  });
}
