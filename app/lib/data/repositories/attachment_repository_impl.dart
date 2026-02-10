import 'dart:async';
import 'dart:io';

import 'package:uuid/uuid.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/data/data_sources/local/local_attachment_data_source.dart';
import 'package:todo_flutter_app/data/data_sources/remote/firebase_storage_attachment_data_source.dart';
import 'package:todo_flutter_app/data/data_sources/remote/firestore_attachment_data_source.dart';
import 'package:todo_flutter_app/domain/entities/attachment.dart';
import 'package:todo_flutter_app/domain/repositories/attachment_repository.dart';

/// Production implementation of [AttachmentRepository].
///
/// Follows an offline-first pattern for file attachments:
/// - Adds files locally first (status = pending)
/// - Enqueues upload in background via [syncUploads]
/// - Syncs with Firebase Storage and updates remote URLs
/// - Persists attachment metadata to Firestore for cross-device sync
/// - Returns failures mapped to [StorageFailure] subclasses
class AttachmentRepositoryImpl implements AttachmentRepository {
  AttachmentRepositoryImpl({
    required LocalAttachmentDataSource localDataSource,
    required FirebaseStorageAttachmentDataSource remoteDataSource,
    required FirestoreAttachmentDataSource firestoreDataSource,
    required String userId,
  }) : _local = localDataSource,
       _remote = remoteDataSource,
       _firestore = firestoreDataSource,
       _userId = userId;

  final LocalAttachmentDataSource _local;
  final FirebaseStorageAttachmentDataSource _remote;
  final FirestoreAttachmentDataSource _firestore;
  final String _userId;

  final _uploadingController = StreamController<bool>.broadcast();
  bool _isUploadingNow = false;

  // ── Attachment CRUD (local-first) ────────────────────────────

  @override
  Future<(List<Attachment>, StorageFailure?)> getAttachmentsByTaskId(
    String taskId,
  ) async {
    try {
      final attachments = await _local.getAttachmentsByTaskId(taskId);
      return (attachments, null);
    } catch (e) {
      return (const <Attachment>[], DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<(Attachment?, StorageFailure?)> getAttachmentById(
    String attachmentId,
  ) async {
    try {
      final attachment = await _local.getAttachmentById(attachmentId);
      return (attachment, null);
    } catch (e) {
      return (null, DatabaseFailure(e.toString()));
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
    try {
      final attachmentId = const Uuid().v4();
      final now = DateTime.now().toUtc();

      final attachment = Attachment(
        id: attachmentId,
        taskId: taskId,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        localPath: localFilePath,
        status: AttachmentStatus.pending,
        createdAt: now,
      );

      // Save locally (offline-first)
      await _local.insertAttachment(attachment);

      // Save metadata to Firestore immediately (fire-and-forget)
      // Allows other devices to see the pending attachment
      unawaited(
        _firestore.setAttachment(attachment).catchError((e) {
          // Ignore errors — local DB is the source of truth
        }),
      );

      return (attachment, null);
    } catch (e) {
      return (
        Attachment(
          id: 'error',
          taskId: taskId,
          fileName: fileName,
          mimeType: mimeType,
          sizeBytes: sizeBytes,
          localPath: localFilePath,
          status: AttachmentStatus.pending,
          createdAt: DateTime.now().toUtc(),
        ),
        DatabaseFailure('Failed to save attachment: $e'),
      );
    }
  }

  @override
  Future<(Attachment, StorageFailure?)> updateAttachment(
    Attachment attachment,
  ) async {
    try {
      final updated = await _local.updateAttachment(attachment);
      if (!updated) {
        return (attachment, const NotFound('Attachment not found.'));
      }
      return (attachment, null);
    } catch (e) {
      return (attachment, DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<StorageFailure?> deleteAttachment(String attachmentId) async {
    try {
      // Get attachment to find remote URL for deletion and get taskId
      final (attachment, error) = await getAttachmentById(attachmentId);
      if (error != null) {
        return error;
      }

      // Delete from local DB
      final deleted = await _local.deleteAttachment(attachmentId);
      if (!deleted) {
        return const NotFound('Attachment not found.');
      }

      // Delete from Firestore (fire-and-forget)
      if (attachment != null) {
        unawaited(
          _firestore
              .deleteAttachment(attachment.taskId, attachmentId)
              .catchError((e) {
                // Ignore errors
              }),
        );
      }

      // Delete from remote storage (fire-and-forget, don't block on failure)
      if (attachment != null && attachment.remoteUrl != null) {
        unawaited(
          _remote
              .deleteAttachment(userId: _userId, attachmentId: attachmentId)
              .catchError((e) {
                // Ignore errors
              }),
        );
      }

      return null;
    } catch (e) {
      return DatabaseFailure(e.toString());
    }
  }

  @override
  Future<NetworkFailure?> syncUploads() async {
    if (_isUploadingNow) {
      return null;
    }

    _isUploadingNow = true;
    _uploadingController.add(true);

    try {
      // Get all pending attachments
      final pendingAttachments = await _local.getPendingAttachments();

      if (pendingAttachments.isEmpty) {
        _isUploadingNow = false;
        _uploadingController.add(false);
        return null;
      }

      // Upload each pending attachment
      for (final attachment in pendingAttachments) {
        try {
          await _uploadAttachment(attachment);
        } catch (e) {
          // Mark as failed, but continue with next attachments
          final failed = attachment.copyWith(status: AttachmentStatus.failed);
          await _local.updateAttachment(failed);
        }
      }

      _isUploadingNow = false;
      _uploadingController.add(false);
      return null;
    } catch (e) {
      _isUploadingNow = false;
      _uploadingController.add(false);
      return ServerError(e.toString());
    }
  }

  /// Uploads a single attachment to Firebase Storage.
  ///
  /// Updates the attachment status and remote URL in local DB on success.
  /// Also saves metadata to Firestore for cross-device sync.
  /// Throws an exception on failure.
  Future<void> _uploadAttachment(Attachment attachment) async {
    // Update status to uploading
    var uploading = attachment.copyWith(status: AttachmentStatus.uploading);
    await _local.updateAttachment(uploading);

    try {
      // Upload to Firebase Storage
      final file = File(attachment.localPath);
      if (!file.existsSync()) {
        throw FileSystemException('File not found', attachment.localPath);
      }

      final remoteUrl = await _remote.uploadAttachment(
        userId: _userId,
        attachmentId: attachment.id,
        file: file,
        mimeType: attachment.mimeType,
      );

      // Mark as uploaded with remote URL
      final uploaded = attachment.copyWith(
        status: AttachmentStatus.uploaded,
        remoteUrl: remoteUrl,
      );
      await _local.updateAttachment(uploaded);

      // Save metadata to Firestore for cross-device sync
      // (fire-and-forget, don't block on Firestore write failure)
      unawaited(
        _firestore.setAttachment(uploaded).catchError((e) {
          // Log error but don't propagate — file is already uploaded
          // and stored locally
        }),
      );

      await _local.markAttachmentSynced(attachment.id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Stream<bool> get isUploading {
    return _uploadingController.stream.distinct();
  }

  /// Disposes the controller (call when repository is destroyed).
  void dispose() {
    _uploadingController.close();
  }
}
