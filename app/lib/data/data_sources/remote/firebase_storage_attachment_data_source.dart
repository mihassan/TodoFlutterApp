import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Data source for uploading and managing attachments in Firebase Cloud Storage.
///
/// Handles file uploads to `users/{uid}/attachments/{attachmentId}` path.
/// Returns remote URLs for storage in metadata.
class FirebaseStorageAttachmentDataSource {
  FirebaseStorageAttachmentDataSource({FirebaseStorage? firebaseStorage})
    : _storage = firebaseStorage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  /// Uploads a file to Firebase Storage for the given user and attachment.
  ///
  /// Returns the download URL if successful.
  /// Throws a [FirebaseException] on failure.
  Future<String> uploadAttachment({
    required String userId,
    required String attachmentId,
    required File file,
    required String mimeType,
    void Function(int, int)? onProgress,
  }) async {
    final storagePath = 'users/$userId/attachments/$attachmentId';
    final storageRef = _storage.ref(storagePath);

    // Upload with optional progress callback
    if (onProgress != null) {
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: mimeType),
      );

      uploadTask.snapshotEvents.listen((snapshot) {
        onProgress(snapshot.bytesTransferred, snapshot.totalBytes);
      });

      await uploadTask;
    } else {
      await storageRef.putFile(file, SettableMetadata(contentType: mimeType));
    }

    // Return the download URL
    final downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl;
  }

  /// Gets the download URL for an existing attachment.
  ///
  /// Returns the URL if the file exists.
  /// Throws a [FirebaseException] if the file does not exist.
  Future<String> getDownloadUrl({
    required String userId,
    required String attachmentId,
  }) async {
    final storagePath = 'users/$userId/attachments/$attachmentId';
    final storageRef = _storage.ref(storagePath);
    return storageRef.getDownloadURL();
  }

  /// Deletes an attachment from Firebase Storage.
  ///
  /// Returns successfully even if the file does not exist.
  Future<void> deleteAttachment({
    required String userId,
    required String attachmentId,
  }) async {
    final storagePath = 'users/$userId/attachments/$attachmentId';
    final storageRef = _storage.ref(storagePath);
    try {
      await storageRef.delete();
    } catch (e) {
      // Ignore "file not found" errors; it's already deleted
      if (e is FirebaseException && e.code == 'object-not-found') {
        return;
      }
      rethrow;
    }
  }

  /// Gets metadata for an attachment (size, content type, etc.).
  ///
  /// Throws a [FirebaseException] if the file does not exist.
  Future<FullMetadata> getMetadata({
    required String userId,
    required String attachmentId,
  }) async {
    final storagePath = 'users/$userId/attachments/$attachmentId';
    final storageRef = _storage.ref(storagePath);
    return storageRef.getMetadata();
  }
}
