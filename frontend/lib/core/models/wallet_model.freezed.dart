// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Wallet _$WalletFromJson(Map<String, dynamic> json) {
  return _Wallet.fromJson(json);
}

/// @nodoc
mixin _$Wallet {
  double get availableBalance => throw _privateConstructorUsedError;
  double get pendingBalance => throw _privateConstructorUsedError;
  double get disputedBalance => throw _privateConstructorUsedError;
  double get totalEarned => throw _privateConstructorUsedError;
  double get totalWithdrawn => throw _privateConstructorUsedError;
  bool get canWithdraw => throw _privateConstructorUsedError;
  String? get withdrawalBlockReason => throw _privateConstructorUsedError;
  DateTime? get nextAutoWithdrawal => throw _privateConstructorUsedError;
  String get withdrawalModel => throw _privateConstructorUsedError;
  bool get accountVerified => throw _privateConstructorUsedError;
  String? get bankName => throw _privateConstructorUsedError;
  String? get accountNumber => throw _privateConstructorUsedError;

  /// Serializes this Wallet to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Wallet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WalletCopyWith<Wallet> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletCopyWith<$Res> {
  factory $WalletCopyWith(Wallet value, $Res Function(Wallet) then) =
      _$WalletCopyWithImpl<$Res, Wallet>;
  @useResult
  $Res call(
      {double availableBalance,
      double pendingBalance,
      double disputedBalance,
      double totalEarned,
      double totalWithdrawn,
      bool canWithdraw,
      String? withdrawalBlockReason,
      DateTime? nextAutoWithdrawal,
      String withdrawalModel,
      bool accountVerified,
      String? bankName,
      String? accountNumber});
}

/// @nodoc
class _$WalletCopyWithImpl<$Res, $Val extends Wallet>
    implements $WalletCopyWith<$Res> {
  _$WalletCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Wallet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? availableBalance = null,
    Object? pendingBalance = null,
    Object? disputedBalance = null,
    Object? totalEarned = null,
    Object? totalWithdrawn = null,
    Object? canWithdraw = null,
    Object? withdrawalBlockReason = freezed,
    Object? nextAutoWithdrawal = freezed,
    Object? withdrawalModel = null,
    Object? accountVerified = null,
    Object? bankName = freezed,
    Object? accountNumber = freezed,
  }) {
    return _then(_value.copyWith(
      availableBalance: null == availableBalance
          ? _value.availableBalance
          : availableBalance // ignore: cast_nullable_to_non_nullable
              as double,
      pendingBalance: null == pendingBalance
          ? _value.pendingBalance
          : pendingBalance // ignore: cast_nullable_to_non_nullable
              as double,
      disputedBalance: null == disputedBalance
          ? _value.disputedBalance
          : disputedBalance // ignore: cast_nullable_to_non_nullable
              as double,
      totalEarned: null == totalEarned
          ? _value.totalEarned
          : totalEarned // ignore: cast_nullable_to_non_nullable
              as double,
      totalWithdrawn: null == totalWithdrawn
          ? _value.totalWithdrawn
          : totalWithdrawn // ignore: cast_nullable_to_non_nullable
              as double,
      canWithdraw: null == canWithdraw
          ? _value.canWithdraw
          : canWithdraw // ignore: cast_nullable_to_non_nullable
              as bool,
      withdrawalBlockReason: freezed == withdrawalBlockReason
          ? _value.withdrawalBlockReason
          : withdrawalBlockReason // ignore: cast_nullable_to_non_nullable
              as String?,
      nextAutoWithdrawal: freezed == nextAutoWithdrawal
          ? _value.nextAutoWithdrawal
          : nextAutoWithdrawal // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      withdrawalModel: null == withdrawalModel
          ? _value.withdrawalModel
          : withdrawalModel // ignore: cast_nullable_to_non_nullable
              as String,
      accountVerified: null == accountVerified
          ? _value.accountVerified
          : accountVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      bankName: freezed == bankName
          ? _value.bankName
          : bankName // ignore: cast_nullable_to_non_nullable
              as String?,
      accountNumber: freezed == accountNumber
          ? _value.accountNumber
          : accountNumber // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WalletImplCopyWith<$Res> implements $WalletCopyWith<$Res> {
  factory _$$WalletImplCopyWith(
          _$WalletImpl value, $Res Function(_$WalletImpl) then) =
      __$$WalletImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double availableBalance,
      double pendingBalance,
      double disputedBalance,
      double totalEarned,
      double totalWithdrawn,
      bool canWithdraw,
      String? withdrawalBlockReason,
      DateTime? nextAutoWithdrawal,
      String withdrawalModel,
      bool accountVerified,
      String? bankName,
      String? accountNumber});
}

/// @nodoc
class __$$WalletImplCopyWithImpl<$Res>
    extends _$WalletCopyWithImpl<$Res, _$WalletImpl>
    implements _$$WalletImplCopyWith<$Res> {
  __$$WalletImplCopyWithImpl(
      _$WalletImpl _value, $Res Function(_$WalletImpl) _then)
      : super(_value, _then);

  /// Create a copy of Wallet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? availableBalance = null,
    Object? pendingBalance = null,
    Object? disputedBalance = null,
    Object? totalEarned = null,
    Object? totalWithdrawn = null,
    Object? canWithdraw = null,
    Object? withdrawalBlockReason = freezed,
    Object? nextAutoWithdrawal = freezed,
    Object? withdrawalModel = null,
    Object? accountVerified = null,
    Object? bankName = freezed,
    Object? accountNumber = freezed,
  }) {
    return _then(_$WalletImpl(
      availableBalance: null == availableBalance
          ? _value.availableBalance
          : availableBalance // ignore: cast_nullable_to_non_nullable
              as double,
      pendingBalance: null == pendingBalance
          ? _value.pendingBalance
          : pendingBalance // ignore: cast_nullable_to_non_nullable
              as double,
      disputedBalance: null == disputedBalance
          ? _value.disputedBalance
          : disputedBalance // ignore: cast_nullable_to_non_nullable
              as double,
      totalEarned: null == totalEarned
          ? _value.totalEarned
          : totalEarned // ignore: cast_nullable_to_non_nullable
              as double,
      totalWithdrawn: null == totalWithdrawn
          ? _value.totalWithdrawn
          : totalWithdrawn // ignore: cast_nullable_to_non_nullable
              as double,
      canWithdraw: null == canWithdraw
          ? _value.canWithdraw
          : canWithdraw // ignore: cast_nullable_to_non_nullable
              as bool,
      withdrawalBlockReason: freezed == withdrawalBlockReason
          ? _value.withdrawalBlockReason
          : withdrawalBlockReason // ignore: cast_nullable_to_non_nullable
              as String?,
      nextAutoWithdrawal: freezed == nextAutoWithdrawal
          ? _value.nextAutoWithdrawal
          : nextAutoWithdrawal // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      withdrawalModel: null == withdrawalModel
          ? _value.withdrawalModel
          : withdrawalModel // ignore: cast_nullable_to_non_nullable
              as String,
      accountVerified: null == accountVerified
          ? _value.accountVerified
          : accountVerified // ignore: cast_nullable_to_non_nullable
              as bool,
      bankName: freezed == bankName
          ? _value.bankName
          : bankName // ignore: cast_nullable_to_non_nullable
              as String?,
      accountNumber: freezed == accountNumber
          ? _value.accountNumber
          : accountNumber // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletImpl implements _Wallet {
  const _$WalletImpl(
      {required this.availableBalance,
      required this.pendingBalance,
      required this.disputedBalance,
      required this.totalEarned,
      required this.totalWithdrawn,
      required this.canWithdraw,
      this.withdrawalBlockReason,
      this.nextAutoWithdrawal,
      required this.withdrawalModel,
      required this.accountVerified,
      this.bankName,
      this.accountNumber});

  factory _$WalletImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletImplFromJson(json);

  @override
  final double availableBalance;
  @override
  final double pendingBalance;
  @override
  final double disputedBalance;
  @override
  final double totalEarned;
  @override
  final double totalWithdrawn;
  @override
  final bool canWithdraw;
  @override
  final String? withdrawalBlockReason;
  @override
  final DateTime? nextAutoWithdrawal;
  @override
  final String withdrawalModel;
  @override
  final bool accountVerified;
  @override
  final String? bankName;
  @override
  final String? accountNumber;

  @override
  String toString() {
    return 'Wallet(availableBalance: $availableBalance, pendingBalance: $pendingBalance, disputedBalance: $disputedBalance, totalEarned: $totalEarned, totalWithdrawn: $totalWithdrawn, canWithdraw: $canWithdraw, withdrawalBlockReason: $withdrawalBlockReason, nextAutoWithdrawal: $nextAutoWithdrawal, withdrawalModel: $withdrawalModel, accountVerified: $accountVerified, bankName: $bankName, accountNumber: $accountNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletImpl &&
            (identical(other.availableBalance, availableBalance) ||
                other.availableBalance == availableBalance) &&
            (identical(other.pendingBalance, pendingBalance) ||
                other.pendingBalance == pendingBalance) &&
            (identical(other.disputedBalance, disputedBalance) ||
                other.disputedBalance == disputedBalance) &&
            (identical(other.totalEarned, totalEarned) ||
                other.totalEarned == totalEarned) &&
            (identical(other.totalWithdrawn, totalWithdrawn) ||
                other.totalWithdrawn == totalWithdrawn) &&
            (identical(other.canWithdraw, canWithdraw) ||
                other.canWithdraw == canWithdraw) &&
            (identical(other.withdrawalBlockReason, withdrawalBlockReason) ||
                other.withdrawalBlockReason == withdrawalBlockReason) &&
            (identical(other.nextAutoWithdrawal, nextAutoWithdrawal) ||
                other.nextAutoWithdrawal == nextAutoWithdrawal) &&
            (identical(other.withdrawalModel, withdrawalModel) ||
                other.withdrawalModel == withdrawalModel) &&
            (identical(other.accountVerified, accountVerified) ||
                other.accountVerified == accountVerified) &&
            (identical(other.bankName, bankName) ||
                other.bankName == bankName) &&
            (identical(other.accountNumber, accountNumber) ||
                other.accountNumber == accountNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      availableBalance,
      pendingBalance,
      disputedBalance,
      totalEarned,
      totalWithdrawn,
      canWithdraw,
      withdrawalBlockReason,
      nextAutoWithdrawal,
      withdrawalModel,
      accountVerified,
      bankName,
      accountNumber);

  /// Create a copy of Wallet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletImplCopyWith<_$WalletImpl> get copyWith =>
      __$$WalletImplCopyWithImpl<_$WalletImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletImplToJson(
      this,
    );
  }
}

abstract class _Wallet implements Wallet {
  const factory _Wallet(
      {required final double availableBalance,
      required final double pendingBalance,
      required final double disputedBalance,
      required final double totalEarned,
      required final double totalWithdrawn,
      required final bool canWithdraw,
      final String? withdrawalBlockReason,
      final DateTime? nextAutoWithdrawal,
      required final String withdrawalModel,
      required final bool accountVerified,
      final String? bankName,
      final String? accountNumber}) = _$WalletImpl;

  factory _Wallet.fromJson(Map<String, dynamic> json) = _$WalletImpl.fromJson;

  @override
  double get availableBalance;
  @override
  double get pendingBalance;
  @override
  double get disputedBalance;
  @override
  double get totalEarned;
  @override
  double get totalWithdrawn;
  @override
  bool get canWithdraw;
  @override
  String? get withdrawalBlockReason;
  @override
  DateTime? get nextAutoWithdrawal;
  @override
  String get withdrawalModel;
  @override
  bool get accountVerified;
  @override
  String? get bankName;
  @override
  String? get accountNumber;

  /// Create a copy of Wallet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletImplCopyWith<_$WalletImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WalletTransaction _$WalletTransactionFromJson(Map<String, dynamic> json) {
  return _WalletTransaction.fromJson(json);
}

/// @nodoc
mixin _$WalletTransaction {
  String get id => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String? get serviceName => throw _privateConstructorUsedError;
  String? get bookingId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this WalletTransaction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WalletTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WalletTransactionCopyWith<WalletTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WalletTransactionCopyWith<$Res> {
  factory $WalletTransactionCopyWith(
          WalletTransaction value, $Res Function(WalletTransaction) then) =
      _$WalletTransactionCopyWithImpl<$Res, WalletTransaction>;
  @useResult
  $Res call(
      {String id,
      String type,
      double amount,
      String? serviceName,
      String? bookingId,
      String status,
      DateTime createdAt});
}

/// @nodoc
class _$WalletTransactionCopyWithImpl<$Res, $Val extends WalletTransaction>
    implements $WalletTransactionCopyWith<$Res> {
  _$WalletTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WalletTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? amount = null,
    Object? serviceName = freezed,
    Object? bookingId = freezed,
    Object? status = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      serviceName: freezed == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String?,
      bookingId: freezed == bookingId
          ? _value.bookingId
          : bookingId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WalletTransactionImplCopyWith<$Res>
    implements $WalletTransactionCopyWith<$Res> {
  factory _$$WalletTransactionImplCopyWith(_$WalletTransactionImpl value,
          $Res Function(_$WalletTransactionImpl) then) =
      __$$WalletTransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String type,
      double amount,
      String? serviceName,
      String? bookingId,
      String status,
      DateTime createdAt});
}

/// @nodoc
class __$$WalletTransactionImplCopyWithImpl<$Res>
    extends _$WalletTransactionCopyWithImpl<$Res, _$WalletTransactionImpl>
    implements _$$WalletTransactionImplCopyWith<$Res> {
  __$$WalletTransactionImplCopyWithImpl(_$WalletTransactionImpl _value,
      $Res Function(_$WalletTransactionImpl) _then)
      : super(_value, _then);

  /// Create a copy of WalletTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? amount = null,
    Object? serviceName = freezed,
    Object? bookingId = freezed,
    Object? status = null,
    Object? createdAt = null,
  }) {
    return _then(_$WalletTransactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      serviceName: freezed == serviceName
          ? _value.serviceName
          : serviceName // ignore: cast_nullable_to_non_nullable
              as String?,
      bookingId: freezed == bookingId
          ? _value.bookingId
          : bookingId // ignore: cast_nullable_to_non_nullable
              as String?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WalletTransactionImpl implements _WalletTransaction {
  const _$WalletTransactionImpl(
      {required this.id,
      required this.type,
      required this.amount,
      this.serviceName,
      this.bookingId,
      required this.status,
      required this.createdAt});

  factory _$WalletTransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$WalletTransactionImplFromJson(json);

  @override
  final String id;
  @override
  final String type;
  @override
  final double amount;
  @override
  final String? serviceName;
  @override
  final String? bookingId;
  @override
  final String status;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'WalletTransaction(id: $id, type: $type, amount: $amount, serviceName: $serviceName, bookingId: $bookingId, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WalletTransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.serviceName, serviceName) ||
                other.serviceName == serviceName) &&
            (identical(other.bookingId, bookingId) ||
                other.bookingId == bookingId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, type, amount, serviceName, bookingId, status, createdAt);

  /// Create a copy of WalletTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WalletTransactionImplCopyWith<_$WalletTransactionImpl> get copyWith =>
      __$$WalletTransactionImplCopyWithImpl<_$WalletTransactionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WalletTransactionImplToJson(
      this,
    );
  }
}

abstract class _WalletTransaction implements WalletTransaction {
  const factory _WalletTransaction(
      {required final String id,
      required final String type,
      required final double amount,
      final String? serviceName,
      final String? bookingId,
      required final String status,
      required final DateTime createdAt}) = _$WalletTransactionImpl;

  factory _WalletTransaction.fromJson(Map<String, dynamic> json) =
      _$WalletTransactionImpl.fromJson;

  @override
  String get id;
  @override
  String get type;
  @override
  double get amount;
  @override
  String? get serviceName;
  @override
  String? get bookingId;
  @override
  String get status;
  @override
  DateTime get createdAt;

  /// Create a copy of WalletTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WalletTransactionImplCopyWith<_$WalletTransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
