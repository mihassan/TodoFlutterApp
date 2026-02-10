import 'package:drift/drift.dart';

import 'package:todo_flutter_app/domain/entities/attachment.dart';
import 'package:todo_flutter_app/domain/entities/priority.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// The Drift database for the Todo Flutter App.
///
/// Contains all local tables and exposes the generated query API.
/// Use [AppDatabase.memory] for in-memory testing.
@DriftDatabase(
  tables: [TaskEntries, TaskListEntries, AttachmentEntries, SyncQueue],
)
class AppDatabase extends _$AppDatabase {
  /// Creates a database backed by the given [QueryExecutor].
  ///
  /// In production, use `NativeDatabase` from `drift_flutter`.
  /// In tests, use `NativeDatabase.memory()`.
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
