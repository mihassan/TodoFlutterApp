// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Task {

/// Unique identifier (UUID v4).
 String get id;/// Short title describing the task.
 String get title;/// Optional longer description or notes.
 String get notes;/// Whether the task has been completed.
 bool get isCompleted;/// Optional due date/time (UTC).
 DateTime? get dueAt;/// Task priority level.
 Priority get priority;/// Free-form tags for categorisation.
 List<String> get tags;/// ID of the [TaskList] this task belongs to (null = Inbox).
 String? get listId;/// When the task was created (UTC).
 DateTime get createdAt;/// When the task was last modified (UTC).
 DateTime get updatedAt;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,notes,isCompleted,dueAt,priority,const DeepCollectionEquality().hash(tags),listId,createdAt,updatedAt);

@override
String toString() {
  return 'Task(id: $id, title: $title, notes: $notes, isCompleted: $isCompleted, dueAt: $dueAt, priority: $priority, tags: $tags, listId: $listId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String title, String notes, bool isCompleted, DateTime? dueAt, Priority priority, List<String> tags, String? listId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? notes = null,Object? isCompleted = null,Object? dueAt = freezed,Object? priority = null,Object? tags = null,Object? listId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String notes,  bool isCompleted,  DateTime? dueAt,  Priority priority,  List<String> tags,  String? listId,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.title,_that.notes,_that.isCompleted,_that.dueAt,_that.priority,_that.tags,_that.listId,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String notes,  bool isCompleted,  DateTime? dueAt,  Priority priority,  List<String> tags,  String? listId,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.title,_that.notes,_that.isCompleted,_that.dueAt,_that.priority,_that.tags,_that.listId,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String notes,  bool isCompleted,  DateTime? dueAt,  Priority priority,  List<String> tags,  String? listId,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.title,_that.notes,_that.isCompleted,_that.dueAt,_that.priority,_that.tags,_that.listId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Task implements Task {
  const _Task({required this.id, required this.title, this.notes = '', this.isCompleted = false, this.dueAt, this.priority = Priority.none, final  List<String> tags = const [], this.listId, required this.createdAt, required this.updatedAt}): _tags = tags;
  

/// Unique identifier (UUID v4).
@override final  String id;
/// Short title describing the task.
@override final  String title;
/// Optional longer description or notes.
@override@JsonKey() final  String notes;
/// Whether the task has been completed.
@override@JsonKey() final  bool isCompleted;
/// Optional due date/time (UTC).
@override final  DateTime? dueAt;
/// Task priority level.
@override@JsonKey() final  Priority priority;
/// Free-form tags for categorisation.
 final  List<String> _tags;
/// Free-form tags for categorisation.
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// ID of the [TaskList] this task belongs to (null = Inbox).
@override final  String? listId;
/// When the task was created (UTC).
@override final  DateTime createdAt;
/// When the task was last modified (UTC).
@override final  DateTime updatedAt;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.dueAt, dueAt) || other.dueAt == dueAt)&&(identical(other.priority, priority) || other.priority == priority)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,notes,isCompleted,dueAt,priority,const DeepCollectionEquality().hash(_tags),listId,createdAt,updatedAt);

@override
String toString() {
  return 'Task(id: $id, title: $title, notes: $notes, isCompleted: $isCompleted, dueAt: $dueAt, priority: $priority, tags: $tags, listId: $listId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String notes, bool isCompleted, DateTime? dueAt, Priority priority, List<String> tags, String? listId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? notes = null,Object? isCompleted = null,Object? dueAt = freezed,Object? priority = null,Object? tags = null,Object? listId = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: null == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,dueAt: freezed == dueAt ? _self.dueAt : dueAt // ignore: cast_nullable_to_non_nullable
as DateTime?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as Priority,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
