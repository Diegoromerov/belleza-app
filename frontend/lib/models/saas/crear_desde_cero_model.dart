// frontend/lib/models/saas/crear_desde_cero_model.dart
import 'package:flutter/foundation.dart';

/// DTO para la definición de un servicio en tránsito durante el wizard.
@immutable
class ServiceDraft {
  final String name;
  final String category;
  final int durationMinutes;
  final double price;
  final String description;

  const ServiceDraft({
    required this.name,
    required this.category,
    required this.durationMinutes,
    required this.price,
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name.trim(),
        'category': category.trim(),
        'duration_minutes': durationMinutes,
        'price': price,
        'description': description.trim(),
      };

  factory ServiceDraft.fromJson(Map<String, dynamic> json) {
    return ServiceDraft(
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'GENERAL',
      durationMinutes: int.tryParse(json['duration_minutes']?.toString() ?? '') ?? 30,
      price: double.tryParse(json['price']?.toString() ?? '') ?? 0.0,
      description: json['description']?.toString() ?? '',
    );
  }

  ServiceDraft copyWith({
    String? name,
    String? category,
    int? durationMinutes,
    double? price,
    String? description,
  }) {
    return ServiceDraft(
      name: name ?? this.name,
      category: category ?? this.category,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      price: price ?? this.price,
      description: description ?? this.description,
    );
  }
}

/// DTO para asignar categorías temáticas a un miembro de personal preexistente.
@immutable
class StaffCategoryAssignmentDraft {
  final String membershipId;
  final List<String> assignedCategories;

  const StaffCategoryAssignmentDraft({
    required this.membershipId,
    required this.assignedCategories,
  });

  Map<String, dynamic> toJson() => {
        'membership_id': membershipId,
        'assigned_categories': assignedCategories,
      };

  factory StaffCategoryAssignmentDraft.fromJson(Map<String, dynamic> json) {
    final rawCats = json['assigned_categories'] as List<dynamic>?;
    return StaffCategoryAssignmentDraft(
      membershipId: json['membership_id']?.toString() ?? '',
      assignedCategories: rawCats?.map((c) => c.toString()).toList() ?? [],
    );
  }
}

/// Request DTO enviado a POST /api/v1/saas/hub/onboarding/bootstrap
@immutable
class CrearDesdeCeroBootstrapRequest {
  final List<String> activities;
  final List<ServiceDraft> services;
  final List<StaffCategoryAssignmentDraft> staffAssignments;
  final Map<String, dynamic>? decisions;

  const CrearDesdeCeroBootstrapRequest({
    required this.activities,
    required this.services,
    required this.staffAssignments,
    this.decisions,
  });

  Map<String, dynamic> toJson() => {
        'activities': activities,
        'services': services.map((s) => s.toJson()).toList(),
        'staff_assignments': staffAssignments.map((a) => a.toJson()).toList(),
        if (decisions != null) 'decisions': decisions,
      };
}

/// DTO del Context Package compilado por el backend para Pre-Nodo 01.
@immutable
class ContextPackageData {
  final String organizationId;
  final String organizationLegalName;
  final String establishmentId;
  final String establishmentName;
  final String establishmentSlug;
  final String establishmentCity;
  final String establishmentAddress;
  final String establishmentPhone;
  final List<String> activities;
  final List<ServiceDraft> relevantServices;
  final String derivedState;
  final List<String> blocks;
  final Map<String, dynamic> rawPackage;

  const ContextPackageData({
    required this.organizationId,
    required this.organizationLegalName,
    required this.establishmentId,
    required this.establishmentName,
    required this.establishmentSlug,
    required this.establishmentCity,
    required this.establishmentAddress,
    required this.establishmentPhone,
    required this.activities,
    required this.relevantServices,
    required this.derivedState,
    required this.blocks,
    required this.rawPackage,
  });

  factory ContextPackageData.fromJson(Map<String, dynamic> json) {
    final org = json['organization'] as Map<String, dynamic>? ?? {};
    final est = json['establishments'] as Map<String, dynamic>? ?? {};
    final rawActs = (json['activities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final rawBlocks = (json['blocks'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
    final rawServs = json['relevant_services'] as List<dynamic>? ?? [];

    final servicesList = rawServs
        .whereType<Map<String, dynamic>>()
        .map((s) => ServiceDraft.fromJson(s))
        .toList();

    return ContextPackageData(
      organizationId: org['id']?.toString() ?? '',
      organizationLegalName: org['legal_name']?.toString() ?? '',
      establishmentId: est['id']?.toString() ?? '',
      establishmentName: est['name']?.toString() ?? '',
      establishmentSlug: est['slug']?.toString() ?? '',
      establishmentCity: est['city']?.toString() ?? '',
      establishmentAddress: est['address']?.toString() ?? '',
      establishmentPhone: est['phone']?.toString() ?? '',
      activities: rawActs,
      relevantServices: servicesList,
      derivedState: json['state']?.toString() ?? 'INITIAL',
      blocks: rawBlocks,
      rawPackage: json,
    );
  }
}

/// Response DTO retornado por POST /api/v1/saas/hub/onboarding/bootstrap
@immutable
class ContextPackageResponse {
  final String status;
  final ContextPackageData? contextPackage;
  final String? error;
  final String? message;

  const ContextPackageResponse({
    required this.status,
    this.contextPackage,
    this.error,
    this.message,
  });

  bool get isSuccess => status == 'success' && contextPackage != null;
  bool get isReadyForPreNodo01 => contextPackage?.derivedState == 'READY_FOR_PRE_NODE_01';

  factory ContextPackageResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString() ?? 'error';
    final data = json['data'] as Map<String, dynamic>?;
    ContextPackageData? pkg;

    if (data != null && data['context_package'] != null) {
      pkg = ContextPackageData.fromJson(data['context_package'] as Map<String, dynamic>);
    }

    return ContextPackageResponse(
      status: status,
      contextPackage: pkg,
      error: json['error']?.toString(),
      message: json['message']?.toString(),
    );
  }
}
