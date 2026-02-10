import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:todo_flutter_app/data/data_sources/local/local_attachment_data_source.dart';
import 'package:todo_flutter_app/data/data_sources/remote/firebase_storage_attachment_data_source.dart';
import 'package:todo_flutter_app/data/data_sources/remote/firestore_attachment_data_source.dart';
import 'package:todo_flutter_app/data/repositories/attachment_repository_impl.dart';
import 'package:todo_flutter_app/domain/entities/attachment.dart';
import 'package:todo_flutter_app/domain/repositories/attachment_repository.dart';
import 'package:todo_flutter_app/features/auth/providers/auth_provider.dart';
import 'task_providers.dart';

final localAttachmentDataSourceProvider = Provider<LocalAttachmentDataSource>((
  ref,
) {
  return LocalAttachmentDataSource(ref.watch(appDatabaseProvider));
});

final firebaseStorageAttachmentDataSourceProvider =
    Provider<FirebaseStorageAttachmentDataSource>((ref) {
      return FirebaseStorageAttachmentDataSource(
        firebaseStorage: FirebaseStorage.instance,
      );
    });

final firestoreAttachmentDataSourceProvider =
    Provider.family<FirestoreAttachmentDataSource, String>((ref, userId) {
      return FirestoreAttachmentDataSource(
        firestore: FirebaseFirestore.instance,
        userId: userId,
      );
    });

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw StateError('No authenticated user for attachment repository.');
  }

  return AttachmentRepositoryImpl(
    localDataSource: ref.watch(localAttachmentDataSourceProvider),
    remoteDataSource: ref.watch(firebaseStorageAttachmentDataSourceProvider),
    firestoreDataSource: ref.watch(
      firestoreAttachmentDataSourceProvider(user.uid),
    ),
    userId: user.uid,
  );
});

/// Provides all attachments for a given task ID.
final attachmentsByTaskIdProvider =
    FutureProvider.family<List<Attachment>, String>((ref, taskId) async {
      final repository = ref.watch(attachmentRepositoryProvider);
      final (attachments, failure) = await repository.getAttachmentsByTaskId(
        taskId,
      );

      if (failure != null) {
        throw failure;
      }

      return attachments;
    });

/// Provides a single attachment by ID.
final attachmentByIdProvider = FutureProvider.family<Attachment?, String>((
  ref,
  attachmentId,
) async {
  final repository = ref.watch(attachmentRepositoryProvider);
  final (attachment, failure) = await repository.getAttachmentById(
    attachmentId,
  );

  if (failure != null) {
    throw failure;
  }

  return attachment;
});

/// Stream of upload status (true = uploading, false = idle).
final isUploadingProvider = StreamProvider<bool>((ref) {
  final repository = ref.watch(attachmentRepositoryProvider);
  return repository.isUploading;
});
