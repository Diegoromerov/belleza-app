/// GLOWAPP BUSINESS ENGINE MODELS
/// Dart models for Business Profile, Task, Requirement, Evidence, Finding, Document Template.

class BusinessProfileModel {
  final String id;
  final String providerId;
  final String verticalId;
  final String name;
  final String onboardingMode; // NEW_BUSINESS, EXISTING_BUSINESS
  final String lifecycleStage; // IDEA, CONSTITUTION, FORMALIZATION, OPENING, OPERATION, AUDIT, GROWTH
  final double complianceScore;
  final String city;
  final String country;

  BusinessProfileModel({
    required this.id,
    required this.providerId,
    required this.verticalId,
    required this.name,
    required this.onboardingMode,
    required this.lifecycleStage,
    required this.complianceScore,
    required this.city,
    required this.country,
  });

  factory BusinessProfileModel.fromJson(Map<String, dynamic> json) {
    return BusinessProfileModel(
      id: json['id'] ?? '',
      providerId: json['provider_id'] ?? '',
      verticalId: json['vertical_id'] ?? '',
      name: json['name'] ?? 'Mi Negocio de Belleza',
      onboardingMode: json['onboarding_mode'] ?? 'NEW_BUSINESS',
      lifecycleStage: json['lifecycle_stage'] ?? 'IDEA',
      complianceScore: (json['compliance_score'] ?? 0.0).toDouble(),
      city: json['city'] ?? 'Bogotá',
      country: json['country'] ?? 'Colombia',
    );
  }
}

class BusinessTaskModel {
  final String id;
  final String businessProfileId;
  final String requirementId;
  final String title;
  final String description;
  final String stage; // ENTENDER, EXPLICAR, RECOMENDAR, EJECUTAR, VERIFICAR
  final String status; // PENDING, IN_PROGRESS, SUBMITTED, VERIFIED, EXPIRED
  final String dueDate;

  BusinessTaskModel({
    required this.id,
    required this.businessProfileId,
    required this.requirementId,
    required this.title,
    required this.description,
    required this.stage,
    required this.status,
    required this.dueDate,
  });

  factory BusinessTaskModel.fromJson(Map<String, dynamic> json) {
    return BusinessTaskModel(
      id: json['id'] ?? '',
      businessProfileId: json['business_profile_id'] ?? '',
      requirementId: json['requirement_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      stage: json['stage'] ?? 'ENTENDER',
      status: json['status'] ?? 'PENDING',
      dueDate: json['due_date'] ?? '',
    );
  }
}

class BusinessFindingModel {
  final String id;
  final String businessProfileId;
  final String title;
  final String description;
  final String riskLevel; // LOW, MEDIUM, HIGH, CRITICAL
  final String status; // OPEN, MITIGATED, CLOSED
  final String mitigationPlan;

  BusinessFindingModel({
    required this.id,
    required this.businessProfileId,
    required this.title,
    required this.description,
    required this.riskLevel,
    required this.status,
    required this.mitigationPlan,
  });

  factory BusinessFindingModel.fromJson(Map<String, dynamic> json) {
    return BusinessFindingModel(
      id: json['id'] ?? '',
      businessProfileId: json['business_profile_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      riskLevel: json['risk_level'] ?? 'MEDIUM',
      status: json['status'] ?? 'OPEN',
      mitigationPlan: json['mitigation_plan'] ?? '',
    );
  }
}
