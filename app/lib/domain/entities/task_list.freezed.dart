// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskList {

/// Unique identifier (UUID v4).
 String get id;/// Display name chosen by the user.
 String get name;/// Optional colour hex string (e.g. '#FF5733') for UI differentiation.
 String? get colorHex;/// When the list was created (UTC).
 DateTime get createdAt;/// When the list was last modified (UTC).
 DateTime get updatedAt;
/// Create a copy of TaskList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskListCopyWith<TaskList> get copyWith => _$TaskListCopyWithImpl<TaskList>(this as TaskList, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskList&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,colorHex,createdAt,updatedAt);

@override
String toString() {
  return 'TaskList(id: $id, name: $name, colorHex: $colorHex, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TaskListCopyWith<$Res>  {
  factory $TaskListCopyWith(TaskList value, $Res Function(TaskList) _then) = _$TaskListCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? colorHex, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$TaskListCopyWithImpl<$Res>
    implements $TaskListCopyWith<$Res> {
  _$TaskListCopyWithImpl(this._self, this._then);

  final TaskList _self;
  final $Res Function(TaskList) _then;

/// Create a copy of TaskList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? colorHex = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskList].
extension TaskListPatterns on TaskList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskList value)  $default,){
final _that = this;
switch (_that) {
case _TaskList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskList value)?  $default,){
final _that = this;
switch (_that) {
case _TaskList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? colorHex,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskList() when $default != null:
return $default(_that.id,_that.name,_that.colorHex,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? colorHex,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TaskList():
return $default(_that.id,_that.name,_that.colorHex,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? colorHex,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TaskList() when $default != null:
return $default(_that.id,_that.name,_that.colorHex,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _TaskList implements TaskList {
  const _TaskList({required this.id, required this.name, this.colorHex, required this.createdAt, required this.updatedAt});
  

/// Unique identifier (UUID v4).
@override final  String id;
/// Display name chosen by the user.
@override final  String name;
/// Optional colour hex string (e.g. '#FF5733') for UI differentiation.
@override final  String? colorHex;
/// When the list was created (UTC).
@override final  DateTime createdAt;
/// When the list was last modified (UTC).
@override final  DateTime updatedAt;

/// Create a copy of TaskList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskListCopyWith<_TaskList> get copyWith => __$TaskListCopyWithImpl<_TaskList>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskList&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.colorHex, colorHex) || other.colorHex == colorHex)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,colorHex,createdAt,updatedAt);

@override
String toString() {
  return 'TaskList(id: $id, name: $name, colorHex: $colorHex, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TaskListCopyWith<$Res> implements $TaskListCopyWith<$Res> {
  factory _$TaskListCopyWith(_TaskList value, $Res Function(_TaskList) _then) = __$TaskListCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? colorHex, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$TaskListCopyWithImpl<$Res>
    implements _$TaskListCopyWith<$Res> {
  __$TaskListCopyWithImpl(this._self, this._then);

  final _TaskList _self;
  final $Res Function(_TaskList) _then;

/// Create a copy of TaskList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? colorHex = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TaskList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,colorHex: freezed == colorHex ? _self.colorHex : colorHex // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
