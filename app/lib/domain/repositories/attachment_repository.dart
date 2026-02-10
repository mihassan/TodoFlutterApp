import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/attachment.dart';

/// Repository interface for attachment (file) management.
///
/// Abstracts away local storage and Firebase Storage.
/// Handles the lifecycle of file uploads in an offline-first manner.
///
/// Implementations must:
/// - Store files locally in app-scoped storage first
/// - Enqueue uploads to Firebase Storage in the background
/// - Map storage/network exceptions to [AppFailure] subclasses
/// - Track upload progress and failure status
/// - Never throw exceptions; always return failures or success values
abstract interface class AttachmentRepository {
  /// Returns all attachments for a given task.
  ///
  /// Reads from local DB; does not make network requests.
  /// Returns an empty list if the task has no attachments.
  Future<(List<Attachment>, StorageFailure?)> getAttachmentsByTaskId(
    String taskId,
  );

  /// Returns a single attachment by ID.
  ///
  /// Returns `null` if the attachment does not exist.
  Future<(Attachment?, StorageFailure?)> getAttachmentById(String attachmentId);

  /// Saves an attachment file locally and queues it for remote upload.
  ///
  /// Given the file path on disk, creates an [Attachment] record
  /// in local DB with [AttachmentStatus.pending], then enqueues
  /// an upload task to Firebase Storage.
  ///
  /// Returns the created [Attachment] with pending status, or a
  /// [StorageFailure] if the local save or queueing fails.
  ///
  /// Does NOT block until upload completes — use [isSyncing] or
  /// periodic polls to [getAttachmentById] to track progress.
  Future<(Attachment, StorageFailure?)> addAttachment({
    required String taskId,
    required String localFilePath,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
  });

  /// Updates an attachment record (e.g., after successful upload).
  ///
  /// Typically called by the sync engine after a successful remote upload.
  /// Returns the updated [Attachment], or a [StorageFailure] if not found.
  Future<(Attachment, StorageFailure?)> updateAttachment(Attachment attachment);

  /// Deletes an attachment from local DB and queues deletion from Storage.
  ///
  /// Returns `null` on success, or a [StorageFailure] if not found or fails.
  Future<StorageFailure?> deleteAttachment(String attachmentId);

  /// Synchronizes pending attachments with Firebase Storage.
  ///
  /// Uploads any attachments with [AttachmentStatus.pending] to Storage,
  /// updates their [remoteUrl] and [status] in local DB.
  /// Uses retry-with-backoff for failed uploads.
  ///
  /// Returns `null` on success (even if some uploads failed individually),
  /// or a [NetworkFailure] for critical sync errors.
  ///
  /// Automatically called by the app's main sync engine.
  Future<NetworkFailure?> syncUploads();

  /// Returns the current upload sync status.
  ///
  /// Useful for displaying a "uploading..." indicator.
  /// Emits `true` when an upload is in progress.
  Stream<bool> get isUploading;
}
