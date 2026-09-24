// frontend/lib/models/saas/customer_model.dart
import 'package:flutter/foundation.dart';

/// SaasCustomerSummary
///
/// Representa el resumen de un cliente en listados y typeahead.
@immutable
class SaasCustomerSummary {
  final String id;
  final String? tenantId;
  final String? userId;
  final String firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? birthDate;
  final String status; // ACTIVE, INACTIVE, ARCHIVED
  final bool isAssociatedWithActiveEstablishment;
  final String? createdAt;
  final String? updatedAt;

  const SaasCustomerSummary({
    required this.id,
    this.tenantId,
    this.userId,
    required this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.birthDate,
    required this.status,
    this.isAssociatedWithActiveEstablishment = true,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName {
    if (lastName != null && lastName!.trim().isNotEmpty) {
      return '$firstName ${lastName!}'.trim();
    }
    return firstName;
  }

  bool get hasLinkedUser => userId != null && userId!.trim().isNotEmpty;

  factory SaasCustomerSummary.fromJson(Map<String, dynamic> json) {
    return SaasCustomerSummary(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString(),
      userId: json['user_id']?.toString(),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      birthDate: json['birth_date']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      isAssociatedWithActiveEstablishment:
          json['is_associated_with_active_establishment'] is bool
              ? json['is_associated_with_active_establishment'] as bool
              : true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (userId != null) 'user_id': userId,
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (birthDate != null) 'birth_date': birthDate,
      'status': status,
      'is_associated_with_active_establishment':
          isAssociatedWithActiveEstablishment,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

/// CustomerEstablishmentRelation
///
/// Representa los datos específicos de la relación de un cliente con una sede local.
@immutable
class CustomerEstablishmentRelation {
  final String? customerId;
  final String? establishmentId;
  final String? localNotes;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  const CustomerEstablishmentRelation({
    this.customerId,
    this.establishmentId,
    this.localNotes,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerEstablishmentRelation.fromJson(Map<String, dynamic> json) {
    return CustomerEstablishmentRelation(
      customerId: json['customer_id']?.toString(),
      establishmentId: json['establishment_id']?.toString(),
      localNotes: json['local_notes']?.toString(),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (customerId != null) 'customer_id': customerId,
      if (establishmentId != null) 'establishment_id': establishmentId,
      if (localNotes != null) 'local_notes': localNotes,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }
}

/// SaasCustomerDetail
///
/// Representa la ficha completa de un cliente junto a su relación con la sede activa.
@immutable
class SaasCustomerDetail {
  final String id;
  final String? tenantId;
  final String? userId;
  final String firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? birthDate;
  final String? notes; // Ámbito canónico (Tenant)
  final String status; // ACTIVE, INACTIVE, ARCHIVED
  final String? createdAt;
  final String? updatedAt;
  final CustomerEstablishmentRelation? localEstablishment; // Ámbito local (Sede)

  const SaasCustomerDetail({
    required this.id,
    this.tenantId,
    this.userId,
    required this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.birthDate,
    this.notes,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.localEstablishment,
  });

  String get fullName {
    if (lastName != null && lastName!.trim().isNotEmpty) {
      return '$firstName ${lastName!}'.trim();
    }
    return firstName;
  }

  bool get hasLinkedUser => userId != null && userId!.trim().isNotEmpty;
  bool get isLocallyActive => localEstablishment?.isActive ?? false;
  String? get localNotes => localEstablishment?.localNotes;

  factory SaasCustomerDetail.fromJson(Map<String, dynamic> json) {
    final customerData = json['customer'] is Map<String, dynamic>
        ? json['customer'] as Map<String, dynamic>
        : json;

    CustomerEstablishmentRelation? localEst;
    if (json['local_establishment'] is Map<String, dynamic>) {
      localEst = CustomerEstablishmentRelation.fromJson(
          json['local_establishment'] as Map<String, dynamic>);
    } else if (customerData['local_establishment'] is Map<String, dynamic>) {
      localEst = CustomerEstablishmentRelation.fromJson(
          customerData['local_establishment'] as Map<String, dynamic>);
    }

    return SaasCustomerDetail(
      id: customerData['id']?.toString() ?? '',
      tenantId: customerData['tenant_id']?.toString(),
      userId: customerData['user_id']?.toString(),
      firstName: customerData['first_name']?.toString() ?? '',
      lastName: customerData['last_name']?.toString(),
      phone: customerData['phone']?.toString(),
      email: customerData['email']?.toString(),
      birthDate: customerData['birth_date']?.toString(),
      notes: customerData['notes']?.toString(),
      status: customerData['status']?.toString() ?? 'ACTIVE',
      createdAt: customerData['created_at']?.toString(),
      updatedAt: customerData['updated_at']?.toString(),
      localEstablishment: localEst,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      if (userId != null) 'user_id': userId,
      'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (birthDate != null) 'birth_date': birthDate,
      if (notes != null) 'notes': notes,
      'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (localEstablishment != null)
        'local_establishment': localEstablishment!.toJson(),
    };
  }
}

/// CustomerDuplicateCandidate
///
/// Representa un cliente existente retornado en respuesta 409 POSSIBLE_DUPLICATE_FOUND.
@immutable
class CustomerDuplicateCandidate {
  final String id;
  final String firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String status;
  final bool isAssociatedWithActiveEstablishment;
  final String? createdAt;

  const CustomerDuplicateCandidate({
    required this.id,
    required this.firstName,
    this.lastName,
    this.phone,
    this.email,
    required this.status,
    this.isAssociatedWithActiveEstablishment = true,
    this.createdAt,
  });

  String get fullName {
    if (lastName != null && lastName!.trim().isNotEmpty) {
      return '$firstName ${lastName!}'.trim();
    }
    return firstName;
  }

  factory CustomerDuplicateCandidate.fromJson(Map<String, dynamic> json) {
    return CustomerDuplicateCandidate(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      isAssociatedWithActiveEstablishment:
          json['is_associated_with_active_establishment'] is bool
              ? json['is_associated_with_active_establishment'] as bool
              : true,
      createdAt: json['created_at']?.toString(),
    );
  }
}

/// CustomerPagination
@immutable
class CustomerPagination {
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const CustomerPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory CustomerPagination.fromJson(Map<String, dynamic> json) {
    return CustomerPagination(
      total: json['total'] is num ? (json['total'] as num).toInt() : 0,
      page: json['page'] is num ? (json['page'] as num).toInt() : 1,
      limit: json['limit'] is num ? (json['limit'] as num).toInt() : 20,
      totalPages:
          json['total_pages'] is num ? (json['total_pages'] as num).toInt() : 1,
    );
  }
}

/// CustomerListResult
@immutable
class CustomerListResult {
  final String scope;
  final CustomerPagination pagination;
  final List<SaasCustomerSummary> customers;

  const CustomerListResult({
    required this.scope,
    required this.pagination,
    required this.customers,
  });

  factory CustomerListResult.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] is List ? json['data'] as List : [];
    final customers = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => SaasCustomerSummary.fromJson(e))
        .toList();

    final pagination = json['pagination'] is Map<String, dynamic>
        ? CustomerPagination.fromJson(
            json['pagination'] as Map<String, dynamic>)
        : const CustomerPagination(total: 0, page: 1, limit: 20, totalPages: 1);

    return CustomerListResult(
      scope: json['scope']?.toString() ?? 'establishment',
      pagination: pagination,
      customers: customers,
    );
  }
}

/// CustomerHistoryAppointment
@immutable
class CustomerHistoryAppointment {
  final String id;
  final String appointmentDate;
  final String startTime;
  final String? endTime;
  final String status;
  final String? serviceTitle;
  final String? professionalName;

  const CustomerHistoryAppointment({
    required this.id,
    required this.appointmentDate,
    required this.startTime,
    this.endTime,
    required this.status,
    this.serviceTitle,
    this.professionalName,
  });

  factory CustomerHistoryAppointment.fromJson(Map<String, dynamic> json) {
    return CustomerHistoryAppointment(
      id: json['id']?.toString() ?? '',
      appointmentDate: json['appointment_date']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString(),
      status: json['status']?.toString() ?? '',
      serviceTitle: json['service_title']?.toString(),
      professionalName: json['professional_name']?.toString(),
    );
  }
}

/// CustomerHistoryResult
@immutable
class CustomerHistoryResult {
  final String attributionStatus; // ATTRIBUTED_VIA_USER_ACCOUNT o UNLINKED_NO_ATTRIBUTED_HISTORY
  final int count;
  final List<CustomerHistoryAppointment> appointments;

  const CustomerHistoryResult({
    required this.attributionStatus,
    required this.count,
    required this.appointments,
  });

  bool get isAttributed =>
      attributionStatus == 'ATTRIBUTED_VIA_USER_ACCOUNT';

  factory CustomerHistoryResult.fromJson(Map<String, dynamic> json) {
    final rawList =
        json['appointments'] is List ? json['appointments'] as List : [];
    final appointments = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => CustomerHistoryAppointment.fromJson(e))
        .toList();

    return CustomerHistoryResult(
      attributionStatus: json['attribution_status']?.toString() ??
          'UNLINKED_NO_ATTRIBUTED_HISTORY',
      count: json['count'] is num ? (json['count'] as num).toInt() : 0,
      appointments: appointments,
    );
  }
}
