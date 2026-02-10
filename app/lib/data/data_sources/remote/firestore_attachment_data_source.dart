import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:todo_flutter_app/core/failures.dart';
import 'package:todo_flutter_app/domain/entities/attachment.dart';
import 'firestore_mappers.dart';

/// Remote data source for attachment metadata in Firestore.
///
/// Manages attachment records under `users/{uid}/tasks/{taskId}/attachments/`.
/// This is separate from the file storage in Firebase Storage — the metadata
/// here is kept in sync with the file's lifecycle.
class FirestoreAttachmentDataSource {
  const FirestoreAttachmentDataSource({
    required FirebaseFirestore firestore,
    required String userId,
  }) : _firestore = firestore,
       _userId = userId;

  final FirebaseFirestore _firestore;
  final String _userId;

  // ── Collection path helpers ──────────────────────────────────────

  String _tasksPath() => 'users/$_userId/tasks';
  String _attachmentsPath(String taskId) =>
      '${_tasksPath()}/$taskId/attachments';

  // ── CRUD operations ─────────────────────────────────────────────

  /// Retrieves all attachments for a given task from Firestore.
  Future<List<Attachment>> getAttachmentsByTaskId(String taskId) async {
    try {
      final snapshot = await _firestore
          .collection(_attachmentsPath(taskId))
          .orderBy('createdAt', descending: false)
          .get();
      return snapshot.docs.map(attachmentFromFirestore).toList();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ServerError('Permission denied: ${e.message}');
      }
      throw ServerError('Failed to fetch attachments: ${e.message}');
    }
  }

  /// Retrieves a single attachment by ID from Firestore.
  ///
  /// Returns `null` if the attachment does not exist.
  Future<Attachment?> getAttachmentById(
    String taskId,
    String attachmentId,
  ) async {
    try {
      final doc = await _firestore
          .collection(_attachmentsPath(taskId))
          .doc(attachmentId)
          .get();
      if (!doc.exists) return null;
      return attachmentFromFirestore(doc);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ServerError('Permission denied: ${e.message}');
      }
      throw ServerError('Failed to fetch attachment: ${e.message}');
    }
  }

  /// Creates or overwrites an attachment record in Firestore.
  Future<void> setAttachment(Attachment attachment) async {
    try {
      await _firestore
          .collection(_attachmentsPath(attachment.taskId))
          .doc(attachment.id)
          .set(attachmentToFirestore(attachment));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ServerError('Permission denied: ${e.message}');
      }
      throw ServerError('Failed to save attachment: ${e.message}');
    }
  }

  /// Updates specific fields of an attachment record in Firestore.
  Future<void> updateAttachment(
    String taskId,
    String attachmentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _firestore
          .collection(_attachmentsPath(taskId))
          .doc(attachmentId)
          .update(updates);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ServerError('Permission denied: ${e.message}');
      }
      throw ServerError('Failed to update attachment: ${e.message}');
    }
  }

  /// Deletes an attachment record from Firestore.
  ///
  /// Note: This does NOT delete the actual file from Storage.
  /// See [FirebaseStorageAttachmentDataSource.deleteAttachment].
  Future<void> deleteAttachment(String taskId, String attachmentId) async {
    try {
      await _firestore
          .collection(_attachmentsPath(taskId))
          .doc(attachmentId)
          .delete();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw ServerError('Permission denied: ${e.message}');
      }
      throw ServerError('Failed to delete attachment: ${e.message}');
    }
  }
}
