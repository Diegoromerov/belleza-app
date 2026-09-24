// frontend/lib/models/saas/hub_salon_model.dart
import 'package:flutter/foundation.dart';

/// HubEstablishment
///
/// Representa la unidad operativa y comercial activa del establecimiento.
@immutable
class HubEstablishment {
  final String id;
  final String name;
  final String slug;
  final String? phone;
  final String? address;
  final String? city;
  final bool isActive;
  final Map<String, dynamic>? operatingHours;

  const HubEstablishment({
    required this.id,
    required this.name,
    required this.slug,
    this.phone,
    this.address,
    this.city,
    required this.isActive,
    this.operatingHours,
  });

  factory HubEstablishment.fromJson(Map<String, dynamic> json) {
    return HubEstablishment(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      operatingHours: json['operating_hours'] is Map<String, dynamic>
          ? json['operating_hours'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (city != null) 'city': city,
      'is_active': isActive,
      if (operatingHours != null) 'operating_hours': operatingHours,
    };
  }
}

/// HubOrganization
///
/// Representa la entidad legal / tributaria a la que pertenece el establecimiento.
@immutable
class HubOrganization {
  final String id;
  final String legalName;

  const HubOrganization({
    required this.id,
    required this.legalName,
  });

  factory HubOrganization.fromJson(Map<String, dynamic> json) {
    return HubOrganization(
      id: json['id']?.toString() ?? '',
      legalName: json['legal_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'legal_name': legalName,
    };
  }
}

/// HubActiveUserContext
///
/// Representa el contexto y rol del usuario autenticado en la sede activa.
/// Rol Canónico: OWNER | MANAGER | PROFESSIONAL | RECEPTIONIST
@immutable
class HubActiveUserContext {
  final String membershipId;
  final String role;
  final String relationType;
  final String status;

  const HubActiveUserContext({
    required this.membershipId,
    required this.role,
    required this.relationType,
    required this.status,
  });

  factory HubActiveUserContext.fromJson(Map<String, dynamic> json) {
    return HubActiveUserContext(
      membershipId: json['membership_id']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      relationType: json['relation_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'membership_id': membershipId,
      'role': role,
      'relation_type': relationType,
      'status': status,
    };
  }
}

/// HubStaffSummary
///
/// Contiene la métrica agregada del personal activo en el establecimiento.
@immutable
class HubStaffSummary {
  final int activeMembersCount;

  const HubStaffSummary({
    required this.activeMembersCount,
  });

  factory HubStaffSummary.fromJson(Map<String, dynamic> json) {
    final rawCount = json['active_members_count'];
    final int count = rawCount is int
        ? rawCount
        : int.tryParse(rawCount?.toString() ?? '') ?? 0;
    return HubStaffSummary(activeMembersCount: count);
  }

  Map<String, dynamic> toJson() {
    return {
      'active_members_count': activeMembersCount,
    };
  }
}

/// HubSummaryData
///
/// Agrupa los datos del establecimiento, organización, contexto de usuario y métricas de staff.
@immutable
class HubSummaryData {
  final HubEstablishment establishment;
  final HubOrganization organization;
  final HubActiveUserContext activeUserContext;
  final HubStaffSummary staffSummary;

  const HubSummaryData({
    required this.establishment,
    required this.organization,
    required this.activeUserContext,
    required this.staffSummary,
  });

  factory HubSummaryData.fromJson(Map<String, dynamic> json) {
    return HubSummaryData(
      establishment: HubEstablishment.fromJson(
        json['establishment'] is Map<String, dynamic>
            ? json['establishment'] as Map<String, dynamic>
            : {},
      ),
      organization: HubOrganization.fromJson(
        json['organization'] is Map<String, dynamic>
            ? json['organization'] as Map<String, dynamic>
            : {},
      ),
      activeUserContext: HubActiveUserContext.fromJson(
        json['active_user_context'] is Map<String, dynamic>
            ? json['active_user_context'] as Map<String, dynamic>
            : {},
      ),
      staffSummary: HubStaffSummary.fromJson(
        json['staff_summary'] is Map<String, dynamic>
            ? json['staff_summary'] as Map<String, dynamic>
            : {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'establishment': establishment.toJson(),
      'organization': organization.toJson(),
      'active_user_context': activeUserContext.toJson(),
      'staff_summary': staffSummary.toJson(),
    };
  }
}

/// HubSummaryResponse
///
/// Respuesta completa del endpoint `GET /api/v1/saas/hub/summary`.
@immutable
class HubSummaryResponse {
  final bool ok;
  final HubSummaryData summary;

  const HubSummaryResponse({
    required this.ok,
    required this.summary,
  });

  factory HubSummaryResponse.fromJson(Map<String, dynamic> json) {
    return HubSummaryResponse(
      ok: json['ok'] is bool ? json['ok'] as bool : true,
      summary: HubSummaryData.fromJson(
        json['summary'] is Map<String, dynamic>
            ? json['summary'] as Map<String, dynamic>
            : {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'summary': summary.toJson(),
    };
  }
}

/// HubStaffMember
///
/// Representa a un integrante del personal adscrito al establecimiento activo.
@immutable
class HubStaffMember {
  final String membershipId;
  final dynamic userId;
  final String userName;
  final String userEmail;
  final String role;
  final String relationType;
  final String status;
  final DateTime? joinedAt;

  const HubStaffMember({
    required this.membershipId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.relationType,
    required this.status,
    this.joinedAt,
  });

  factory HubStaffMember.fromJson(Map<String, dynamic> json) {
    DateTime? parsedJoinedAt;
    final rawJoined = json['joined_at']?.toString();
    if (rawJoined != null && rawJoined.isNotEmpty) {
      parsedJoinedAt = DateTime.tryParse(rawJoined);
    }

    return HubStaffMember(
      membershipId: json['membership_id']?.toString() ?? '',
      userId: json['user_id'],
      userName: json['user_name']?.toString() ?? '',
      userEmail: json['user_email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      relationType: json['relation_type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      joinedAt: parsedJoinedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'membership_id': membershipId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'role': role,
      'relation_type': relationType,
      'status': status,
      if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
    };
  }
}

/// HubStaffResponse
///
/// Respuesta completa del endpoint `GET /api/v1/saas/hub/staff`.
@immutable
class HubStaffResponse {
  final bool ok;
  final String establishmentId;
  final int staffCount;
  final List<HubStaffMember> members;

  const HubStaffResponse({
    required this.ok,
    required this.establishmentId,
    required this.staffCount,
    required this.members,
  });

  factory HubStaffResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['members'] as List<dynamic>? ?? [];
    final int count = json['staff_count'] is int
        ? json['staff_count'] as int
        : int.tryParse(json['staff_count']?.toString() ?? '') ?? rawList.length;

    return HubStaffResponse(
      ok: json['ok'] is bool ? json['ok'] as bool : true,
      establishmentId: json['establishment_id']?.toString() ?? '',
      staffCount: count,
      members: rawList
          .whereType<Map<String, dynamic>>()
          .map((m) => HubStaffMember.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ok': ok,
      'establishment_id': establishmentId,
      'staff_count': staffCount,
      'members': members.map((m) => m.toJson()).toList(),
    };
  }
}

/// HubCockpitData
///
/// Estructura combinada para la carga del Hub Salón, permitiendo soporte de éxito parcial.
@immutable
class HubCockpitData {
  final HubSummaryResponse summary;
  final HubStaffResponse? staff;
  final String? staffError;

  const HubCockpitData({
    required this.summary,
    this.staff,
    this.staffError,
  });

  bool get isStaffLoaded => staff != null && staffError == null;
  bool get hasStaffError => staffError != null;
}
