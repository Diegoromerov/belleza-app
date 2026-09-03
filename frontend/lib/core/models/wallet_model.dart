// lib/core/models/wallet_model.dart
// Modelos tipados para Wallet del prestador

import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_model.freezed.dart';
part 'wallet_model.g.dart';

@freezed
abstract class Wallet with _$Wallet {
  const factory Wallet({
    required double availableBalance,
    required double pendingBalance,
    required double disputedBalance,
    required double totalEarned,
    required double totalWithdrawn,
    required bool canWithdraw,
    String? withdrawalBlockReason,
    DateTime? nextAutoWithdrawal,
    required String withdrawalModel,
    required bool accountVerified,
    String? bankName,
    String? accountNumber,
  }) = _Wallet;

  factory Wallet.fromJson(Map<String, dynamic> json) => _$WalletFromJson(json);

  factory Wallet.fromBackendJson(Map<String, dynamic> json) {
    return Wallet(
      availableBalance: double.tryParse(json['saldo_disponible']?.toString() ?? '0') ?? 0,
      pendingBalance: double.tryParse(json['saldo_pendiente']?.toString() ?? '0') ?? 0,
      disputedBalance: double.tryParse(json['saldo_en_disputa']?.toString() ?? '0') ?? 0,
      totalEarned: double.tryParse(json['total_ganado']?.toString() ?? '0') ?? 0,
      totalWithdrawn: double.tryParse(json['total_retirado']?.toString() ?? '0') ?? 0,
      canWithdraw: json['puede_retirar'] as bool? ?? false,
      withdrawalBlockReason: json['razon_bloqueo']?.toString(),
      nextAutoWithdrawal: json['proxima_fecha_retiro'] != null
          ? DateTime.tryParse(json['proxima_fecha_retiro'].toString())
          : null,
      withdrawalModel: (json['modelo_retiro']?.toString() ?? 'DEMANDA').toUpperCase(),
      accountVerified: json['cuenta_verificada'] as bool? ?? false,
      bankName: json['banco']?.toString(),
      accountNumber: json['numero_cuenta']?.toString(),
    );
  }
}

@freezed
abstract class WalletTransaction with _$WalletTransaction {
  const factory WalletTransaction({
    required String id,
    required String type,
    required double amount,
    String? serviceName,
    String? bookingId,
    required String status,
    required DateTime createdAt,
  }) = _WalletTransaction;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => _$WalletTransactionFromJson(json);

  factory WalletTransaction.fromBackendJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id']?.toString() ?? '',
      type: json['tipo']?.toString() ?? '',
      amount: double.tryParse(json['monto']?.toString() ?? '0') ?? 0,
      serviceName: json['servicio_nombre']?.toString(),
      bookingId: json['booking_id']?.toString(),
      status: (json['estado']?.toString() ?? 'PENDIENTE').toUpperCase(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

extension WalletTransactionExt on WalletTransaction {
  bool get isCredit => type.startsWith('CREDITO') ||
      type == 'LIBERACION_DISPUTA' ||
      type == 'BONO_CANCELACION';

  String get displayType {
    switch (type) {
      case 'CREDITO_SERVICIO': return 'Servicio completado';
      case 'DEBITO_RETIRO': return 'Retiro';
      case 'RETENCION_DISPUTA': return 'Fondos retenidos';
      case 'LIBERACION_DISPUTA': return 'Disputa resuelta';
      case 'BONO_CANCELACION': return 'Bono recibido';
      case 'AJUSTE_ADMIN': return 'Ajuste administrativo';
      default: return type;
    }
  }
}

extension WalletExt on Wallet {
  String get withdrawalModelDisplay {
    switch (withdrawalModel) {
      case 'QUINCENA': return 'Automático cada 15 días';
      case 'MENSUAL': return 'Automático mensual';
      default: return 'Por demanda';
    }
  }

  String get maskedAccount {
    if (accountNumber == null || accountNumber!.length < 4) return '****';
    return '****${accountNumber!.substring(accountNumber!.length - 4)}';
  }
}