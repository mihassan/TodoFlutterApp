import 'package:freezed_annotation/freezed_annotation.dart';

part 'attachment.freezed.dart';

/// The upload status of an [Attachment].
enum AttachmentStatus {
  /// Queued for upload but not yet started.
  pending,

  /// Currently uploading to remote storage.
  uploading,

  /// Successfully uploaded and available remotely.
  uploaded,

  /// Upload failed — eligible for retry.
  failed,
}

/// A file attached to a [Task].
///
/// Attachments are stored locally first (offline-first) and then synced to
/// Firebase Storage. The [status] field tracks the upload lifecycle.
@freezed
abstract class Attachment with _$Attachment {
  const factory Attachment({
    /// Unique identifier (UUID v4).
    required String id,

    /// ID of the [Task] this attachment belongs to.
    required String taskId,

    /// Original file name (e.g. 'photo.jpg').
    required String fileName,

    /// MIME type (e.g. 'image/jpeg').
    required String mimeType,

    /// File size in bytes.
    required int sizeBytes,

    /// Local file system path (available offline).
    required String localPath,

    /// Remote download URL (null until uploaded).
    String? remoteUrl,

    /// Current upload status.
    @Default(AttachmentStatus.pending) AttachmentStatus status,

    /// When the attachment was created (UTC).
    required DateTime createdAt,
  }) = _Attachment;
}
