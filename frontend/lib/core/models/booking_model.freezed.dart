// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'booking_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Booking _$BookingFromJson(Map<String, dynamic> json) {
  return _Booking.fromJson(json);
}

/// @nodoc
mixin _$Booking {
  String get id => throw _privateConstructorUsedError;
  String get clientName => throw _privateConstructorUsedError;
  String get clientId => throw _privateConstructorUsedError;
  String get serviceName => throw _privateConstructorUsedError;
  String get serviceId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get scheduledAt => throw _privateConstructorUsedError;
  String get serviceAddress => throw _privateConstructorUsedError;
  double get totalAmount => throw _privateConstructorUsedError;
  double? get providerNetAmount => throw _privateConstructorUsedError;
  double? get platformCommission => throw _privateConstructorUsedError;
  double? get stateTax => throw _privateConstructorUsedError;
  String? get wompiReference => throw _privateConstructorUsedError;
  String? get nequiAccount => throw _privateConstructorUsedError;
  String? get payoutStatus => throw _privateConstructorUsedError;
  int? get rating => throw _privateConstructorUsedError;
  String? get clientAvatar => throw _privateConstructorUsedError;

  /// Serializes this Booking to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookingCopyWith<Booking> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookingCopyWith<$Res> {
  factory $BookingCopyWith(Booking value, $Res Function(Booking) then) =
      _$BookingCopyWithImpl<$Res, Booking>;
  @useResult
  $Res call(
      {String id,
      String clientName,
      String clientId,
      String serviceName,
      String serviceId,
      String status,
      DateTime scheduledAt,
      String serviceAddress,
      double totalAmount,
      double? providerNetAmount,
      double? platformCommission,
      double? stateTax,
      String? wompiReference,
      String? nequiAccount,
      String? payoutStatus,
      int? rating,
      String? clientAvatar});
}

/// @nodoc
class _$BookingCopyWithImpl<$Res, $Val extends Booking>
    implements $BookingCopyWith<$Res> {
  _$BookingCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientName = null,
    Object? clientId = null,
    Object? serviceName = null,
    Object? serviceId = null,
    Object? status = null,
    Object? scheduledAt = null,
    Object? serviceAddress = null,
    Object? totalAmount = null,
    Object? providerNetAmount = freezed,
    Object? platformCommission = freezed,
    Object? stateTax = freezed,
    Object? wompiReference = freezed,
    Object? nequiAccount = freezed,
    Object? payoutStatus = freezed,
    Object? rating = freezed,
    Object? clientAvatar = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clientName: null == clientName
          ? _value.clientName
          : clientName // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      serviceName: null == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      serviceId: null == serviceId
          ? _value.serviceId
          : serviceId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      scheduledAt: null == scheduledAt
          ? _value.scheduledAt
          : scheduledAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      serviceAddress: null == serviceAddress
          ? _value.serviceAddress
          : serviceAddress // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      providerNetAmount: freezed == providerNetAmount
          ? _value.providerNetAmount
          : providerNetAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      platformCommission: freezed == platformCommission
          ? _value.platformCommission
          : platformCommission // ignore: cast_nullable_to_non_nullable
              as double?,
      stateTax: freezed == stateTax
          ? _value.stateTax
          : stateTax // ignore: cast_nullable_to_non_nullable
              as double?,
      wompiReference: freezed == wompiReference
          ? _value.wompiReference
          : wompiReference // ignore: cast_nullable_to_non_nullable
              as String?,
      nequiAccount: freezed == nequiAccount
          ? _value.nequiAccount
          : nequiAccount // ignore: cast_nullable_to_non_nullable
              as String?,
      payoutStatus: freezed == payoutStatus
          ? _value.payoutStatus
          : payoutStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int?,
      clientAvatar: freezed == clientAvatar
          ? _value.clientAvatar
          : clientAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BookingImplCopyWith<$Res> implements $BookingCopyWith<$Res> {
  factory _$$BookingImplCopyWith(
          _$BookingImpl value, $Res Function(_$BookingImpl) then) =
      __$$BookingImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String clientName,
      String clientId,
      String serviceName,
      String serviceId,
      String status,
      DateTime scheduledAt,
      String serviceAddress,
      double totalAmount,
      double? providerNetAmount,
      double? platformCommission,
      double? stateTax,
      String? wompiReference,
      String? nequiAccount,
      String? payoutStatus,
      int? rating,
      String? clientAvatar});
}

/// @nodoc
class __$$BookingImplCopyWithImpl<$Res>
    extends _$BookingCopyWithImpl<$Res, _$BookingImpl>
    implements _$$BookingImplCopyWith<$Res> {
  __$$BookingImplCopyWithImpl(
      _$BookingImpl _value, $Res Function(_$BookingImpl) _then)
      : super(_value, _then);

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientName = null,
    Object? clientId = null,
    Object? serviceName = null,
    Object? serviceId = null,
    Object? status = null,
    Object? scheduledAt = null,
    Object? serviceAddress = null,
    Object? totalAmount = null,
    Object? providerNetAmount = freezed,
    Object? platformCommission = freezed,
    Object? stateTax = freezed,
    Object? wompiReference = freezed,
    Object? nequiAccount = freezed,
    Object? payoutStatus = freezed,
    Object? rating = freezed,
    Object? clientAvatar = freezed,
  }) {
    return _then(_$BookingImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clientName: null == clientName
          ? _value.clientName
          : clientName // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      serviceName: null == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String,
      serviceId: null == serviceId
          ? _value.serviceId
          : serviceId // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      scheduledAt: null == scheduledAt
          ? _value.scheduledAt
          : scheduledAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      serviceAddress: null == serviceAddress
          ? _value.serviceAddress
          : serviceAddress // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      providerNetAmount: freezed == providerNetAmount
          ? _value.providerNetAmount
          : providerNetAmount // ignore: cast_nullable_to_non_nullable
              as double?,
      platformCommission: freezed == platformCommission
          ? _value.platformCommission
          : platformCommission // ignore: cast_nullable_to_non_nullable
              as double?,
      stateTax: freezed == stateTax
          ? _value.stateTax
          : stateTax // ignore: cast_nullable_to_non_nullable
              as double?,
      wompiReference: freezed == wompiReference
          ? _value.wompiReference
          : wompiReference // ignore: cast_nullable_to_non_nullable
              as String?,
      nequiAccount: freezed == nequiAccount
          ? _value.nequiAccount
          : nequiAccount // ignore: cast_nullable_to_non_nullable
              as String?,
      payoutStatus: freezed == payoutStatus
          ? _value.payoutStatus
          : payoutStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as int?,
      clientAvatar: freezed == clientAvatar
          ? _value.clientAvatar
          : clientAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BookingImpl implements _Booking {
  const _$BookingImpl(
      {required this.id,
      required this.clientName,
      required this.clientId,
      required this.serviceName,
      required this.serviceId,
      required this.status,
      required this.scheduledAt,
      required this.serviceAddress,
      required this.totalAmount,
      this.providerNetAmount,
      this.platformCommission,
      this.stateTax,
      this.wompiReference,
      this.nequiAccount,
      this.payoutStatus,
      this.rating,
      this.clientAvatar});

  factory _$BookingImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookingImplFromJson(json);

  @override
  final String id;
  @override
  final String clientName;
  @override
  final String clientId;
  @override
  final String serviceName;
  @override
  final String serviceId;
  @override
  final String status;
  @override
  final DateTime scheduledAt;
  @override
  final String serviceAddress;
  @override
  final double totalAmount;
  @override
  final double? providerNetAmount;
  @override
  final double? platformCommission;
  @override
  final double? stateTax;
  @override
  final String? wompiReference;
  @override
  final String? nequiAccount;
  @override
  final String? payoutStatus;
  @override
  final int? rating;
  @override
  final String? clientAvatar;

  @override
  String toString() {
    return 'Booking(id: $id, clientName: $clientName, clientId: $clientId, serviceName: $serviceName, serviceId: $serviceId, status: $status, scheduledAt: $scheduledAt, serviceAddress: $serviceAddress, totalAmount: $totalAmount, providerNetAmount: $providerNetAmount, platformCommission: $platformCommission, stateTax: $stateTax, wompiReference: $wompiReference, nequiAccount: $nequiAccount, payoutStatus: $payoutStatus, rating: $rating, clientAvatar: $clientAvatar)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookingImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientName, clientName) ||
                other.clientName == clientName) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.serviceId, serviceId) ||
                other.serviceId == serviceId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.scheduledAt, scheduledAt) ||
                other.scheduledAt == scheduledAt) &&
            (identical(other.serviceAddress, serviceAddress) ||
                other.serviceAddress == serviceAddress) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.providerNetAmount, providerNetAmount) ||
                other.providerNetAmount == providerNetAmount) &&
            (identical(other.platformCommission, platformCommission) ||
                other.platformCommission == platformCommission) &&
            (identical(other.stateTax, stateTax) ||
                other.stateTax == stateTax) &&
            (identical(other.wompiReference, wompiReference) ||
                other.wompiReference == wompiReference) &&
            (identical(other.nequiAccount, nequiAccount) ||
                other.nequiAccount == nequiAccount) &&
            (identical(other.payoutStatus, payoutStatus) ||
                other.payoutStatus == payoutStatus) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.clientAvatar, clientAvatar) ||
                other.clientAvatar == clientAvatar));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      clientName,
      clientId,
      serviceName,
      serviceId,
      status,
      scheduledAt,
      serviceAddress,
      totalAmount,
      providerNetAmount,
      platformCommission,
      stateTax,
      wompiReference,
      nequiAccount,
      payoutStatus,
      rating,
      clientAvatar);

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookingImplCopyWith<_$BookingImpl> get copyWith =>
      __$$BookingImplCopyWithImpl<_$BookingImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BookingImplToJson(
      this,
    );
  }
}

abstract class _Booking implements Booking {
  const factory _Booking(
      {required final String id,
      required final String clientName,
      required final String clientId,
      required final String serviceName,
      required final String serviceId,
      required final String status,
      required final DateTime scheduledAt,
      required final String serviceAddress,
      required final double totalAmount,
      final double? providerNetAmount,
      final double? platformCommission,
      final double? stateTax,
      final String? wompiReference,
      final String? nequiAccount,
      final String? payoutStatus,
      final int? rating,
      final String? clientAvatar}) = _$BookingImpl;

  factory _Booking.fromJson(Map<String, dynamic> json) = _$BookingImpl.fromJson;

  @override
  String get id;
  @override
  String get clientName;
  @override
  String get clientId;
  @override
  String get serviceName;
  @override
  String get serviceId;
  @override
  String get status;
  @override
  DateTime get scheduledAt;
  @override
  String get serviceAddress;
  @override
  double get totalAmount;
  @override
  double? get providerNetAmount;
  @override
  double? get platformCommission;
  @override
  double? get stateTax;
  @override
  String? get wompiReference;
  @override
  String? get nequiAccount;
  @override
  String? get payoutStatus;
  @override
  int? get rating;
  @override
  String? get clientAvatar;

  /// Create a copy of Booking
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookingImplCopyWith<_$BookingImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
