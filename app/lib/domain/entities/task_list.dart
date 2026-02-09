import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_list.freezed.dart';

/// A named list that groups related [Task]s.
///
/// Every user has an implicit "Inbox" for un-categorised tasks (represented by
/// a null `listId` on the task). This entity represents explicit, user-created
/// lists such as "Work", "Shopping", etc.
@freezed
abstract class TaskList with _$TaskList {
  const factory TaskList({
    /// Unique identifier (UUID v4).
    required String id,

    /// Display name chosen by the user.
    required String name,

    /// Optional colour hex string (e.g. '#FF5733') for UI differentiation.
    String? colorHex,

    /// When the list was created (UTC).
    required DateTime createdAt,

    /// When the list was last modified (UTC).
    required DateTime updatedAt,
  }) = _TaskList;
}
