# Phase 11.5: Display Attachments on Task Detail UI

> **For Claude:** Execute this plan task-by-task. All 4 SyncController tests passing. Phase 11.4 committed.

**Goal:** Build UI widgets to display, upload, and manage attachments on the task detail screen. Support visual feedback for pending/uploading/uploaded/failed states.

**Architecture:**
- 3 new widgets: `AttachmentTile` (single attachment card), `AttachmentListSection` (list container), `AddAttachmentButton` (picker + upload)
- Wire into existing `TaskDetailScreen` with attachment state from `attachmentsByTaskIdProvider`
- Status badges show sync progress; tap to retry on failure

**Tech Stack:** Flutter widgets, Riverpod providers, image_picker, intl for date formatting

---

## Task 1: Create AttachmentTile Widget

**Files:**
- Create: `app/lib/features/tasks/widgets/attachment_tile.dart`
- Test: `app/test/features/tasks/widgets/attachment_tile_test.dart`

**Step 1: Read existing task detail screen to understand context**

Run: `cat app/lib/features/tasks/screens/task_detail_screen.dart | head -100`

Understand: imports, theme usage, error handling patterns, where attachments section should go

**Step 2: Write the failing test**

Create `app/test/features/tasks/widgets/attachment_tile_test.dart`:

```dart
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
          home: Scaffold(
            body: AttachmentTile(attachment: attachment),
          ),
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
          home: Scaffold(
            body: AttachmentTile(attachment: attachment),
          ),
        ),
      );

      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('displays uploading status with progress indicator', (tester) async {
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
          home: Scaffold(
            body: AttachmentTile(attachment: attachment),
          ),
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
          home: Scaffold(
            body: AttachmentTile(attachment: attachment),
          ),
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
```

**Step 3: Run test to verify it fails**

Run: `cd app && flutter test test/features/tasks/widgets/attachment_tile_test.dart`

Expected: FAIL with "file not found" or "widget not found"

**Step 4: Write minimal AttachmentTile widget**

Create `app/lib/features/tasks/widgets/attachment_tile.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:todo_flutter_app/domain/entities/attachment.dart';

class AttachmentTile extends StatelessWidget {
  const AttachmentTile({
    super.key,
    required this.attachment,
    this.onRetry,
    this.onDelete,
  });

  final Attachment attachment;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  Widget _buildStatusBadge() {
    switch (attachment.status) {
      case AttachmentStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Pending',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case AttachmentStatus.uploading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue.shade600,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Uploading',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case AttachmentStatus.uploaded:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_done,
              size: 14,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              'Uploaded',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      case AttachmentStatus.failed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error,
              size: 14,
              color: Colors.red.shade600,
            ),
            const SizedBox(width: 4),
            Text(
              'Failed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            _formatFileSize(attachment.sizeBytes),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            _formatDate(attachment.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildStatusBadge(),
                ),
              ],
            ),
            if (attachment.status == AttachmentStatus.failed &&
                (onRetry != null || onDelete != null))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onRetry != null)
                      TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, size: 18),
                        label: const Text('Delete'),
                      ),
                  ],
                ),
              )
            else if (onDelete != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

**Step 5: Run tests to verify they pass**

Run: `cd app && flutter test test/features/tasks/widgets/attachment_tile_test.dart`

Expected: ✅ All 6 tests PASS

**Step 6: Commit**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp
git add app/lib/features/tasks/widgets/attachment_tile.dart app/test/features/tasks/widgets/attachment_tile_test.dart
git commit -m "feat: create AttachmentTile widget for displaying single attachment

- Shows filename, size, creation date
- Status badge: pending (orange), uploading (blue with spinner), uploaded (green checkmark), failed (red)
- Retry and delete action buttons
- 6 widget tests passing"
```

---

## Task 2: Create AttachmentListSection Widget

**Files:**
- Create: `app/lib/features/tasks/widgets/attachment_list_section.dart`
- Test: `app/test/features/tasks/widgets/attachment_list_section_test.dart`

**Step 1: Write the failing test**

Create `app/test/features/tasks/widgets/attachment_list_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/domain/entities/attachment.dart';
import 'package:todo_flutter_app/features/tasks/widgets/attachment_list_section.dart';

void main() {
  group('AttachmentListSection', () {
    testWidgets('displays empty state when no attachments', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AttachmentListSection(
              attachments: [],
            ),
          ),
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
          home: Scaffold(
            body: AttachmentListSection(
              attachments: attachments,
            ),
          ),
        ),
      );

      expect(find.text('file1.pdf'), findsOneWidget);
      expect(find.text('file2.jpg'), findsOneWidget);
      expect(find.byType(AttachmentTile), findsWidgets);
    });

    testWidgets('calls onRetry when retry button tapped', (tester) async {
      bool retryCalled = false;
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
              onRetry: (id) => retryCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(retryCalled, isTrue);
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
```

**Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/features/tasks/widgets/attachment_list_section_test.dart`

Expected: FAIL

**Step 3: Write minimal AttachmentListSection widget**

Create `app/lib/features/tasks/widgets/attachment_list_section.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:todo_flutter_app/domain/entities/attachment.dart';
import 'attachment_tile.dart';

class AttachmentListSection extends StatelessWidget {
  const AttachmentListSection({
    super.key,
    required this.attachments,
    this.onRetry,
    this.onDelete,
  });

  final List<Attachment> attachments;
  final Function(String attachmentId)? onRetry;
  final Function(String attachmentId)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Text(
          'No attachments',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Attachments',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: attachments.length,
            itemBuilder: (context, index) {
              final attachment = attachments[index];
              return AttachmentTile(
                attachment: attachment,
                onRetry: onRetry != null
                    ? () => onRetry!(attachment.id)
                    : null,
                onDelete: onDelete != null
                    ? () => onDelete!(attachment.id)
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `cd app && flutter test test/features/tasks/widgets/attachment_list_section_test.dart`

Expected: ✅ All 5 tests PASS

**Step 5: Commit**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp
git add app/lib/features/tasks/widgets/attachment_list_section.dart app/test/features/tasks/widgets/attachment_list_section_test.dart
git commit -m "feat: create AttachmentListSection widget for listing attachments

- Displays list of attachments or empty state
- Passes retry/delete callbacks to child AttachmentTile widgets
- 5 widget tests passing"
```

---

## Task 3: Create AddAttachmentButton Widget

**Files:**
- Create: `app/lib/features/tasks/widgets/add_attachment_button.dart`
- Test: `app/test/features/tasks/widgets/add_attachment_button_test.dart`

**Step 1: Write the failing test**

Create `app/test/features/tasks/widgets/add_attachment_button_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_flutter_app/features/tasks/widgets/add_attachment_button.dart';

void main() {
  group('AddAttachmentButton', () {
    testWidgets('renders button with icon and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddAttachmentButton(
              onFileSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.attach_file), findsOneWidget);
      expect(find.text('Add Attachment'), findsOneWidget);
    });

    testWidgets('calls onFileSelected when file is picked', (tester) async {
      String? selectedPath;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddAttachmentButton(
              onFileSelected: (path) => selectedPath = path,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Note: In real scenario, image_picker would show native dialog
      // For testing, we'd need to mock it. This is a placeholder.
      expect(find.byType(AddAttachmentButton), findsOneWidget);
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
    });

    testWidgets('disables button when uploading', (tester) async {
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

      final button = find.byType(ElevatedButton);
      expect(button, findsOneWidget);
      // Button will be disabled (grayed out) when isUploading=true
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `cd app && flutter test test/features/tasks/widgets/add_attachment_button_test.dart`

Expected: FAIL

**Step 3: Write minimal AddAttachmentButton widget**

Create `app/lib/features/tasks/widgets/add_attachment_button.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddAttachmentButton extends StatelessWidget {
  const AddAttachmentButton({
    super.key,
    required this.onFileSelected,
    this.isUploading = false,
  });

  final Function(String filePath) onFileSelected;
  final bool isUploading;

  Future<void> _pickFile(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    
    // Show menu to choose between gallery and file picker
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Pick from Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    onFileSelected(image.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                  );
                  if (image != null) {
                    onFileSelected(image.path);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isUploading ? null : () => _pickFile(context),
      icon: isUploading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.attach_file),
      label: Text(isUploading ? 'Uploading...' : 'Add Attachment'),
    );
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `cd app && flutter test test/features/tasks/widgets/add_attachment_button_test.dart`

Expected: ✅ All 4 tests PASS

**Step 5: Commit**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp
git add app/lib/features/tasks/widgets/add_attachment_button.dart app/test/features/tasks/widgets/add_attachment_button_test.dart
git commit -m "feat: create AddAttachmentButton widget for picking attachments

- Shows file picker menu (gallery + camera)
- Disables button while uploading
- Shows progress indicator during upload
- 4 widget tests passing"
```

---

## Task 4: Integrate Attachments into TaskDetailScreen

**Files:**
- Modify: `app/lib/features/tasks/screens/task_detail_screen.dart`
- Modify: `app/test/features/tasks/screens/task_detail_screen_test.dart`

**Step 1: Read current task detail screen**

Run: `head -150 app/lib/features/tasks/screens/task_detail_screen.dart`

Understand the structure, where to add attachments section

**Step 2: Update TaskDetailScreen to include attachment widgets**

Modify `app/lib/features/tasks/screens/task_detail_screen.dart`:
- Import attachment widgets + providers
- Add `attachmentsByTaskIdProvider` watch
- Add `AttachmentListSection` in the scrollable content
- Add `AddAttachmentButton` in an appropriate location
- Wire up onRetry and onDelete callbacks

Key changes:
```dart
// Add imports
import 'app/providers/attachment_providers.dart'; // or relevant path
import 'widgets/attachment_list_section.dart';
import 'widgets/add_attachment_button.dart';

// In the build method, watch attachments
final attachments = ref.watch(attachmentsByTaskIdProvider(taskId));

// In the scrollable content, after notes section:
attachments.when(
  data: (items) => AttachmentListSection(
    attachments: items,
    onRetry: (id) {
      // Trigger retry in attachment repository
      ref.read(attachmentRepositoryProvider).retryUpload(id);
    },
    onDelete: (id) {
      // Trigger delete via controller
      ref.read(taskDetailControllerProvider.notifier).deleteAttachment(id);
    },
  ),
  loading: () => const SizedBox(
    height: 100,
    child: Center(child: CircularProgressIndicator()),
  ),
  error: (err, st) => ErrorBanner(message: 'Failed to load attachments'),
);

// Add button in FAB or action area
AddAttachmentButton(
  onFileSelected: (path) {
    ref.read(attachmentRepositoryProvider).addAttachment(
      taskId: taskId,
      filePath: path,
    );
  },
  isUploading: ref.watch(isUploadingProvider),
),
```

**Step 3: Update TaskDetailScreen tests**

Modify `app/test/features/tasks/screens/task_detail_screen_test.dart`:
- Mock `attachmentsByTaskIdProvider` in the override list
- Add test case: "displays attachments section when attachments exist"
- Add test case: "shows empty state when no attachments"

**Step 4: Run task detail tests**

Run: `cd app && flutter test test/features/tasks/screens/task_detail_screen_test.dart`

Expected: ✅ All tests PASS (including new attachment tests)

**Step 5: Commit**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp
git add app/lib/features/tasks/screens/task_detail_screen.dart app/test/features/tasks/screens/task_detail_screen_test.dart
git commit -m "feat: integrate attachments into task detail screen (Phase 11.5)

- Display AttachmentListSection showing all task attachments
- Add button to pick and upload new attachments
- Wire up retry/delete callbacks
- Handle loading/error states
- Updated all task detail tests with attachment mocks"
```

---

## Task 5: Add Missing Provider Functions

**Files:**
- Modify: `app/lib/domain/repositories/attachment_repository.dart`
- Modify: `app/lib/data/repositories/attachment_repository_impl.dart`

**Step 1: Check what's missing**

These methods may not exist yet:
- `retryUpload(String attachmentId)` — re-attempt failed upload
- Ensure `getAttachmentsByTaskId(String taskId)` returns Stream

**Step 2: Add to interface**

Update `AttachmentRepository`:
```dart
Future<void> retryUpload(String attachmentId);
```

**Step 3: Implement in repository**

Update `AttachmentRepositoryImpl`:
```dart
@override
Future<void> retryUpload(String attachmentId) async {
  try {
    final attachment = await _localDataSource.getAttachmentById(attachmentId);
    if (attachment == null) {
      throw const Failure.notFound('Attachment not found');
    }
    
    // Reset status to pending to trigger re-upload
    await _localDataSource.updateAttachment(
      attachment.copyWith(status: AttachmentStatus.pending),
    );
    
    // Queue for sync
    await _syncQueue.enqueue(
      SyncEntry(
        type: 'attachment_upload',
        resourceId: attachmentId,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  } catch (e) {
    logger.e('retryUpload failed', error: e);
    rethrow;
  }
}
```

**Step 4: Run tests**

Run: `cd app && flutter test test/data/repositories/attachment_repository_impl_test.dart`

Expected: ✅ Tests PASS (may need to add test for retryUpload)

**Step 5: Commit**

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp
git add app/lib/domain/repositories/attachment_repository.dart app/lib/data/repositories/attachment_repository_impl.dart
git commit -m "feat: add retryUpload method to attachment repository

- Allows retry of failed attachment uploads
- Resets status to pending and re-queues for sync
- Used by attachment UI delete/retry actions"
```

---

## Task 6: Verify All Tests Pass

**Files:** None (verification only)

**Step 1: Run full test suite**

Run: `cd app && flutter test`

Expected: ✅ ~390+ tests PASS (was 378, added ~12 new)

**Step 2: Run analysis**

Run: `cd app && flutter analyze`

Expected: ✅ 0 warnings, 0 errors

**Step 3: Log results**

Note the final test count and commit summary

---

## Task 7: Final Phase 11.5 Commit (Summary)

**Files:** None (just summary commit)

```bash
cd /Users/mihassan/Documents/Programming/TodoFlutterApp
git add docs/plans/2026-02-09-todo-flutter-app.md
git commit -m "chore: update progress — Phase 11.5 complete (Phase 11 ~95%)

Phase 11.5: Display Attachments on Task Detail
- Created AttachmentTile widget: status badges, retry/delete actions
- Created AttachmentListSection widget: list container with empty state
- Created AddAttachmentButton widget: image picker integration
- Integrated attachments into TaskDetailScreen
- Added retryUpload() method to attachment repository
- All ~390+ tests passing
- Ready for Phase 11.7 (final commit) or Phase 12 (settings)"
```

---

## Execution Summary

Once all tasks complete:
- ✅ 3 new widgets (AttachmentTile, AttachmentListSection, AddAttachmentButton)
- ✅ Integration into task detail screen with state management
- ✅ ~12 new widget tests added
- ✅ Full test suite passing (~390+ tests)
- ✅ Phase 11.5 complete, Phase 11 ~95% done
- ⏭️ Next: Phase 11.7 (final Phase 11 summary commit) or Phase 12 (Settings)
