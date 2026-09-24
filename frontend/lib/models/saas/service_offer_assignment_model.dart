// frontend/lib/models/saas/service_offer_assignment_model.dart
import 'package:flutter/foundation.dart';
import 'hub_salon_model.dart';

/// ServiceOfferModel
///
/// Representa una oferta de servicio base en el establecimiento activo (NODO-02).
/// Invariante: Solo contiene atributos estructurales canónicos.
@immutable
class ServiceOfferModel {
  final String id;
  final dynamic tenantId;
  final String establishmentId;
  final String name;
  final String? description;
  final int baseDuration; // Minutos (1 a 1440)
  final double basePrice;  // Precio base en moneda local (>= 0.00)
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceOfferModel({
    required this.id,
    this.tenantId,
    required this.establishmentId,
    required this.name,
    this.description,
    required this.baseDuration,
    required this.basePrice,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceOfferModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    final rawDuration = json['base_duration'];
    final int duration = rawDuration is int
        ? rawDuration
        : int.tryParse(rawDuration?.toString() ?? '') ?? 0;

    final rawPrice = json['base_price'];
    final double price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;

    return ServiceOfferModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id'],
      establishmentId: json['establishment_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      baseDuration: duration,
      basePrice: price,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      'establishment_id': establishmentId,
      'name': name,
      if (description != null) 'description': description,
      'base_duration': baseDuration,
      'base_price': basePrice,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ServiceOfferModel copyWith({
    String? id,
    dynamic tenantId,
    String? establishmentId,
    String? name,
    String? description,
    int? baseDuration,
    double? basePrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceOfferModel(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      establishmentId: establishmentId ?? this.establishmentId,
      name: name ?? this.name,
      description: description ?? this.description,
      baseDuration: baseDuration ?? this.baseDuration,
      basePrice: basePrice ?? this.basePrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceOfferModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// ServiceAssignmentModel
///
/// Representa la vinculación operativa entre una oferta de servicio y una membresía de colaborador.
@immutable
class ServiceAssignmentModel {
  final String id;
  final dynamic tenantId;
  final String establishmentId;
  final String serviceOfferId;
  final String membershipId;
  final DateTime? createdAt;

  const ServiceAssignmentModel({
    required this.id,
    this.tenantId,
    required this.establishmentId,
    required this.serviceOfferId,
    required this.membershipId,
    this.createdAt,
  });

  factory ServiceAssignmentModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return ServiceAssignmentModel(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id'],
      establishmentId: json['establishment_id']?.toString() ?? '',
      serviceOfferId: json['service_offer_id']?.toString() ?? '',
      membershipId: json['membership_id']?.toString() ?? '',
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (tenantId != null) 'tenant_id': tenantId,
      'establishment_id': establishmentId,
      'service_offer_id': serviceOfferId,
      'membership_id': membershipId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceAssignmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// ServiceOfferFormData
///
/// Payload validado para crear o editar una oferta de servicio.
class ServiceOfferFormData {
  final String name;
  final String? description;
  final int baseDuration;
  final double basePrice;

  ServiceOfferFormData({
    required this.name,
    this.description,
    required this.baseDuration,
    required this.basePrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      'base_duration': baseDuration,
      'base_price': basePrice,
    };
  }

  String? validate() {
    if (name.trim().isEmpty) {
      return 'El nombre de la oferta es obligatorio.';
    }
    if (name.trim().length > 255) {
      return 'El nombre no puede exceder los 255 caracteres.';
    }
    if (description != null && description!.length > 2000) {
      return 'La descripción no puede exceder los 2000 caracteres.';
    }
    if (baseDuration <= 0 || baseDuration > 1440) {
      return 'La duración debe estar entre 1 y 1440 minutos.';
    }
    if (basePrice < 0) {
      return 'El precio no puede ser negativo.';
    }
    return null;
  }
}

/// ServiceAssignmentFormData
///
/// Payload para crear una asignación entre oferta y colaborador.
class ServiceAssignmentFormData {
  final String serviceOfferId;
  final String membershipId;

  ServiceAssignmentFormData({
    required this.serviceOfferId,
    required this.membershipId,
  });

  Map<String, dynamic> toJson() {
    return {
      'service_offer_id': serviceOfferId.trim(),
      'membership_id': membershipId.trim(),
    };
  }

  String? validate() {
    if (serviceOfferId.trim().isEmpty) {
      return 'Debe seleccionar una oferta de servicio.';
    }
    if (membershipId.trim().isEmpty) {
      return 'Debe seleccionar un colaborador.';
    }
    return null;
  }
}

/// ServiceOfferWithAssignments
///
/// Estructura de presentación que agrupa una oferta con sus asignaciones y los datos de los miembros.
@immutable
class ServiceOfferWithAssignments {
  final ServiceOfferModel offer;
  final List<ServiceAssignmentModel> assignments;
  final List<HubStaffMember> assignedStaff;

  const ServiceOfferWithAssignments({
    required this.offer,
    required this.assignments,
    required this.assignedStaff,
  });

  int get assignmentCount => assignments.length;
}
