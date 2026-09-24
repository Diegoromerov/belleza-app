// frontend/lib/models/saas_staff_model.dart
// GO-08.41: Staff Provisioning Frontend Models

/// Represents a staff member belonging to the active establishment.
class StaffMember {
  final String membershipId;
  final String tenantId;
  final String establishmentId;
  final int userId;
  final String userName;
  final String userEmail;
  final String role; // OWNER | MANAGER | PROFESSIONAL | RECEPTIONIST
  final String relationType; // STAFF_EMPLOYEE | INDEPENDENT_PROVIDER | OWNER_PARTNER
  final String status; // ACTIVE | SUSPENDED | REVOKED
  final DateTime? joinedAt;
  final DateTime? revokedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffMember({
    required this.membershipId,
    required this.tenantId,
    required this.establishmentId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.relationType,
    required this.status,
    this.joinedAt,
    this.revokedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      membershipId: (json['membership_id'] ?? json['id'] ?? '').toString(),
      tenantId: (json['tenant_id'] ?? '').toString(),
      establishmentId: (json['establishment_id'] ?? '').toString(),
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      userName: json['user_name'] ?? json['nombre'] ?? '',
      userEmail: json['user_email'] ?? json['email'] ?? '',
      role: json['role'] ?? 'PROFESSIONAL',
      relationType: json['relation_type'] ?? 'STAFF_EMPLOYEE',
      status: json['status'] ?? 'ACTIVE',
      joinedAt: json['joined_at'] != null ? DateTime.tryParse(json['joined_at'].toString()) : null,
      revokedAt: json['revoked_at'] != null ? DateTime.tryParse(json['revoked_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'membership_id': membershipId,
      'tenant_id': tenantId,
      'establishment_id': establishmentId,
      'user_id': userId,
      'user_name': userName,
      'user_email': userEmail,
      'role': role,
      'relation_type': relationType,
      'status': status,
      'joined_at': joinedAt?.toIso8601String(),
      'revoked_at': revokedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'ACTIVE';
  bool get isSuspended => status == 'SUSPENDED';
  bool get isRevoked => status == 'REVOKED';
  bool get isOwner => role == 'OWNER';
  bool get isManager => role == 'MANAGER';
}

/// Response wrapper for listing staff members in an establishment.
class StaffListResponse {
  final String establishmentId;
  final List<StaffMember> members;

  StaffListResponse({
    required this.establishmentId,
    required this.members,
  });

  factory StaffListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['members'] as List<dynamic>? ?? [];
    return StaffListResponse(
      establishmentId: (json['establishment_id'] ?? '').toString(),
      members: list.map((item) => StaffMember.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

/// Represents an asynchronous invitation issued for staff incorporation.
class StaffInvitation {
  final String id;
  final String tenantId;
  final String establishmentId;
  final String email;
  final String role; // OWNER | MANAGER | PROFESSIONAL | RECEPTIONIST
  final String relationType; // STAFF_EMPLOYEE | INDEPENDENT_PROVIDER | OWNER_PARTNER
  final String? invitedByMembershipId;
  final String? inviterName;
  final String status; // PENDING | ACCEPTED | REVOKED | EXPIRED
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffInvitation({
    required this.id,
    required this.tenantId,
    required this.establishmentId,
    required this.email,
    required this.role,
    required this.relationType,
    this.invitedByMembershipId,
    this.inviterName,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StaffInvitation.fromJson(Map<String, dynamic> json) {
    return StaffInvitation(
      id: (json['id'] ?? '').toString(),
      tenantId: (json['tenant_id'] ?? '').toString(),
      establishmentId: (json['establishment_id'] ?? '').toString(),
      email: json['email'] ?? '',
      role: json['role'] ?? 'PROFESSIONAL',
      relationType: json['relation_type'] ?? 'STAFF_EMPLOYEE',
      invitedByMembershipId: json['invited_by_membership_id']?.toString(),
      inviterName: json['inviter_name'],
      status: json['status'] ?? 'PENDING',
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) ?? DateTime.now() : DateTime.now(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }

  bool get isPending => status == 'PENDING';
  bool get isExpired => status == 'EXPIRED' || DateTime.now().isAfter(expiresAt);
  bool get isRevoked => status == 'REVOKED';
  bool get isAccepted => status == 'ACCEPTED';
}

/// Response wrapper for listing invitations in an establishment.
class StaffInvitationListResponse {
  final List<StaffInvitation> invitations;

  StaffInvitationListResponse({required this.invitations});

  factory StaffInvitationListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['invitations'] as List<dynamic>? ?? [];
    return StaffInvitationListResponse(
      invitations: list.map((item) => StaffInvitation.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

/// Response wrapper for an emitted or resent invitation.
class StaffInvitationEmissionResponse {
  final bool success;
  final StaffInvitation invitation;
  final String rawToken;
  final String? invitationUrl;

  StaffInvitationEmissionResponse({
    required this.success,
    required this.invitation,
    required this.rawToken,
    this.invitationUrl,
  });

  factory StaffInvitationEmissionResponse.fromJson(Map<String, dynamic> json) {
    final invData = json['invitation'] as Map<String, dynamic>? ?? {};
    return StaffInvitationEmissionResponse(
      success: json['success'] ?? true,
      invitation: StaffInvitation.fromJson(invData),
      rawToken: json['raw_token'] ?? '',
      invitationUrl: json['invitation_url'],
    );
  }
}

/// DTO for public inspection of an invitation token.
class StaffInvitationInspection {
  final bool valid;
  final String email;
  final String role;
  final String relationType;
  final String establishmentId;
  final String establishmentName;
  final String tenantName;
  final DateTime expiresAt;
  final bool userExists;

  StaffInvitationInspection({
    required this.valid,
    required this.email,
    required this.role,
    required this.relationType,
    required this.establishmentId,
    required this.establishmentName,
    required this.tenantName,
    required this.expiresAt,
    required this.userExists,
  });

  factory StaffInvitationInspection.fromJson(Map<String, dynamic> json) {
    return StaffInvitationInspection(
      valid: json['valid'] ?? true,
      email: json['email'] ?? '',
      role: json['role'] ?? 'PROFESSIONAL',
      relationType: json['relation_type'] ?? 'STAFF_EMPLOYEE',
      establishmentId: (json['establishment_id'] ?? '').toString(),
      establishmentName: json['establishment_name'] ?? 'Establecimiento',
      tenantName: json['tenant_name'] ?? 'Organización',
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at'].toString()) ?? DateTime.now() : DateTime.now(),
      userExists: json['user_exists'] ?? false,
    );
  }
}

/// DTO for invitation acceptance result.
class StaffInvitationAcceptanceResponse {
  final bool success;
  final String membershipId;
  final String establishmentId;
  final String role;

  StaffInvitationAcceptanceResponse({
    required this.success,
    required this.membershipId,
    required this.establishmentId,
    required this.role,
  });

  factory StaffInvitationAcceptanceResponse.fromJson(Map<String, dynamic> json) {
    return StaffInvitationAcceptanceResponse(
      success: json['success'] ?? true,
      membershipId: (json['membership_id'] ?? '').toString(),
      establishmentId: (json['establishment_id'] ?? '').toString(),
      role: json['role'] ?? '',
    );
  }
}

/// Domain exception for Staff Provisioning API errors.
class SaasStaffException implements Exception {
  final String code;
  final String message;
  final int statusCode;

  SaasStaffException({
    required this.code,
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => 'SaasStaffException: [$code] $message';

  /// Maps backend error codes to user-facing localized messages.
  static String localize(String code, {String? defaultMsg}) {
    switch (code) {
      case 'UNAUTHORIZED_ROLE':
      case 'UNAUTHORIZED_ROLE_MUTATION':
        return 'No tienes permisos suficientes para realizar esta acción sobre este colaborador.';
      case 'SELF_ROLE_MUTATION_PROHIBITED':
        return 'Por motivos de seguridad y gobernanza, no puedes modificar tu propio rol.';
      case 'SELF_STATUS_MUTATION_PROHIBITED':
        return 'No puedes suspender ni revocar tu propia membresía.';
      case 'CANNOT_ORPHAN_ESTABLISHMENT':
        return 'Acción bloqueada: El establecimiento debe mantener al menos un (1) Propietario (Owner) activo.';
      case 'INVALID_STATE_TRANSITION':
        return 'Transición de estado inválida. Las membresías revocadas no pueden ser reactivadas.';
      case 'INVITATION_ALREADY_PENDING':
        return 'Ya existe una invitación pendiente para este correo electrónico en esta sede.';
      case 'USER_ALREADY_MEMBER':
        return 'Este usuario ya es un miembro activo o registrado de este establecimiento.';
      case 'INVITATION_EXPIRED':
        return 'Esta invitación ha expirado (+7 días transcurridos). Solicita un reenvío al administrador.';
      case 'INVITATION_REVOKED':
        return 'Esta invitación fue cancelada o revocada por la administración del salón.';
      case 'INVITATION_ALREADY_PROCESSED':
        return 'Esta invitación ya fue aceptada previamente.';
      case 'INVITATION_NOT_FOUND':
        return 'El enlace de invitación no es válido o no existe.';
      case 'IDENTITY_MISMATCH':
        return 'La cuenta actualmente autenticada no coincide con el correo destinatario de la invitación.';
      case 'TENANT_MISMATCH':
        return 'La cuenta pertenece a una organización distinta a la sede emisora.';
      case 'REGISTRATION_REQUIRED':
        return 'Debes completar tu nombre completo y contraseña para registrarte.';
      case 'AUTHENTICATION_REQUIRED':
        return 'Ya existe una cuenta con este correo. Por favor, inicia sesión para aceptar la invitación.';
      case 'ACTIVE_CONTEXT_REQUIRED':
        return 'Se requiere tener una sede activa seleccionada.';
      default:
        return defaultMsg ?? 'Ocurrió un error al procesar la solicitud ($code).';
    }
  }
}
