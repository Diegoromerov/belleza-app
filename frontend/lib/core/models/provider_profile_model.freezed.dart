// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'provider_profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProviderProfile _$ProviderProfileFromJson(Map<String, dynamic> json) {
  return _ProviderProfile.fromJson(json);
}

/// @nodoc
mixin _$ProviderProfile {
  String get id => throw _privateConstructorUsedError;
  String get fullName => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get phone => throw _privateConstructorUsedError;
  String? get avatarUrl => throw _privateConstructorUsedError;
  String? get coverUrl => throw _privateConstructorUsedError;
  String? get businessName => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get specialty => throw _privateConstructorUsedError;
  String get verificationStatus => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;
  double get ratingAvg => throw _privateConstructorUsedError;
  int get ratingCount => throw _privateConstructorUsedError;
  int get activeStartHour => throw _privateConstructorUsedError;
  int get activeEndHour => throw _privateConstructorUsedError;
  Map<String, dynamic> get weeklySchedule => throw _privateConstructorUsedError;
  double get coverageRadius => throw _privateConstructorUsedError;
  int get experienceYears => throw _privateConstructorUsedError;
  String? get bankName => throw _privateConstructorUsedError;
  String? get accountNumber => throw _privateConstructorUsedError;
  String? get accountType => throw _privateConstructorUsedError;
  String get withdrawalModel => throw _privateConstructorUsedError;
  DateTime? get nextWithdrawalDate => throw _privateConstructorUsedError;

  /// Serializes this ProviderProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProviderProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProviderProfileCopyWith<ProviderProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProviderProfileCopyWith<$Res> {
  factory $ProviderProfileCopyWith(
          ProviderProfile value, $Res Function(ProviderProfile) then) =
      _$ProviderProfileCopyWithImpl<$Res, ProviderProfile>;
  @useResult
  $Res call(
      {String id,
      String fullName,
      String email,
      String phone,
      String? avatarUrl,
      String? coverUrl,
      String? businessName,
      String? description,
      String? specialty,
      String verificationStatus,
      bool isActive,
      double ratingAvg,
      int ratingCount,
      int activeStartHour,
      int activeEndHour,
      Map<String, dynamic> weeklySchedule,
      double coverageRadius,
      int experienceYears,
      String? bankName,
      String? accountNumber,
      String? accountType,
      String withdrawalModel,
      DateTime? nextWithdrawalDate});
}

/// @nodoc
class _$ProviderProfileCopyWithImpl<$Res, $Val extends ProviderProfile>
    implements $ProviderProfileCopyWith<$Res> {
  _$ProviderProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProviderProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? email = null,
    Object? phone = null,
    Object? avatarUrl = freezed,
    Object? coverUrl = freezed,
    Object? businessName = freezed,
    Object? description = freezed,
    Object? specialty = freezed,
    Object? verificationStatus = null,
    Object? isActive = null,
    Object? ratingAvg = null,
    Object? ratingCount = null,
    Object? activeStartHour = null,
    Object? activeEndHour = null,
    Object? weeklySchedule = null,
    Object? coverageRadius = null,
    Object? experienceYears = null,
    Object? bankName = freezed,
    Object? accountNumber = freezed,
    Object? accountType = freezed,
    Object? withdrawalModel = null,
    Object? nextWithdrawalDate = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      coverUrl: freezed == coverUrl
          ? _value.coverUrl
          : coverUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      businessName: freezed == businessName
          ? _value.businessName
          : businessName // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      specialty: freezed == specialty
          ? _value.specialty
          : specialty // ignore: cast_nullable_to_non_nullable
              as String?,
      verificationStatus: null == verificationStatus
          ? _value.verificationStatus
          : verificationStatus // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      ratingAvg: null == ratingAvg
          ? _value.ratingAvg
          : ratingAvg // ignore: cast_nullable_to_non_nullable
              as double,
      ratingCount: null == ratingCount
          ? _value.ratingCount
          : ratingCount // ignore: cast_nullable_to_non_nullable
              as int,
      activeStartHour: null == activeStartHour
          ? _value.activeStartHour
          : activeStartHour // ignore: cast_nullable_to_non_nullable
              as int,
      activeEndHour: null == activeEndHour
          ? _value.activeEndHour
          : activeEndHour // ignore: cast_nullable_to_non_nullable
              as int,
      weeklySchedule: null == weeklySchedule
          ? _value.weeklySchedule
          : weeklySchedule // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      coverageRadius: null == coverageRadius
          ? _value.coverageRadius
          : coverageRadius // ignore: cast_nullable_to_non_nullable
              as double,
      experienceYears: null == experienceYears
          ? _value.experienceYears
          : experienceYears // ignore: cast_nullable_to_non_nullable
              as int,
      bankName: freezed == bankName
          ? _value.bankName
          : bankName // ignore: cast_nullable_to_non_nullable
              as String?,
      accountNumber: freezed == accountNumber
          ? _value.accountNumber
          : accountNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      accountType: freezed == accountType
          ? _value.accountType
          : accountType // ignore: cast_nullable_to_non_nullable
              as String?,
      withdrawalModel: null == withdrawalModel
          ? _value.withdrawalModel
          : withdrawalModel // ignore: cast_nullable_to_non_nullable
              as String,
      nextWithdrawalDate: freezed == nextWithdrawalDate
          ? _value.nextWithdrawalDate
          : nextWithdrawalDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProviderProfileImplCopyWith<$Res>
    implements $ProviderProfileCopyWith<$Res> {
  factory _$$ProviderProfileImplCopyWith(_$ProviderProfileImpl value,
          $Res Function(_$ProviderProfileImpl) then) =
      __$$ProviderProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String fullName,
      String email,
      String phone,
      String? avatarUrl,
      String? coverUrl,
      String? businessName,
      String? description,
      String? specialty,
      String verificationStatus,
      bool isActive,
      double ratingAvg,
      int ratingCount,
      int activeStartHour,
      int activeEndHour,
      Map<String, dynamic> weeklySchedule,
      double coverageRadius,
      int experienceYears,
      String? bankName,
      String? accountNumber,
      String? accountType,
      String withdrawalModel,
      DateTime? nextWithdrawalDate});
}

/// @nodoc
class __$$ProviderProfileImplCopyWithImpl<$Res>
    extends _$ProviderProfileCopyWithImpl<$Res, _$ProviderProfileImpl>
    implements _$$ProviderProfileImplCopyWith<$Res> {
  __$$ProviderProfileImplCopyWithImpl(
      _$ProviderProfileImpl _value, $Res Function(_$ProviderProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProviderProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fullName = null,
    Object? email = null,
    Object? phone = null,
    Object? avatarUrl = freezed,
    Object? coverUrl = freezed,
    Object? businessName = freezed,
    Object? description = freezed,
    Object? specialty = freezed,
    Object? verificationStatus = null,
    Object? isActive = null,
    Object? ratingAvg = null,
    Object? ratingCount = null,
    Object? activeStartHour = null,
    Object? activeEndHour = null,
    Object? weeklySchedule = null,
    Object? coverageRadius = null,
    Object? experienceYears = null,
    Object? bankName = freezed,
    Object? accountNumber = freezed,
    Object? accountType = freezed,
    Object? withdrawalModel = null,
    Object? nextWithdrawalDate = freezed,
  }) {
    return _then(_$ProviderProfileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fullName: null == fullName
          ? _value.fullName
          : fullName // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _value.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      avatarUrl: freezed == avatarUrl
          ? _value.avatarUrl
          : avatarUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      coverUrl: freezed == coverUrl
          ? _value.coverUrl
          : coverUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      businessName: freezed == businessName
          ? _value.businessName
          : businessName // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      specialty: freezed == specialty
          ? _value.specialty
          : specialty // ignore: cast_nullable_to_non_nullable
              as String?,
      verificationStatus: null == verificationStatus
          ? _value.verificationStatus
          : verificationStatus // ignore: cast_nullable_to_non_nullable
              as String,
      isActive: null == isActive
          ? _value.isActive
          : isActive // ignore: cast_nullable_to_non_nullable
              as bool,
      ratingAvg: null == ratingAvg
          ? _value.ratingAvg
          : ratingAvg // ignore: cast_nullable_to_non_nullable
              as double,
      ratingCount: null == ratingCount
          ? _value.ratingCount
          : ratingCount // ignore: cast_nullable_to_non_nullable
              as int,
      activeStartHour: null == activeStartHour
          ? _value.activeStartHour
          : activeStartHour // ignore: cast_nullable_to_non_nullable
              as int,
      activeEndHour: null == activeEndHour
          ? _value.activeEndHour
          : activeEndHour // ignore: cast_nullable_to_non_nullable
              as int,
      weeklySchedule: null == weeklySchedule
          ? _value._weeklySchedule
          : weeklySchedule // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      coverageRadius: null == coverageRadius
          ? _value.coverageRadius
          : coverageRadius // ignore: cast_nullable_to_non_nullable
              as double,
      experienceYears: null == experienceYears
          ? _value.experienceYears
          : experienceYears // ignore: cast_nullable_to_non_nullable
              as int,
      bankName: freezed == bankName
          ? _value.bankName
          : bankName // ignore: cast_nullable_to_non_nullable
              as String?,
      accountNumber: freezed == accountNumber
          ? _value.accountNumber
          : accountNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      accountType: freezed == accountType
          ? _value.accountType
          : accountType // ignore: cast_nullable_to_non_nullable
              as String?,
      withdrawalModel: null == withdrawalModel
          ? _value.withdrawalModel
          : withdrawalModel // ignore: cast_nullable_to_non_nullable
              as String,
      nextWithdrawalDate: freezed == nextWithdrawalDate
          ? _value.nextWithdrawalDate
          : nextWithdrawalDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProviderProfileImpl implements _ProviderProfile {
  const _$ProviderProfileImpl(
      {required this.id,
      required this.fullName,
      required this.email,
      required this.phone,
      this.avatarUrl,
      this.coverUrl,
      this.businessName,
      this.description,
      this.specialty,
      required this.verificationStatus,
      required this.isActive,
      required this.ratingAvg,
      required this.ratingCount,
      required this.activeStartHour,
      required this.activeEndHour,
      required final Map<String, dynamic> weeklySchedule,
      required this.coverageRadius,
      required this.experienceYears,
      this.bankName,
      this.accountNumber,
      this.accountType,
      required this.withdrawalModel,
      this.nextWithdrawalDate})
      : _weeklySchedule = weeklySchedule;

  factory _$ProviderProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProviderProfileImplFromJson(json);

  @override
  final String id;
  @override
  final String fullName;
  @override
  final String email;
  @override
  final String phone;
  @override
  final String? avatarUrl;
  @override
  final String? coverUrl;
  @override
  final String? businessName;
  @override
  final String? description;
  @override
  final String? specialty;
  @override
  final String verificationStatus;
  @override
  final bool isActive;
  @override
  final double ratingAvg;
  @override
  final int ratingCount;
  @override
  final int activeStartHour;
  @override
  final int activeEndHour;
  final Map<String, dynamic> _weeklySchedule;
  @override
  Map<String, dynamic> get weeklySchedule {
    if (_weeklySchedule is EqualUnmodifiableMapView) return _weeklySchedule;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_weeklySchedule);
  }

  @override
  final double coverageRadius;
  @override
  final int experienceYears;
  @override
  final String? bankName;
  @override
  final String? accountNumber;
  @override
  final String? accountType;
  @override
  final String withdrawalModel;
  @override
  final DateTime? nextWithdrawalDate;

  @override
  String toString() {
    return 'ProviderProfile(id: $id, fullName: $fullName, email: $email, phone: $phone, avatarUrl: $avatarUrl, coverUrl: $coverUrl, businessName: $businessName, description: $description, specialty: $specialty, verificationStatus: $verificationStatus, isActive: $isActive, ratingAvg: $ratingAvg, ratingCount: $ratingCount, activeStartHour: $activeStartHour, activeEndHour: $activeEndHour, weeklySchedule: $weeklySchedule, coverageRadius: $coverageRadius, experienceYears: $experienceYears, bankName: $bankName, accountNumber: $accountNumber, accountType: $accountType, withdrawalModel: $withdrawalModel, nextWithdrawalDate: $nextWithdrawalDate)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProviderProfileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fullName, fullName) ||
                other.fullName == fullName) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.avatarUrl, avatarUrl) ||
                other.avatarUrl == avatarUrl) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl) &&
            (identical(other.businessName, businessName) ||
                other.businessName == businessName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.specialty, specialty) ||
                other.specialty == specialty) &&
            (identical(other.verificationStatus, verificationStatus) ||
                other.verificationStatus == verificationStatus) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            (identical(other.ratingAvg, ratingAvg) ||
                other.ratingAvg == ratingAvg) &&
            (identical(other.ratingCount, ratingCount) ||
                other.ratingCount == ratingCount) &&
            (identical(other.activeStartHour, activeStartHour) ||
                other.activeStartHour == activeStartHour) &&
            (identical(other.activeEndHour, activeEndHour) ||
                other.activeEndHour == activeEndHour) &&
            const DeepCollectionEquality()
                .equals(other._weeklySchedule, _weeklySchedule) &&
            (identical(other.coverageRadius, coverageRadius) ||
                other.coverageRadius == coverageRadius) &&
            (identical(other.experienceYears, experienceYears) ||
                other.experienceYears == experienceYears) &&
            (identical(other.bankName, bankName) ||
                other.bankName == bankName) &&
            (identical(other.accountNumber, accountNumber) ||
                other.accountNumber == accountNumber) &&
            (identical(other.accountType, accountType) ||
                other.accountType == accountType) &&
            (identical(other.withdrawalModel, withdrawalModel) ||
                other.withdrawalModel == withdrawalModel) &&
            (identical(other.nextWithdrawalDate, nextWithdrawalDate) ||
                other.nextWithdrawalDate == nextWithdrawalDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        fullName,
        email,
        phone,
        avatarUrl,
        coverUrl,
        businessName,
        description,
        specialty,
        verificationStatus,
        isActive,
        ratingAvg,
        ratingCount,
        activeStartHour,
        activeEndHour,
        const DeepCollectionEquality().hash(_weeklySchedule),
        coverageRadius,
        experienceYears,
        bankName,
        accountNumber,
        accountType,
        withdrawalModel,
        nextWithdrawalDate
      ]);

  /// Create a copy of ProviderProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProviderProfileImplCopyWith<_$ProviderProfileImpl> get copyWith =>
      __$$ProviderProfileImplCopyWithImpl<_$ProviderProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProviderProfileImplToJson(
      this,
    );
  }
}

abstract class _ProviderProfile implements ProviderProfile {
  const factory _ProviderProfile(
      {required final String id,
      required final String fullName,
      required final String email,
      required final String phone,
      final String? avatarUrl,
      final String? coverUrl,
      final String? businessName,
      final String? description,
      final String? specialty,
      required final String verificationStatus,
      required final bool isActive,
      required final double ratingAvg,
      required final int ratingCount,
      required final int activeStartHour,
      required final int activeEndHour,
      required final Map<String, dynamic> weeklySchedule,
      required final double coverageRadius,
      required final int experienceYears,
      final String? bankName,
      final String? accountNumber,
      final String? accountType,
      required final String withdrawalModel,
      final DateTime? nextWithdrawalDate}) = _$ProviderProfileImpl;

  factory _ProviderProfile.fromJson(Map<String, dynamic> json) =
      _$ProviderProfileImpl.fromJson;

  @override
  String get id;
  @override
  String get fullName;
  @override
  String get email;
  @override
  String get phone;
  @override
  String? get avatarUrl;
  @override
  String? get coverUrl;
  @override
  String? get businessName;
  @override
  String? get description;
  @override
  String? get specialty;
  @override
  String get verificationStatus;
  @override
  bool get isActive;
  @override
  double get ratingAvg;
  @override
  int get ratingCount;
  @override
  int get activeStartHour;
  @override
  int get activeEndHour;
  @override
  Map<String, dynamic> get weeklySchedule;
  @override
  double get coverageRadius;
  @override
  int get experienceYears;
  @override
  String? get bankName;
  @override
  String? get accountNumber;
  @override
  String? get accountType;
  @override
  String get withdrawalModel;
  @override
  DateTime? get nextWithdrawalDate;

  /// Create a copy of ProviderProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProviderProfileImplCopyWith<_$ProviderProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
