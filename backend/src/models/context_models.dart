import 'package:json_annotation/json_annotation.dart';

part 'context_models.g.dart';

@JsonSerializable()
class AvailableContext {
  final String id;
  final String tenantId;
  final String salonId;
  final String membership;
  final String role;

  AvailableContext({
    required this.id,
    required this.tenantId,
    required this.salonId,
    required this.membership,
    required this.role,
  });

  factory AvailableContext.fromJson(Map<String, dynamic> json) => _$AvailableContextFromJson(json);
  Map<String, dynamic> toJson() => _$AvailableContextToJson(this);
}

@JsonSerializable()
class ActiveContext {
  final String id;
  final String tenantId;
  final String salonId;
  final String membership;
  final String role;
  final String state;

  ActiveContext({
    required this.id,
    required this.tenantId,
    required this.salonId,
    required this.membership,
    required this.role,
    required this.state,
  });

  factory ActiveContext.fromJson(Map<String, dynamic> json) => _$ActiveContextFromJson(json);
  Map<String, dynamic> toJson() => _$ActiveContextToJson(this);
}