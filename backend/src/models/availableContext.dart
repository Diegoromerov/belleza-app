class AvailableContext {
  final String tenantId;
  final String salonId;
  final Membership membership;
  final String role;

  AvailableContext({
    required this.tenantId,
    required this.salonId,
    required this.membership,
    required this.role,
  });

  factory AvailableContext.fromJson(Map<String, dynamic> json) {
    return AvailableContext(
      tenantId: json['tenantId'],
      salonId: json['salonId'],
      membership: Membership.fromJson(json['membership']),
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'salonId': salonId,
      'membership': membership.toJson(),
      'role': role,
    };
  }
}