import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/attachment.dart';
import 'package:todo_flutter_app/domain/repositories/attachment_repository.dart';

/// A fake implementation of [AttachmentRepository] for testing.
///
/// Stores attachments in memory. Does not upload to Firebase Storage.
/// Useful for unit tests and widget tests.
class FakeAttachmentRepository implements AttachmentRepository {
  /// Creates a [FakeAttachmentRepository].
  ///
  /// Optionally provide initial [attachments].
  FakeAttachmentRepository({List<Attachment>? attachments})
    : _attachments = attachments ?? [],
      _isUploadingNotifier = _UploadingNotifier();

  final List<Attachment> _attachments;
  final _UploadingNotifier _isUploadingNotifier;

  @override
  Future<(List<Attachment>, StorageFailure?)> getAttachmentsByTaskId(
    String taskId,
  ) async {
    final attachments = _attachments.where((a) => a.taskId == taskId).toList();
    return (attachments, null);
  }

  @override
  Future<(Attachment?, StorageFailure?)> getAttachmentById(
    String attachmentId,
  ) async {
    try {
      final attachment = _attachments.firstWhere((a) => a.id == attachmentId);
      return (attachment, null);
    } catch (e) {
      return (null, null); // Return null if not found
    }
  }

  @override
  Future<(Attachment, StorageFailure?)> addAttachment({
    required String taskId,
    required String localFilePath,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  }) async {
    final now = DateTime.now().toUtc();
    final attachment = Attachment(
      id: 'fake_attachment_${now.millisecondsSinceEpoch}',
      taskId: taskId,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      localPath: localFilePath,
      status: AttachmentStatus.pending,
      createdAt: now,
    );

    _attachments.add(attachment);
    return (attachment, null);
  }

  @override
  Future<(Attachment, StorageFailure?)> updateAttachment(
    Attachment attachment,
  ) async {
    final index = _attachments.indexWhere((a) => a.id == attachment.id);
    if (index == -1) {
      return (attachment, const NotFound());
    }
    _attachments[index] = attachment;
    return (attachment, null);
  }

  @override
  Future<StorageFailure?> deleteAttachment(String attachmentId) async {
    final index = _attachments.indexWhere((a) => a.id == attachmentId);
    if (index == -1) {
      return const NotFound();
    }
    _attachments.removeAt(index);
    return null;
  }

  @override
  Future<StorageFailure?> retryUpload(String attachmentId) async {
    final index = _attachments.indexWhere((a) => a.id == attachmentId);
    if (index == -1) {
      return const NotFound();
    }
    _attachments[index] = _attachments[index].copyWith(
      status: AttachmentStatus.pending,
    );
    return null;
  }

  @override
  Future<NetworkFailure?> syncUploads() async {
    _isUploadingNotifier.startUploading();
    await Future.delayed(const Duration(milliseconds: 100));

    // Mark all pending attachments as uploaded
    for (int i = 0; i < _attachments.length; i++) {
      if (_attachments[i].status == AttachmentStatus.pending) {
        _attachments[i] = _attachments[i].copyWith(
          status: AttachmentStatus.uploaded,
          remoteUrl: 'https://example.com/attachments/${_attachments[i].id}',
        );
      }
    }

    _isUploadingNotifier.endUploading();
    return null;
  }

  @override
  Stream<bool> get isUploading => _isUploadingNotifier.stream;
}

/// Helper notifier for upload status streaming.
class _UploadingNotifier {
  final List<void Function(bool)> _listeners = [];

  void startUploading() {
    _notifyListeners(true);
  }

  void endUploading() {
    _notifyListeners(false);
  }

  Stream<bool> get stream {
    return Stream.multi((controller) {
      // Emit initial state
      controller.add(false);

      void listener(bool isUploading) {
        controller.add(isUploading);
      }

      _listeners.add(listener);
      controller.onCancel = () {
        _listeners.remove(listener);
      };
    });
  }

  void _notifyListeners(bool isUploading) {
    for (final listener in _listeners) {
      listener(isUploading);
    }
  }
}
