import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:todo_flutter_app/data/data_sources/local/app_database.dart';
import 'package:todo_flutter_app/data/data_sources/local/local_sync_queue_data_source.dart';
import 'package:todo_flutter_app/data/data_sources/local/local_task_data_source.dart';
import 'package:todo_flutter_app/data/data_sources/remote/firestore_task_data_source.dart';
import 'package:todo_flutter_app/data/repositories/task_repository_impl.dart';
import 'package:todo_flutter_app/data/services/connectivity_service.dart';
import 'package:todo_flutter_app/domain/repositories/task_repository.dart';
import 'package:todo_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:todo_flutter_app/features/tasks/controllers/sync_controller.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final executor = LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'todo_app.sqlite'));
    return NativeDatabase(file);
  });

  final db = AppDatabase(executor);
  ref.onDispose(db.close);
  return db;
});

final localTaskDataSourceProvider = Provider<LocalTaskDataSource>((ref) {
  return LocalTaskDataSource(ref.watch(appDatabaseProvider));
});

final localSyncQueueDataSourceProvider = Provider<LocalSyncQueueDataSource>((
  ref,
) {
  return LocalSyncQueueDataSource(ref.watch(appDatabaseProvider));
});

final firestoreTaskDataSourceProvider = Provider<FirestoreTaskDataSource>((
  ref,
) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw StateError('No authenticated user for Firestore data source.');
  }

  return FirestoreTaskDataSource(
    firestore: FirebaseFirestore.instance,
    uid: user.uid,
  );
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepositoryImpl(
    localDataSource: ref.watch(localTaskDataSourceProvider),
    remoteDataSource: ref.watch(firestoreTaskDataSourceProvider),
    syncQueueDataSource: ref.watch(localSyncQueueDataSourceProvider),
  );
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncStatus>((ref) {
      final controller = SyncController(
        repository: ref.watch(taskRepositoryProvider),
        connectivityService: ref.watch(connectivityServiceProvider),
      );

      controller.start();
      return controller;
    });
