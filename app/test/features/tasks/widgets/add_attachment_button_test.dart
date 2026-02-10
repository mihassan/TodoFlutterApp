import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/features/tasks/widgets/add_attachment_button.dart';

void main() {
  group('AddAttachmentButton', () {
    testWidgets('renders button with icon and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AddAttachmentButton(onFileSelected: (_) {})),
        ),
      );

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
      expect(find.text('Add Attachment'), findsOneWidget);
    });

    testWidgets('shows loading state when uploading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddAttachmentButton(
              onFileSelected: (_) {},
              isUploading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Uploading...'), findsOneWidget);
    });

    testWidgets('hides attach icon when uploading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddAttachmentButton(
              onFileSelected: (_) {},
              isUploading: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.attach_file), findsNothing);
    });

    testWidgets('shows attach icon when not uploading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddAttachmentButton(
              onFileSelected: (_) {},
              isUploading: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
      expect(find.text('Add Attachment'), findsOneWidget);
    });
  });
}
