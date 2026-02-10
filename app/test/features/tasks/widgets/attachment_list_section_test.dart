import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/domain/entities/attachment.dart';
import 'package:todo_flutter_app/features/tasks/widgets/attachment_list_section.dart';

void main() {
  group('AttachmentListSection', () {
    testWidgets('displays empty state when no attachments', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AttachmentListSection(attachments: [])),
        ),
      );

      expect(find.text('No attachments'), findsOneWidget);
    });

    testWidgets('displays list of attachments', (tester) async {
      final attachments = [
        Attachment(
          id: 'att1',
          taskId: 'task1',
          fileName: 'file1.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 1024,
          localPath: '/tmp/file1.pdf',
          status: AttachmentStatus.uploaded,
          createdAt: DateTime.now(),
        ),
        Attachment(
          id: 'att2',
          taskId: 'task1',
          fileName: 'file2.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 2048,
          localPath: '/tmp/file2.jpg',
          status: AttachmentStatus.pending,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AttachmentListSection(attachments: attachments)),
        ),
      );

      expect(find.text('file1.pdf'), findsOneWidget);
      expect(find.text('file2.jpg'), findsOneWidget);
    });

    testWidgets('displays Attachments header', (tester) async {
      final attachments = [
        Attachment(
          id: 'att1',
          taskId: 'task1',
          fileName: 'file.txt',
          mimeType: 'text/plain',
          sizeBytes: 512,
          localPath: '/tmp/file.txt',
          status: AttachmentStatus.uploaded,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AttachmentListSection(attachments: attachments)),
        ),
      );

      expect(find.text('Attachments'), findsOneWidget);
    });

    testWidgets('calls onRetry when retry button tapped', (tester) async {
      String? retriedId;
      final attachments = [
        Attachment(
          id: 'att1',
          taskId: 'task1',
          fileName: 'failed.pdf',
          mimeType: 'application/pdf',
          sizeBytes: 1024,
          localPath: '/tmp/failed.pdf',
          status: AttachmentStatus.failed,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentListSection(
              attachments: attachments,
              onRetry: (id) => retriedId = id,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(retriedId, 'att1');
    });

    testWidgets('calls onDelete when delete button tapped', (tester) async {
      String? deletedId;
      final attachments = [
        Attachment(
          id: 'att1',
          taskId: 'task1',
          fileName: 'temp.txt',
          mimeType: 'text/plain',
          sizeBytes: 256,
          localPath: '/tmp/temp.txt',
          status: AttachmentStatus.uploaded,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AttachmentListSection(
              attachments: attachments,
              onDelete: (id) => deletedId = id,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(deletedId, 'att1');
    });
  });
}
