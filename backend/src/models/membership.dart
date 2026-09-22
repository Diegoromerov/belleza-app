class Membership {
  final String level;

  Membership({required this.level});

  factory Membership.fromJson(Map<String, dynamic> json) {
    return Membership(level: json['level']);
  }

  Map<String, dynamic> toJson() {
    return {'level': level};
  }
}