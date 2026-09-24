// frontend/lib/models/saas/saas_cash_model.dart
// GO-08.53: SaaS Cash Drawer Models & DTOs

/// SaasCashException
///
/// Excepción tipificada para capturar errores del subsistema de Cash Drawer.
class SaasCashException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  SaasCashException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  bool get isDrawerAlreadyOpen => errorCode == 'CASH_DRAWER_ALREADY_OPEN' || statusCode == 409;
  bool get isDrawerNotOpen => errorCode == 'CASH_DRAWER_NOT_OPEN' || statusCode == 422;
  bool get isInsufficientFunds => errorCode == 'INSUFFICIENT_DRAWER_FUNDS' || statusCode == 422;
  bool get isForbidden => errorCode == 'FORBIDDEN_ROLE' || statusCode == 403;
  bool get isNotFound => errorCode == 'SESSION_NOT_FOUND' || statusCode == 404;

  @override
  String toString() =>
      'SaasCashException: $message ${errorCode != null ? '[$errorCode]' : ''} ${statusCode != null ? '(Status: $statusCode)' : ''}';
}

/// SaasCashMovement
///
/// Representa un movimiento individual dentro de un turno de caja.
class SaasCashMovement {
  final String id;
  final String sessionId;
  final String movementType; // 'OPENING' | 'CASH_SALE' | 'CASH_IN' | 'CASH_OUT' | 'CLOSING'
  final String? category; // 'BASE_ADICIONAL', 'CAMBIO_SENCILLO', 'GASTO_MENOR', 'ANTICIPO_PROPINA', etc.
  final double amount;
  final String? reason;
  final String? notes;
  final int? performedByUserId;
  final String? performedByUserName;
  final String? ticketId;
  final String? ticketNumber;
  final String? paymentId;
  final DateTime createdAt;

  const SaasCashMovement({
    required this.id,
    required this.sessionId,
    required this.movementType,
    this.category,
    required this.amount,
    this.reason,
    this.notes,
    this.performedByUserId,
    this.performedByUserName,
    this.ticketId,
    this.ticketNumber,
    this.paymentId,
    required this.createdAt,
  });

  bool get isOpening => movementType == 'OPENING';
  bool get isCashSale => movementType == 'CASH_SALE';
  bool get isCashIn => movementType == 'CASH_IN';
  bool get isCashOut => movementType == 'CASH_OUT';
  bool get isClosing => movementType == 'CLOSING';

  factory SaasCashMovement.fromJson(Map<String, dynamic> json) {
    String? performedByName;
    int? performedById;
    if (json['performed_by'] is Map) {
      final pb = json['performed_by'] as Map<String, dynamic>;
      performedByName = pb['name'] as String?;
      performedById = (pb['user_id'] as num?)?.toInt();
    } else {
      performedByName = json['performed_by_user_name'] as String? ?? json['performed_by_name'] as String?;
      performedById = (json['performed_by_user_id'] as num?)?.toInt();
    }

    return SaasCashMovement(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      movementType: (json['movement_type'] as String? ?? 'CASH_IN').toUpperCase(),
      category: json['category'] as String?,
      amount: double.tryParse(json['amount']?.toString() ?? '0.0') ?? 0.0,
      reason: json['reason'] as String?,
      notes: json['notes'] as String?,
      performedByUserId: performedById,
      performedByUserName: performedByName ?? 'Operador',
      ticketId: json['ticket_id'] as String?,
      ticketNumber: json['ticket_number'] as String?,
      paymentId: json['payment_id'] as String? ?? json['ticket_payment_id'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'session_id': sessionId,
    'movement_type': movementType,
    'category': category,
    'amount': amount,
    'reason': reason,
    'notes': notes,
    'performed_by_user_id': performedByUserId,
    'performed_by_user_name': performedByUserName,
    'ticket_id': ticketId,
    'ticket_number': ticketNumber,
    'payment_id': paymentId,
    'created_at': createdAt.toIso8601String(),
  };
}

/// SaasCashSession
///
/// Representa una sesión de turno de caja (abierta o cerrada).
class SaasCashSession {
  final String id;
  final String tenantId;
  final String establishmentId;
  final int? openedByUserId;
  final String? openedByUserName;
  final int? closedByUserId;
  final String? closedByUserName;
  final String status; // 'OPEN' | 'CLOSED'
  final DateTime openedAt;
  final DateTime? closedAt;
  final double openingBalance;
  final String? openingNotes;
  final String? closingNotes;
  final double cashSalesTotal;
  final double cashInTotal;
  final double cashOutTotal;
  final double? expectedCash; // Null if RECEPTIONIST (Blind Close)
  final double? countedCash;
  final double? difference;
  final String? reconciliationStatus; // 'BALANCED' | 'SURPLUS' | 'SHORTAGE'
  final List<SaasCashMovement> movements;

  const SaasCashSession({
    required this.id,
    required this.tenantId,
    required this.establishmentId,
    this.openedByUserId,
    this.openedByUserName,
    this.closedByUserId,
    this.closedByUserName,
    required this.status,
    required this.openedAt,
    this.closedAt,
    required this.openingBalance,
    this.openingNotes,
    this.closingNotes,
    this.cashSalesTotal = 0.0,
    this.cashInTotal = 0.0,
    this.cashOutTotal = 0.0,
    this.expectedCash,
    this.countedCash,
    this.difference,
    this.reconciliationStatus,
    this.movements = const [],
  });

  bool get isOpen => status == 'OPEN';
  bool get isClosed => status == 'CLOSED';

  factory SaasCashSession.fromJson(Map<String, dynamic> json) {
    String? openedName;
    int? openedId;
    if (json['opened_by'] is Map) {
      final ob = json['opened_by'] as Map<String, dynamic>;
      openedName = ob['name'] as String?;
      openedId = (ob['user_id'] as num?)?.toInt();
    } else {
      openedName = json['opened_by_user_name'] as String? ?? json['opened_by_name'] as String?;
      openedId = (json['opened_by_user_id'] as num?)?.toInt();
    }

    String? closedName;
    int? closedId;
    if (json['closed_by'] is Map) {
      final cb = json['closed_by'] as Map<String, dynamic>;
      closedName = cb['name'] as String?;
      closedId = (cb['user_id'] as num?)?.toInt();
    } else {
      closedName = json['closed_by_user_name'] as String? ?? json['closed_by_name'] as String?;
      closedId = (json['closed_by_user_id'] as num?)?.toInt();
    }

    // Extract metrics either from nested metrics or top level
    double sales = 0.0;
    double cashIn = 0.0;
    double cashOut = 0.0;
    double? expected;

    if (json['metrics'] is Map) {
      final m = json['metrics'] as Map<String, dynamic>;
      sales = double.tryParse(m['cash_sales_total']?.toString() ?? '0.0') ?? 0.0;
      cashIn = double.tryParse(m['cash_in_total']?.toString() ?? '0.0') ?? 0.0;
      cashOut = double.tryParse(m['cash_out_total']?.toString() ?? '0.0') ?? 0.0;
      if (m['expected_cash'] != null) {
        expected = double.tryParse(m['expected_cash'].toString());
      }
    } else {
      sales = double.tryParse(json['cash_sales_total']?.toString() ?? '0.0') ?? 0.0;
      cashIn = double.tryParse(json['cash_in_total']?.toString() ?? '0.0') ?? 0.0;
      cashOut = double.tryParse(json['cash_out_total']?.toString() ?? '0.0') ?? 0.0;
      if (json['expected_cash'] != null) {
        expected = double.tryParse(json['expected_cash'].toString());
      }
    }

    final rawMovements = json['movements'] as List<dynamic>? ?? [];
    final parsedMovements = rawMovements.map((m) => SaasCashMovement.fromJson(m as Map<String, dynamic>)).toList();

    return SaasCashSession(
      id: json['id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      establishmentId: json['establishment_id'] as String? ?? '',
      openedByUserId: openedId,
      openedByUserName: openedName ?? 'Operador',
      closedByUserId: closedId,
      closedByUserName: closedName,
      status: (json['status'] as String? ?? 'OPEN').toUpperCase(),
      openedAt: json['opened_at'] != null ? DateTime.parse(json['opened_at'] as String) : DateTime.now(),
      closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at'] as String) : null,
      openingBalance: double.tryParse(json['opening_balance']?.toString() ?? '0.0') ?? 0.0,
      openingNotes: json['opening_notes'] as String?,
      closingNotes: json['closing_notes'] as String?,
      cashSalesTotal: sales,
      cashInTotal: cashIn,
      cashOutTotal: cashOut,
      expectedCash: expected,
      countedCash: json['counted_cash'] != null ? double.tryParse(json['counted_cash'].toString()) : null,
      difference: json['difference'] != null ? double.tryParse(json['difference'].toString()) : null,
      reconciliationStatus: json['reconciliation_status'] as String?,
      movements: parsedMovements,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'tenant_id': tenantId,
    'establishment_id': establishmentId,
    'opened_by_user_id': openedByUserId,
    'opened_by_user_name': openedByUserName,
    'closed_by_user_id': closedByUserId,
    'closed_by_user_name': closedByUserName,
    'status': status,
    'opened_at': openedAt.toIso8601String(),
    'closed_at': closedAt?.toIso8601String(),
    'opening_balance': openingBalance,
    'opening_notes': openingNotes,
    'closing_notes': closingNotes,
    'cash_sales_total': cashSalesTotal,
    'cash_in_total': cashInTotal,
    'cash_out_total': cashOutTotal,
    'expected_cash': expectedCash,
    'counted_cash': countedCash,
    'difference': difference,
    'reconciliation_status': reconciliationStatus,
    'movements': movements.map((m) => m.toJson()).toList(),
  };
}

/// SaasCashReconciliation
///
/// Resultado de la conciliación al cerrar un turno.
class SaasCashReconciliation {
  final String sessionId;
  final String status;
  final String reconciliationStatus; // 'BALANCED' | 'SURPLUS' | 'SHORTAGE'
  final double openingBalance;
  final double cashSalesTotal;
  final double cashInTotal;
  final double cashOutTotal;
  final double expectedCash;
  final double countedCash;
  final double difference;
  final String? notes;
  final DateTime? closedAt;

  const SaasCashReconciliation({
    required this.sessionId,
    required this.status,
    required this.reconciliationStatus,
    this.openingBalance = 0.0,
    this.cashSalesTotal = 0.0,
    this.cashInTotal = 0.0,
    this.cashOutTotal = 0.0,
    required this.expectedCash,
    required this.countedCash,
    required this.difference,
    this.notes,
    this.closedAt,
  });

  bool get isBalanced => reconciliationStatus == 'BALANCED';
  bool get isSurplus => reconciliationStatus == 'SURPLUS';
  bool get isShortage => reconciliationStatus == 'SHORTAGE';

  factory SaasCashReconciliation.fromJson(Map<String, dynamic> json) {
    return SaasCashReconciliation(
      sessionId: json['session_id'] as String? ?? json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'CLOSED',
      reconciliationStatus: (json['reconciliation_status'] as String? ?? 'BALANCED').toUpperCase(),
      openingBalance: double.tryParse(json['opening_balance']?.toString() ?? '0.0') ?? 0.0,
      cashSalesTotal: double.tryParse(json['cash_sales_total']?.toString() ?? '0.0') ?? 0.0,
      cashInTotal: double.tryParse(json['cash_in_total']?.toString() ?? '0.0') ?? 0.0,
      cashOutTotal: double.tryParse(json['cash_out_total']?.toString() ?? '0.0') ?? 0.0,
      expectedCash: double.tryParse(json['expected_cash']?.toString() ?? '0.0') ?? 0.0,
      countedCash: double.tryParse(json['counted_cash']?.toString() ?? '0.0') ?? 0.0,
      difference: double.tryParse(json['difference']?.toString() ?? '0.0') ?? 0.0,
      notes: json['notes'] as String? ?? json['closing_notes'] as String?,
      closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at'] as String) : null,
    );
  }
}

/// SaasCashStatusResponse
///
/// Respuesta de GET /api/saas/cash/current
class SaasCashStatusResponse {
  final bool isOpen;
  final SaasCashSession? session;
  final String? role;

  const SaasCashStatusResponse({
    required this.isOpen,
    this.session,
    this.role,
  });

  factory SaasCashStatusResponse.fromJson(Map<String, dynamic> json) {
    final isOpen = json['is_open'] as bool? ?? false;
    final sessionMap = json['session'] as Map<String, dynamic>?;
    return SaasCashStatusResponse(
      isOpen: isOpen,
      session: sessionMap != null ? SaasCashSession.fromJson(sessionMap) : null,
      role: json['role'] as String?,
    );
  }
}

/// SaasCashHistoryResponse
///
/// Respuesta de GET /api/saas/cash/history
class SaasCashHistoryResponse {
  final List<SaasCashSession> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const SaasCashHistoryResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory SaasCashHistoryResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? json['sessions'] as List<dynamic>? ?? [];
    final items = rawItems.map((s) => SaasCashSession.fromJson(s as Map<String, dynamic>)).toList();
    final total = (json['total'] as num?)?.toInt() ?? items.length;
    final page = (json['page'] as num?)?.toInt() ?? 1;
    final limit = (json['limit'] as num?)?.toInt() ?? 20;
    final totalPages = (json['total_pages'] as num?)?.toInt() ?? ((total / limit).ceil() > 0 ? (total / limit).ceil() : 1);

    return SaasCashHistoryResponse(
      items: items,
      total: total,
      page: page,
      limit: limit,
      totalPages: totalPages,
    );
  }
}

/// SaasCashSessionDetail
///
/// Detalle completo de una sesión con sus movimientos
class SaasCashSessionDetail {
  final SaasCashSession session;
  final List<SaasCashMovement> movements;

  const SaasCashSessionDetail({
    required this.session,
    required this.movements,
  });

  factory SaasCashSessionDetail.fromJson(Map<String, dynamic> json) {
    final sessionMap = json['session'] is Map<String, dynamic>
        ? json['session'] as Map<String, dynamic>
        : json;
    final rawMovements = json['movements'] as List<dynamic>? ?? [];
    return SaasCashSessionDetail(
      session: SaasCashSession.fromJson(sessionMap),
      movements: rawMovements.map((m) => SaasCashMovement.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }
}
