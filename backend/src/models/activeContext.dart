class ActiveContext {
  final String tenantId;
  final String salonId;
  final Membership membership;
  final String role;
  final String state;

  ActiveContext({
    required this.tenantId,
    required this.salonId,
    required this.membership,
    required this.role,
    required this.state,
  });

  factory ActiveContext.fromJson(Map<String, dynamic> json) {
    return ActiveContext(
      tenantId: json['tenantId'],
      salonId: json['salonId'],
      membership: Membership.fromJson(json['membership']),
      role: json['role'],
      state: json['state'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'salonId': salonId,
      'membership': membership.toJson(),
      'role': role,
      'state': state,
    };
  }
}