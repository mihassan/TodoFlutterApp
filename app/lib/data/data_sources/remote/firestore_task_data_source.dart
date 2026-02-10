import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:todo_flutter_app/domain/entities/task.dart' as domain;
import 'package:todo_flutter_app/domain/entities/task_list.dart' as domain;

import 'firestore_mappers.dart';

/// Remote data source for tasks and task lists backed by Cloud Firestore.
///
/// All data is scoped under `users/{uid}/tasks/` and `users/{uid}/lists/`.
/// This class does NOT handle failure mapping — that's the repository's job.
class FirestoreTaskDataSource {
  FirestoreTaskDataSource({
    required FirebaseFirestore firestore,
    required String uid,
  }) : _firestore = firestore,
       _uid = uid;

  final FirebaseFirestore _firestore;
  final String _uid;

  /// Reference to the user's tasks collection.
  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection('users').doc(_uid).collection('tasks');

  /// Reference to the user's task lists collection.
  CollectionReference<Map<String, dynamic>> get _listsRef =>
      _firestore.collection('users').doc(_uid).collection('lists');

  // ── Task CRUD ──────────────────────────────────────────

  /// Returns all tasks for the current user.
  Future<List<domain.Task>> getTasks() async {
    final snapshot = await _tasksRef.get();
    return snapshot.docs.map(taskFromFirestore).toList();
  }

  /// Returns a single task by [id], or `null` if not found.
  Future<domain.Task?> getTaskById(String id) async {
    final doc = await _tasksRef.doc(id).get();
    if (!doc.exists) return null;
    return taskFromFirestore(doc);
  }

  /// Creates or overwrites a task document with the given task's ID.
  Future<void> setTask(domain.Task task) async {
    await _tasksRef.doc(task.id).set(taskToFirestore(task));
  }

  /// Updates specific fields of a task document.
  Future<void> updateTask(domain.Task task) async {
    await _tasksRef.doc(task.id).update(taskToFirestore(task));
  }

  /// Deletes a task by [id].
  Future<void> deleteTask(String id) async {
    await _tasksRef.doc(id).delete();
  }

  // ── TaskList CRUD ──────────────────────────────────────

  /// Returns all task lists for the current user.
  Future<List<domain.TaskList>> getTaskLists() async {
    final snapshot = await _listsRef.get();
    return snapshot.docs.map(taskListFromFirestore).toList();
  }

  /// Returns a single task list by [id], or `null` if not found.
  Future<domain.TaskList?> getTaskListById(String id) async {
    final doc = await _listsRef.doc(id).get();
    if (!doc.exists) return null;
    return taskListFromFirestore(doc);
  }

  /// Creates or overwrites a task list document with the given list's ID.
  Future<void> setTaskList(domain.TaskList list) async {
    await _listsRef.doc(list.id).set(taskListToFirestore(list));
  }

  /// Updates specific fields of a task list document.
  Future<void> updateTaskList(domain.TaskList list) async {
    await _listsRef.doc(list.id).update(taskListToFirestore(list));
  }

  /// Deletes a task list by [id].
  Future<void> deleteTaskList(String id) async {
    await _listsRef.doc(id).delete();
  }
}
