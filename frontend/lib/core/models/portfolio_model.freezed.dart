// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portfolio_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PortfolioItem _$PortfolioItemFromJson(Map<String, dynamic> json) {
  return _PortfolioItem.fromJson(json);
}

/// @nodoc
mixin _$PortfolioItem {
  String get id => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  int? get likesCount => throw _privateConstructorUsedError;

  /// Serializes this PortfolioItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PortfolioItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PortfolioItemCopyWith<PortfolioItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PortfolioItemCopyWith<$Res> {
  factory $PortfolioItemCopyWith(
          PortfolioItem value, $Res Function(PortfolioItem) then) =
      _$PortfolioItemCopyWithImpl<$Res, PortfolioItem>;
  @useResult
  $Res call(
      {String id,
      String imageUrl,
      String title,
      String category,
      DateTime? createdAt,
      int? likesCount});
}

/// @nodoc
class _$PortfolioItemCopyWithImpl<$Res, $Val extends PortfolioItem>
    implements $PortfolioItemCopyWith<$Res> {
  _$PortfolioItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PortfolioItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? imageUrl = null,
    Object? title = null,
    Object? category = null,
    Object? createdAt = freezed,
    Object? likesCount = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      likesCount: freezed == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PortfolioItemImplCopyWith<$Res>
    implements $PortfolioItemCopyWith<$Res> {
  factory _$$PortfolioItemImplCopyWith(
          _$PortfolioItemImpl value, $Res Function(_$PortfolioItemImpl) then) =
      __$$PortfolioItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String imageUrl,
      String title,
      String category,
      DateTime? createdAt,
      int? likesCount});
}

/// @nodoc
class __$$PortfolioItemImplCopyWithImpl<$Res>
    extends _$PortfolioItemCopyWithImpl<$Res, _$PortfolioItemImpl>
    implements _$$PortfolioItemImplCopyWith<$Res> {
  __$$PortfolioItemImplCopyWithImpl(
      _$PortfolioItemImpl _value, $Res Function(_$PortfolioItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of PortfolioItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? imageUrl = null,
    Object? title = null,
    Object? category = null,
    Object? createdAt = freezed,
    Object? likesCount = freezed,
  }) {
    return _then(_$PortfolioItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: null == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      likesCount: freezed == likesCount
          ? _value.likesCount
          : likesCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PortfolioItemImpl implements _PortfolioItem {
  const _$PortfolioItemImpl(
      {required this.id,
      required this.imageUrl,
      required this.title,
      required this.category,
      this.createdAt,
      this.likesCount});

  factory _$PortfolioItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PortfolioItemImplFromJson(json);

  @override
  final String id;
  @override
  final String imageUrl;
  @override
  final String title;
  @override
  final String category;
  @override
  final DateTime? createdAt;
  @override
  final int? likesCount;

  @override
  String toString() {
    return 'PortfolioItem(id: $id, imageUrl: $imageUrl, title: $title, category: $category, createdAt: $createdAt, likesCount: $likesCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PortfolioItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, imageUrl, title, category, createdAt, likesCount);

  /// Create a copy of PortfolioItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PortfolioItemImplCopyWith<_$PortfolioItemImpl> get copyWith =>
      __$$PortfolioItemImplCopyWithImpl<_$PortfolioItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PortfolioItemImplToJson(
      this,
    );
  }
}

abstract class _PortfolioItem implements PortfolioItem {
  const factory _PortfolioItem(
      {required final String id,
      required final String imageUrl,
      required final String title,
      required final String category,
      final DateTime? createdAt,
      final int? likesCount}) = _$PortfolioItemImpl;

  factory _PortfolioItem.fromJson(Map<String, dynamic> json) =
      _$PortfolioItemImpl.fromJson;

  @override
  String get id;
  @override
  String get imageUrl;
  @override
  String get title;
  @override
  String get category;
  @override
  DateTime? get createdAt;
  @override
  int? get likesCount;

  /// Create a copy of PortfolioItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PortfolioItemImplCopyWith<_$PortfolioItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
