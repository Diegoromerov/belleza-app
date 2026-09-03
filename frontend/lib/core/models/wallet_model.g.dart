// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WalletImpl _$$WalletImplFromJson(Map<String, dynamic> json) => _$WalletImpl(
      availableBalance: (json['availableBalance'] as num).toDouble(),
      pendingBalance: (json['pendingBalance'] as num).toDouble(),
      disputedBalance: (json['disputedBalance'] as num).toDouble(),
      totalEarned: (json['totalEarned'] as num).toDouble(),
      totalWithdrawn: (json['totalWithdrawn'] as num).toDouble(),
      canWithdraw: json['canWithdraw'] as bool,
      withdrawalBlockReason: json['withdrawalBlockReason'] as String?,
      nextAutoWithdrawal: json['nextAutoWithdrawal'] == null
          ? null
          : DateTime.parse(json['nextAutoWithdrawal'] as String),
      withdrawalModel: json['withdrawalModel'] as String,
      accountVerified: json['accountVerified'] as bool,
      bankName: json['bankName'] as String?,
      accountNumber: json['accountNumber'] as String?,
    );

Map<String, dynamic> _$$WalletImplToJson(_$WalletImpl instance) =>
    <String, dynamic>{
      'availableBalance': instance.availableBalance,
      'pendingBalance': instance.pendingBalance,
      'disputedBalance': instance.disputedBalance,
      'totalEarned': instance.totalEarned,
      'totalWithdrawn': instance.totalWithdrawn,
      'canWithdraw': instance.canWithdraw,
      'withdrawalBlockReason': instance.withdrawalBlockReason,
      'nextAutoWithdrawal': instance.nextAutoWithdrawal?.toIso8601String(),
      'withdrawalModel': instance.withdrawalModel,
      'accountVerified': instance.accountVerified,
      'bankName': instance.bankName,
      'accountNumber': instance.accountNumber,
    };

_$WalletTransactionImpl _$$WalletTransactionImplFromJson(
        Map<String, dynamic> json) =>
    _$WalletTransactionImpl(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      serviceName: json['serviceName'] as String?,
      bookingId: json['bookingId'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$WalletTransactionImplToJson(
        _$WalletTransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'serviceName': instance.serviceName,
      'bookingId': instance.bookingId,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
    };
