// frontend/lib/models/saas/available_context_model.dart
import 'package:flutter/foundation.dart';

/// AvailableContextItem
///
/// Representa una membresía activa y los datos de su sede física asociada.
/// Mapea 1:1 los campos devueltos por el backend en `GET /api/v1/saas/context/available`.
@immutable
class AvailableContextItem {
  final String membershipId;
  final String organizationLegalName;
  final String establishmentName;
  final String establishmentSlug;
  final bool establishmentIsActive;
  final String role;
  final String relationType;
  final String tenantName;

  const AvailableContextItem({
    required this.membershipId,
    required this.organizationLegalName,
    required this.establishmentName,
    required this.establishmentSlug,
    required this.establishmentIsActive,
    required this.role,
    required this.relationType,
    required this.tenantName,
  });

  factory AvailableContextItem.fromJson(Map<String, dynamic> json) {
    return AvailableContextItem(
      membershipId: json['membership_id']?.toString() ?? '',
      organizationLegalName: json['organization_legal_name']?.toString() ?? '',
      establishmentName: json['establishment_name']?.toString() ?? '',
      establishmentSlug: json['establishment_slug']?.toString() ?? '',
      establishmentIsActive: json['establishment_is_active'] is bool
          ? json['establishment_is_active'] as bool
          : true,
      role: json['role']?.toString() ?? '',
      relationType: json['relation_type']?.toString() ?? '',
      tenantName: json['tenant_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'membership_id': membershipId,
      'organization_legal_name': organizationLegalName,
      'establishment_name': establishmentName,
      'establishment_slug': establishmentSlug,
      'establishment_is_active': establishmentIsActive,
      'role': role,
      'relation_type': relationType,
      'tenant_name': tenantName,
    };
  }
}

/// AvailableContextResponse
///
/// Respuesta completa del endpoint de resolución de contextos disponibles.
@immutable
class AvailableContextResponse {
  final String resolutionStatus; // 'NO_CONTEXT' | 'ONE_CONTEXT' | 'MULTIPLE_CONTEXTS'
  final int availableContextsCount;
  final List<AvailableContextItem> availableContexts;

  const AvailableContextResponse({
    required this.resolutionStatus,
    required this.availableContextsCount,
    required this.availableContexts,
  });

  bool get isNoContext =>
      resolutionStatus == 'NO_CONTEXT' || availableContextsCount == 0;
  bool get isOneContext =>
      resolutionStatus == 'ONE_CONTEXT' && availableContextsCount == 1;
  bool get isMultipleContexts =>
      resolutionStatus == 'MULTIPLE_CONTEXTS' && availableContextsCount >= 2;

  factory AvailableContextResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final rawList = data['available_contexts'] as List<dynamic>? ?? [];

    return AvailableContextResponse(
      resolutionStatus: data['resolution_status']?.toString() ?? 'NO_CONTEXT',
      availableContextsCount: (data['available_contexts_count'] as num?)?.toInt() ??
          rawList.length,
      availableContexts: rawList
          .whereType<Map<String, dynamic>>()
          .map((item) => AvailableContextItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resolution_status': resolutionStatus,
      'available_contexts_count': availableContextsCount,
      'available_contexts':
          availableContexts.map((e) => e.toJson()).toList(),
    };
  }
}
