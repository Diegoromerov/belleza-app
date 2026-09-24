// frontend/lib/services/saas/saas_tickets_service.dart
import '../../models/saas/ticket_model.dart';
import '../api_service.dart';

/// SaasTicketException
///
/// Excepción tipificada para capturar errores del subsistema de Service Tickets / Checkout.
class SaasTicketException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  SaasTicketException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  bool get isOverpayment => errorCode == 'OVERPAYMENT_NOT_ALLOWED';
  bool get isUnauthorized => errorCode == 'UNAUTHORIZED_ROLE' || statusCode == 403;
  bool get isNotFound => errorCode == 'TICKET_NOT_FOUND' || statusCode == 404;
  bool get isAlreadyTicketed => errorCode == 'APPOINTMENT_ALREADY_TICKETED' || statusCode == 409;

  @override
  String toString() =>
      'SaasTicketException: $message ${errorCode != null ? '[$errorCode]' : ''} ${statusCode != null ? '(Status: $statusCode)' : ''}';
}

/// SaasTicketsService
///
/// Servicio cliente para el dominio POS / Service Ticket & Financial Checkout (SCR-12).
/// Consume exclusivamente los 11 endpoints de /api/saas/tickets/*.
class SaasTicketsService {
  final Future<dynamic> Function(String path) _apiGet;
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPost;
  final Future<dynamic> Function(String path, Map<String, dynamic> body) _apiPatch;
  final Future<dynamic> Function(String path, [Map<String, dynamic>? body]) _apiDelete;

  SaasTicketsService({
    Future<dynamic> Function(String path)? apiGet,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPost,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPatch,
    Future<dynamic> Function(String path, [Map<String, dynamic>? body])? apiDelete,
  })  : _apiGet = apiGet ?? ApiService.get,
        _apiPost = apiPost ?? ApiService.post,
        _apiPatch = apiPatch ?? ApiService.patch,
        _apiDelete = apiDelete ?? ApiService.delete;

  // 1. POST /api/saas/tickets — Crear ticket (DRAFT)
  Future<SaasServiceTicket> createTicket({
    String? appointmentId,
    String clientMode = 'GUEST',
    int? customerUserId,
    String? guestName,
    String? guestPhone,
    String? guestEmail,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      if (appointmentId != null && appointmentId.isNotEmpty) 'appointment_id': appointmentId,
      'client_mode': clientMode,
      if (clientMode == 'REGISTERED' && customerUserId != null) 'customer_user_id': customerUserId,
      if (clientMode == 'GUEST' && guestName != null) 'guest_name': guestName.trim(),
      if (clientMode == 'GUEST' && guestPhone != null && guestPhone.trim().isNotEmpty)
        'guest_phone': guestPhone.trim(),
      if (clientMode == 'GUEST' && guestEmail != null && guestEmail.trim().isNotEmpty)
        'guest_email': guestEmail.trim(),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    try {
      final response = await _apiPost('/api/saas/tickets', body);
      if (response is Map<String, dynamic>) {
        final ticketMap = response['ticket'] is Map<String, dynamic>
            ? response['ticket'] as Map<String, dynamic>
            : response;
        return SaasServiceTicket.fromJson(ticketMap);
      }
      throw SaasTicketException(message: 'Respuesta inválida al crear ticket.');
    } catch (e) {
      throw _handleError(e, 'Error al crear ticket de servicio.');
    }
  }

  // 2. POST /api/saas/tickets/:id/items — Agregar ítem
  Future<Map<String, dynamic>> addItem(
    String ticketId, {
    String itemType = 'SERVICE',
    String? serviceOfferId,
    String? performedByMembershipId,
    int quantity = 1,
    String? title,
    String? titleSnapshot,
    double? unitPrice,
    double? unitPriceSnapshot,
    double discountAmount = 0.00,
  }) async {
    final effectiveTitle = titleSnapshot ?? title;
    final effectivePrice = unitPriceSnapshot ?? unitPrice;

    final body = <String, dynamic>{
      'item_type': itemType,
      if (serviceOfferId != null) 'service_offer_id': serviceOfferId,
      if (performedByMembershipId != null) 'performed_by_membership_id': performedByMembershipId,
      'quantity': quantity,
      if (effectiveTitle != null && effectiveTitle.trim().isNotEmpty) 'title': effectiveTitle.trim(),
      if (effectivePrice != null) 'unit_price': effectivePrice,
      'discount_amount': discountAmount,
    };

    try {
      final response = await _apiPost('/api/saas/tickets/$ticketId/items', body);
      if (response is Map<String, dynamic>) {
        final item = response['item'] is Map<String, dynamic>
            ? SaasTicketItem.fromJson(response['item'] as Map<String, dynamic>)
            : null;
        final ticket = response['ticket'] is Map<String, dynamic>
            ? SaasServiceTicket.fromJson(response['ticket'] as Map<String, dynamic>)
            : (response['id'] != null ? SaasServiceTicket.fromJson(response) : null);
        return {'item': item, 'ticket': ticket};
      }
      throw SaasTicketException(message: 'Respuesta inválida al agregar ítem al ticket.');
    } catch (e) {
      throw _handleError(e, 'Error al agregar ítem al ticket.');
    }
  }

  // 3. PATCH /api/saas/tickets/:id/items/:itemId — Modificar ítem
  Future<Map<String, dynamic>> updateItem(
    String ticketId,
    String itemId, {
    int? quantity,
    double? discountAmount,
    String? title,
    String? titleSnapshot,
    double? unitPrice,
    double? unitPriceSnapshot,
  }) async {
    final effectiveTitle = titleSnapshot ?? title;
    final effectivePrice = unitPriceSnapshot ?? unitPrice;

    final body = <String, dynamic>{
      if (quantity != null) 'quantity': quantity,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (effectiveTitle != null) 'title': effectiveTitle.trim(),
      if (effectivePrice != null) 'unit_price': effectivePrice,
    };

    try {
      final response = await _apiPatch('/api/saas/tickets/$ticketId/items/$itemId', body);
      if (response is Map<String, dynamic>) {
        final item = response['item'] is Map<String, dynamic>
            ? SaasTicketItem.fromJson(response['item'] as Map<String, dynamic>)
            : null;
        final ticket = response['ticket'] is Map<String, dynamic>
            ? SaasServiceTicket.fromJson(response['ticket'] as Map<String, dynamic>)
            : (response['id'] != null ? SaasServiceTicket.fromJson(response) : null);
        return {'item': item, 'ticket': ticket};
      }
      throw SaasTicketException(message: 'Respuesta inválida al actualizar ítem.');
    } catch (e) {
      throw _handleError(e, 'Error al actualizar ítem del ticket.');
    }
  }

  // 4. DELETE /api/saas/tickets/:id/items/:itemId — Eliminar ítem
  Future<SaasServiceTicket> deleteItem(String ticketId, String itemId) async {
    try {
      final response = await _apiDelete('/api/saas/tickets/$ticketId/items/$itemId');
      if (response is Map<String, dynamic>) {
        final ticketMap = response['ticket'] is Map<String, dynamic>
            ? response['ticket'] as Map<String, dynamic>
            : response;
        return SaasServiceTicket.fromJson(ticketMap);
      }
      throw SaasTicketException(message: 'Respuesta inválida al eliminar ítem.');
    } catch (e) {
      throw _handleError(e, 'Error al eliminar ítem del ticket.');
    }
  }

  /// Alias de eliminación para compatibilidad de interfaz
  Future<SaasServiceTicket> removeItem(String ticketId, String itemId) => deleteItem(ticketId, itemId);

  // 5. PATCH /api/saas/tickets/:id/adjustments — Ajustes de cabecera
  Future<SaasServiceTicket> applyAdjustments(
    String ticketId, {
    double? discountAmount,
    String? discountReason,
    double? tipAmount,
    double? taxAmount,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (discountReason != null) 'discount_reason': discountReason.trim(),
      if (tipAmount != null) 'tip_amount': tipAmount,
      if (taxAmount != null) 'tax_amount': taxAmount,
      if (notes != null) 'notes': notes.trim(),
    };

    try {
      final response = await _apiPatch('/api/saas/tickets/$ticketId/adjustments', body);
      if (response is Map<String, dynamic>) {
        final ticketMap = response['ticket'] is Map<String, dynamic>
            ? response['ticket'] as Map<String, dynamic>
            : response;
        return SaasServiceTicket.fromJson(ticketMap);
      }
      throw SaasTicketException(message: 'Respuesta inválida al aplicar ajustes.');
    } catch (e) {
      throw _handleError(e, 'Error al aplicar ajustes al ticket.');
    }
  }

  // 6. POST /api/saas/tickets/:id/confirm — Confirmar ticket (DRAFT -> OPEN)
  Future<SaasServiceTicket> confirmTicket(String ticketId) async {
    try {
      final response = await _apiPost('/api/saas/tickets/$ticketId/confirm', {});
      if (response is Map<String, dynamic>) {
        final ticketMap = response['ticket'] is Map<String, dynamic>
            ? response['ticket'] as Map<String, dynamic>
            : response;
        return SaasServiceTicket.fromJson(ticketMap);
      }
      throw SaasTicketException(message: 'Respuesta inválida al confirmar ticket.');
    } catch (e) {
      throw _handleError(e, 'Error al confirmar ticket.');
    }
  }

  // 7. POST /api/saas/tickets/:id/payments — Registrar pago (Split Tender)
  Future<Map<String, dynamic>> addPayment(
    String ticketId, {
    required String paymentMethod,
    required double amount,
    String? referenceCode,
  }) async {
    final body = <String, dynamic>{
      'payment_method': paymentMethod,
      'amount': amount,
      if (referenceCode != null && referenceCode.trim().isNotEmpty)
        'reference_code': referenceCode.trim(),
    };

    try {
      final response = await _apiPost('/api/saas/tickets/$ticketId/payments', body);
      if (response is Map<String, dynamic>) {
        final payment = response['payment'] is Map<String, dynamic>
            ? SaasTicketPayment.fromJson(response['payment'] as Map<String, dynamic>)
            : null;
        final ticket = response['ticket'] is Map<String, dynamic>
            ? SaasServiceTicket.fromJson(response['ticket'] as Map<String, dynamic>)
            : (response['id'] != null ? SaasServiceTicket.fromJson(response) : null);
        return {'payment': payment, 'ticket': ticket};
      }
      throw SaasTicketException(message: 'Respuesta inválida al registrar pago.');
    } catch (e) {
      throw _handleError(e, 'Error al registrar pago.');
    }
  }

  // 8. POST /api/saas/tickets/:id/close — Cerrar ticket (PAID -> CLOSED)
  Future<SaasServiceTicket> closeTicket(String ticketId) async {
    try {
      final response = await _apiPost('/api/saas/tickets/$ticketId/close', {});
      if (response is Map<String, dynamic>) {
        final ticketMap = response['ticket'] is Map<String, dynamic>
            ? response['ticket'] as Map<String, dynamic>
            : response;
        return SaasServiceTicket.fromJson(ticketMap);
      }
      throw SaasTicketException(message: 'Respuesta inválida al cerrar ticket.');
    } catch (e) {
      throw _handleError(e, 'Error al cerrar ticket.');
    }
  }

  // 9. POST /api/saas/tickets/:id/void — Anular ticket (VOID)
  Future<SaasServiceTicket> voidTicket(String ticketId, {required String reason}) async {
    final body = <String, dynamic>{'reason': reason.trim()};
    try {
      final response = await _apiPost('/api/saas/tickets/$ticketId/void', body);
      if (response is Map<String, dynamic>) {
        final ticketMap = response['ticket'] is Map<String, dynamic>
            ? response['ticket'] as Map<String, dynamic>
            : response;
        return SaasServiceTicket.fromJson(ticketMap);
      }
      throw SaasTicketException(message: 'Respuesta inválida al anular ticket.');
    } catch (e) {
      throw _handleError(e, 'Error al anular ticket.');
    }
  }

  // 10. GET /api/saas/tickets/:id — Detalle completo del ticket
  Future<SaasServiceTicket> getTicketById(String ticketId) async {
    try {
      final response = await _apiGet('/api/saas/tickets/$ticketId');
      if (response is Map<String, dynamic>) {
        final ticketMap = response['ticket'] is Map<String, dynamic>
            ? response['ticket'] as Map<String, dynamic>
            : response;
        return SaasServiceTicket.fromJson(ticketMap);
      }
      throw SaasTicketException(message: 'Respuesta inválida al consultar ticket.');
    } catch (e) {
      throw _handleError(e, 'Error al consultar detalle del ticket.');
    }
  }

  // 11. GET /api/saas/tickets — Listar tickets
  Future<TicketListResult> listTickets({
    String? status,
    String? dateFrom,
    String? dateTo,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      var path = '/api/saas/tickets?page=$page&limit=$limit';
      if (status != null && status.isNotEmpty && status != 'ALL') {
        path += '&status=${Uri.encodeQueryComponent(status)}';
      }
      if (dateFrom != null) path += '&date_from=${Uri.encodeQueryComponent(dateFrom)}';
      if (dateTo != null) path += '&date_to=${Uri.encodeQueryComponent(dateTo)}';

      final response = await _apiGet(path);
      if (response is Map<String, dynamic>) {
        return TicketListResult.fromJson(response);
      }
      throw SaasTicketException(message: 'Respuesta inválida al listar tickets.');
    } catch (e) {
      throw _handleError(e, 'Error al listar tickets de la sede.');
    }
  }

  SaasTicketException _handleError(dynamic error, String defaultMsg) {
    if (error is SaasTicketException) return error;

    final errStr = error.toString();

    if (errStr.contains('OVERPAYMENT_NOT_ALLOWED')) {
      return SaasTicketException(
        message: 'El monto ingresado supera el saldo pendiente del ticket.',
        statusCode: 422,
        errorCode: 'OVERPAYMENT_NOT_ALLOWED',
      );
    }

    if (errStr.contains('APPOINTMENT_ALREADY_TICKETED') || errStr.contains('409')) {
      return SaasTicketException(
        message: 'Esta cita ya tiene un ticket activo registrado.',
        statusCode: 409,
        errorCode: 'APPOINTMENT_ALREADY_TICKETED',
      );
    }

    if (errStr.contains('INVALID_APPOINTMENT_STATUS')) {
      return SaasTicketException(
        message: 'La cita debe encontrarse en estado EN ATENCIÓN (IN_SERVICE) o COMPLETADA.',
        statusCode: 422,
        errorCode: 'INVALID_APPOINTMENT_STATUS',
      );
    }

    if (errStr.contains('INVALID_SERVICE_ASSIGNMENT')) {
      return SaasTicketException(
        message: 'El profesional seleccionado no tiene asignado este servicio en el catálogo.',
        statusCode: 422,
        errorCode: 'INVALID_SERVICE_ASSIGNMENT',
      );
    }

    if (errStr.contains('EMPTY_TICKET')) {
      return SaasTicketException(
        message: 'Debes agregar al menos un servicio antes de confirmar el ticket.',
        statusCode: 422,
        errorCode: 'EMPTY_TICKET',
      );
    }

    if (errStr.contains('IMMUTABLE_TICKET_STATUS')) {
      return SaasTicketException(
        message: 'El ticket se encuentra cerrado o en un estado que no admite modificaciones.',
        statusCode: 422,
        errorCode: 'IMMUTABLE_TICKET_STATUS',
      );
    }

    if (errStr.contains('MISSING_VOID_REASON')) {
      return SaasTicketException(
        message: 'Debes proporcionar un motivo válido para anular el ticket.',
        statusCode: 400,
        errorCode: 'MISSING_VOID_REASON',
      );
    }

    if (errStr.contains('UNAUTHORIZED_ROLE') || errStr.contains('403') || errStr.contains('FORBIDDEN')) {
      return SaasTicketException(
        message: 'No tienes permisos suficientes para realizar esta acción.',
        statusCode: 403,
        errorCode: 'UNAUTHORIZED_ROLE',
      );
    }

    if (errStr.contains('TICKET_NOT_FOUND') || errStr.contains('404')) {
      return SaasTicketException(
        message: 'El ticket solicitado no existe o no pertenece a esta sede.',
        statusCode: 404,
        errorCode: 'TICKET_NOT_FOUND',
      );
    }

    return SaasTicketException(
      message: errStr.replaceFirst('Exception: ', '').trim().isEmpty
          ? defaultMsg
          : errStr.replaceFirst('Exception: ', '').trim(),
    );
  }
}
