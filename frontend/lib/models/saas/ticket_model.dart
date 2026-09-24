// frontend/lib/models/saas/ticket_model.dart
import 'package:flutter/foundation.dart';

/// SaasTicketItem
///
/// Representa un ítem individual dentro de un ticket de servicio (SERVICE o CUSTOM).
@immutable
class SaasTicketItem {
  final String id;
  final String ticketId;
  final int? tenantId;
  final String? establishmentId;
  final String itemType; // 'SERVICE' | 'CUSTOM'
  final String? serviceOfferId;
  final String performedByMembershipId;
  final String? performerName;
  final String titleSnapshot;
  final int quantity;
  final double unitPriceSnapshot;
  final double discountAmount;
  final double totalAmount;
  final String? createdAt;
  final String? updatedAt;

  const SaasTicketItem({
    required this.id,
    required this.ticketId,
    this.tenantId,
    this.establishmentId,
    required this.itemType,
    this.serviceOfferId,
    required this.performedByMembershipId,
    this.performerName,
    required this.titleSnapshot,
    this.quantity = 1,
    required this.unitPriceSnapshot,
    this.discountAmount = 0.00,
    required this.totalAmount,
    this.createdAt,
    this.updatedAt,
  });

  bool get isService => itemType == 'SERVICE';
  bool get isCustom => itemType == 'CUSTOM';
  double get computedSubtotal => unitPriceSnapshot * quantity;
  double get lineTotal => totalAmount;

  factory SaasTicketItem.fromJson(Map<String, dynamic> json) {
    return SaasTicketItem(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticket_id']?.toString() ?? '',
      tenantId: json['tenant_id'] is num ? (json['tenant_id'] as num).toInt() : null,
      establishmentId: json['establishment_id']?.toString(),
      itemType: json['item_type']?.toString() ?? 'SERVICE',
      serviceOfferId: json['service_offer_id']?.toString(),
      performedByMembershipId: json['performed_by_membership_id']?.toString() ?? '',
      performerName: json['performer_name']?.toString(),
      titleSnapshot: json['title_snapshot']?.toString() ?? '',
      quantity: json['quantity'] is num ? (json['quantity'] as num).toInt() : 1,
      unitPriceSnapshot: json['unit_price_snapshot'] is num
          ? (json['unit_price_snapshot'] as num).toDouble()
          : double.tryParse(json['unit_price_snapshot']?.toString() ?? '0') ?? 0.0,
      discountAmount: json['discount_amount'] is num
          ? (json['discount_amount'] as num).toDouble()
          : double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      totalAmount: json['total_amount'] is num
          ? (json['total_amount'] as num).toDouble()
          : double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (establishmentId != null) 'establishment_id': establishmentId,
      'item_type': itemType,
      if (serviceOfferId != null) 'service_offer_id': serviceOfferId,
      'performed_by_membership_id': performedByMembershipId,
      if (performerName != null) 'performer_name': performerName,
      'title_snapshot': titleSnapshot,
      'quantity': quantity,
      'unit_price_snapshot': unitPriceSnapshot,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

/// SaasTicketPayment
///
/// Representa un pago registrado sobre un ticket de servicio.
@immutable
class SaasTicketPayment {
  final String id;
  final String ticketId;
  final int? tenantId;
  final String? establishmentId;
  final String paymentMethod; // 'CASH' | 'CARD' | 'TRANSFER' | 'OTHER'
  final double amount;
  final String? referenceCode;
  final String receivedByMembershipId;
  final String? receiverName;
  final String? createdAt;

  const SaasTicketPayment({
    required this.id,
    required this.ticketId,
    this.tenantId,
    this.establishmentId,
    required this.paymentMethod,
    required this.amount,
    this.referenceCode,
    required this.receivedByMembershipId,
    this.receiverName,
    this.createdAt,
  });

  factory SaasTicketPayment.fromJson(Map<String, dynamic> json) {
    return SaasTicketPayment(
      id: json['id']?.toString() ?? '',
      ticketId: json['ticket_id']?.toString() ?? '',
      tenantId: json['tenant_id'] is num ? (json['tenant_id'] as num).toInt() : null,
      establishmentId: json['establishment_id']?.toString(),
      paymentMethod: json['payment_method']?.toString() ?? 'CASH',
      amount: json['amount'] is num
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      referenceCode: json['reference_code']?.toString(),
      receivedByMembershipId: json['received_by_membership_id']?.toString() ?? '',
      receiverName: json['receiver_name']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      if (tenantId != null) 'tenant_id': tenantId,
      if (establishmentId != null) 'establishment_id': establishmentId,
      'payment_method': paymentMethod,
      'amount': amount,
      if (referenceCode != null) 'reference_code': referenceCode,
      'received_by_membership_id': receivedByMembershipId,
      if (receiverName != null) 'receiver_name': receiverName,
      if (createdAt != null) 'created_at': createdAt,
    };
  }
}

/// SaasServiceTicket
///
/// Representa el ticket de servicio y checkout completo en GlowApp SaaS.
@immutable
class SaasServiceTicket {
  final String id;
  final int tenantId;
  final String establishmentId;
  final String ticketNumber; // TICK-000001
  final String? appointmentId;

  // Cliente Dual XOR
  final String clientMode; // 'GUEST' | 'REGISTERED'
  final int? customerUserId;
  final String? guestNameSnapshot;
  final String? guestPhoneSnapshot;
  final String? guestEmailSnapshot;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;

  // Máquina de Estados
  final String status; // 'DRAFT' | 'OPEN' | 'PAID' | 'CLOSED' | 'VOID'

  // Componentes Financieros Server-Calculated
  final double subtotalAmount;
  final double discountAmount;
  final String? discountReason;
  final double taxAmount;
  final double tipAmount;
  final double totalAmount;
  final double paidAmount;
  final double balanceDue;

  final String? notes;
  final String createdByMembershipId;
  final String? closedByMembershipId;
  final String? voidedByMembershipId;
  final String? voidReason;

  final String? createdAt;
  final String? updatedAt;
  final String? closedAt;
  final String? voidedAt;

  final List<SaasTicketItem> items;
  final List<SaasTicketPayment> payments;
  final int itemsCount;
  final int paymentsCount;

  const SaasServiceTicket({
    required this.id,
    required this.tenantId,
    required this.establishmentId,
    required this.ticketNumber,
    this.appointmentId,
    required this.clientMode,
    this.customerUserId,
    this.guestNameSnapshot,
    this.guestPhoneSnapshot,
    this.guestEmailSnapshot,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    required this.status,
    required this.subtotalAmount,
    this.discountAmount = 0.00,
    this.discountReason,
    this.taxAmount = 0.00,
    this.tipAmount = 0.00,
    required this.totalAmount,
    this.paidAmount = 0.00,
    required this.balanceDue,
    this.notes,
    required this.createdByMembershipId,
    this.closedByMembershipId,
    this.voidedByMembershipId,
    this.voidReason,
    this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.voidedAt,
    this.items = const [],
    this.payments = const [],
    this.itemsCount = 0,
    this.paymentsCount = 0,
  });

  bool get isDraft => status == 'DRAFT';
  bool get isOpen => status == 'OPEN';
  bool get isPaid => status == 'PAID';
  bool get isClosed => status == 'CLOSED';
  bool get isVoid => status == 'VOID';

  bool get isGuest => clientMode == 'GUEST';
  bool get isRegistered => clientMode == 'REGISTERED';

  String? get guestName => guestNameSnapshot;
  double get totalPaid => paidAmount;

  bool get isEditable => isDraft;
  bool get canAcceptPayments => isOpen;
  bool get canBeClosed => isPaid || (balanceDue <= 0.0001 && !isClosed && !isVoid && !isDraft);
  bool get canBeVoided => !isClosed && !isVoid;

  String get clientDisplayName {
    if (isRegistered) {
      if (customerName != null && customerName!.trim().isNotEmpty) {
        return customerName!.trim();
      }
      return 'Usuario #$customerUserId';
    }
    return guestNameSnapshot ?? 'Invitado';
  }

  factory SaasServiceTicket.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] is List ? json['items'] as List : [];
    final itemsList = rawItems
        .whereType<Map<String, dynamic>>()
        .map((e) => SaasTicketItem.fromJson(e))
        .toList();

    final rawPayments = json['payments'] is List ? json['payments'] as List : [];
    final paymentsList = rawPayments
        .whereType<Map<String, dynamic>>()
        .map((e) => SaasTicketPayment.fromJson(e))
        .toList();

    return SaasServiceTicket(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id'] is num ? (json['tenant_id'] as num).toInt() : 0,
      establishmentId: json['establishment_id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? '',
      appointmentId: json['appointment_id']?.toString(),
      clientMode: json['client_mode']?.toString() ?? 'GUEST',
      customerUserId: json['customer_user_id'] is num ? (json['customer_user_id'] as num).toInt() : null,
      guestNameSnapshot: json['guest_name_snapshot']?.toString(),
      guestPhoneSnapshot: json['guest_phone_snapshot']?.toString(),
      guestEmailSnapshot: json['guest_email_snapshot']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerEmail: json['customer_email']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      status: json['status']?.toString() ?? 'DRAFT',
      subtotalAmount: json['subtotal_amount'] is num
          ? (json['subtotal_amount'] as num).toDouble()
          : double.tryParse(json['subtotal_amount']?.toString() ?? '0') ?? 0.0,
      discountAmount: json['discount_amount'] is num
          ? (json['discount_amount'] as num).toDouble()
          : double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      discountReason: json['discount_reason']?.toString(),
      taxAmount: json['tax_amount'] is num
          ? (json['tax_amount'] as num).toDouble()
          : double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0.0,
      tipAmount: json['tip_amount'] is num
          ? (json['tip_amount'] as num).toDouble()
          : double.tryParse(json['tip_amount']?.toString() ?? '0') ?? 0.0,
      totalAmount: json['total_amount'] is num
          ? (json['total_amount'] as num).toDouble()
          : double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paidAmount: json['paid_amount'] is num
          ? (json['paid_amount'] as num).toDouble()
          : double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      balanceDue: json['balance_due'] is num
          ? (json['balance_due'] as num).toDouble()
          : double.tryParse(json['balance_due']?.toString() ?? '0') ?? 0.0,
      notes: json['notes']?.toString(),
      createdByMembershipId: json['created_by_membership_id']?.toString() ?? '',
      closedByMembershipId: json['closed_by_membership_id']?.toString(),
      voidedByMembershipId: json['voided_by_membership_id']?.toString(),
      voidReason: json['void_reason']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      closedAt: json['closed_at']?.toString(),
      voidedAt: json['voided_at']?.toString(),
      items: itemsList,
      payments: paymentsList,
      itemsCount: json['items_count'] is num ? (json['items_count'] as num).toInt() : itemsList.length,
      paymentsCount: json['payments_count'] is num ? (json['payments_count'] as num).toInt() : paymentsList.length,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'establishment_id': establishmentId,
      'ticket_number': ticketNumber,
      if (appointmentId != null) 'appointment_id': appointmentId,
      'client_mode': clientMode,
      if (customerUserId != null) 'customer_user_id': customerUserId,
      if (guestNameSnapshot != null) 'guest_name_snapshot': guestNameSnapshot,
      if (guestPhoneSnapshot != null) 'guest_phone_snapshot': guestPhoneSnapshot,
      if (guestEmailSnapshot != null) 'guest_email_snapshot': guestEmailSnapshot,
      if (customerName != null) 'customer_name': customerName,
      if (customerEmail != null) 'customer_email': customerEmail,
      if (customerPhone != null) 'customer_phone': customerPhone,
      'status': status,
      'subtotal_amount': subtotalAmount,
      'discount_amount': discountAmount,
      if (discountReason != null) 'discount_reason': discountReason,
      'tax_amount': taxAmount,
      'tip_amount': tipAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'balance_due': balanceDue,
      if (notes != null) 'notes': notes,
      'created_by_membership_id': createdByMembershipId,
      if (closedByMembershipId != null) 'closed_by_membership_id': closedByMembershipId,
      if (voidedByMembershipId != null) 'voided_by_membership_id': voidedByMembershipId,
      if (voidReason != null) 'void_reason': voidReason,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (closedAt != null) 'closed_at': closedAt,
      if (voidedAt != null) 'voided_at': voidedAt,
      'items': items.map((e) => e.toJson()).toList(),
      'payments': payments.map((e) => e.toJson()).toList(),
      'items_count': itemsCount,
      'payments_count': paymentsCount,
    };
  }
}

/// TicketListResult
@immutable
class TicketListResult {
  final List<SaasServiceTicket> tickets;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const TicketListResult({
    required this.tickets,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory TicketListResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['tickets'] is List ? json['tickets'] as List : [];
    final tickets = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => SaasServiceTicket.fromJson(e))
        .toList();

    final pagination = json['pagination'] is Map<String, dynamic>
        ? json['pagination'] as Map<String, dynamic>
        : {};

    return TicketListResult(
      tickets: tickets,
      total: pagination['total'] is num ? (pagination['total'] as num).toInt() : tickets.length,
      page: pagination['page'] is num ? (pagination['page'] as num).toInt() : 1,
      limit: pagination['limit'] is num ? (pagination['limit'] as num).toInt() : 20,
      totalPages: pagination['totalPages'] is num ? (pagination['totalPages'] as num).toInt() : 1,
    );
  }
}
