// frontend/lib/models/saas/staff_schedule_model.dart
// NODO-03A UI / SCR-09: Staff Operational Availability & Schedule Runtime Models

import 'package:flutter/foundation.dart';

const List<String> kCanonicalWeekdays = [
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

const Map<String, String> kWeekdayLabels = {
  'monday': 'Lunes',
  'tuesday': 'Martes',
  'wednesday': 'Miércoles',
  'thursday': 'Jueves',
  'friday': 'Viernes',
  'saturday': 'Sábado',
  'sunday': 'Domingo',
};

final RegExp _timeFormatRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

int timeToMinutes(String timeStr) {
  final parts = timeStr.split(':');
  if (parts.length != 2) return 0;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return h * 60 + m;
}

bool isValidTimeFormat(String timeStr) {
  return _timeFormatRegex.hasMatch(timeStr.trim());
}

@immutable
class TimeBlockModel {
  final String startTime; // 'HH:mm'
  final String endTime;   // 'HH:mm'

  const TimeBlockModel({
    required this.startTime,
    required this.endTime,
  });

  factory TimeBlockModel.fromJson(Map<String, dynamic> json) {
    final rawStart = json['start_time'] as String? ?? '';
    final rawEnd = json['end_time'] as String? ?? '';
    return TimeBlockModel(
      startTime: rawStart.length >= 5 ? rawStart.substring(0, 5) : rawStart,
      endTime: rawEnd.length >= 5 ? rawEnd.substring(0, 5) : rawEnd,
    );
  }

  Map<String, dynamic> toJson() => {
    'start_time': startTime,
    'end_time': endTime,
  };

  TimeBlockModel copyWith({
    String? startTime,
    String? endTime,
  }) {
    return TimeBlockModel(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeBlockModel &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;
}

@immutable
class DayScheduleModel {
  final bool isWorking;
  final List<TimeBlockModel> timeBlocks;

  const DayScheduleModel({
    required this.isWorking,
    required this.timeBlocks,
  });

  factory DayScheduleModel.fromJson(Map<String, dynamic> json) {
    final isWorking = json['is_working'] as bool? ?? false;
    final rawBlocks = json['time_blocks'] as List<dynamic>? ?? [];
    final blocks = rawBlocks
        .whereType<Map<String, dynamic>>()
        .map((b) => TimeBlockModel.fromJson(b))
        .toList();
    return DayScheduleModel(
      isWorking: isWorking,
      timeBlocks: List.unmodifiable(blocks),
    );
  }

  Map<String, dynamic> toJson() => {
    'is_working': isWorking,
    'time_blocks': timeBlocks.map((b) => b.toJson()).toList(),
  };

  static const DayScheduleModel empty = DayScheduleModel(
    isWorking: false,
    timeBlocks: [],
  );

  DayScheduleModel copyWith({
    bool? isWorking,
    List<TimeBlockModel>? timeBlocks,
  }) {
    return DayScheduleModel(
      isWorking: isWorking ?? this.isWorking,
      timeBlocks: timeBlocks != null ? List.unmodifiable(timeBlocks) : this.timeBlocks,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DayScheduleModel &&
          runtimeType == other.runtimeType &&
          isWorking == other.isWorking &&
          listEquals(timeBlocks, other.timeBlocks);

  @override
  int get hashCode => isWorking.hashCode ^ timeBlocks.hashCode;
}

@immutable
class WeeklyScheduleModel {
  final DayScheduleModel monday;
  final DayScheduleModel tuesday;
  final DayScheduleModel wednesday;
  final DayScheduleModel thursday;
  final DayScheduleModel friday;
  final DayScheduleModel saturday;
  final DayScheduleModel sunday;

  const WeeklyScheduleModel({
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory WeeklyScheduleModel.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleModel(
      monday: json['monday'] is Map<String, dynamic>
          ? DayScheduleModel.fromJson(json['monday'] as Map<String, dynamic>)
          : DayScheduleModel.empty,
      tuesday: json['tuesday'] is Map<String, dynamic>
          ? DayScheduleModel.fromJson(json['tuesday'] as Map<String, dynamic>)
          : DayScheduleModel.empty,
      wednesday: json['wednesday'] is Map<String, dynamic>
          ? DayScheduleModel.fromJson(json['wednesday'] as Map<String, dynamic>)
          : DayScheduleModel.empty,
      thursday: json['thursday'] is Map<String, dynamic>
          ? DayScheduleModel.fromJson(json['thursday'] as Map<String, dynamic>)
          : DayScheduleModel.empty,
      friday: json['friday'] is Map<String, dynamic>
          ? DayScheduleModel.fromJson(json['friday'] as Map<String, dynamic>)
          : DayScheduleModel.empty,
      saturday: json['saturday'] is Map<String, dynamic>
          ? DayScheduleModel.fromJson(json['saturday'] as Map<String, dynamic>)
          : DayScheduleModel.empty,
      sunday: json['sunday'] is Map<String, dynamic>
          ? DayScheduleModel.fromJson(json['sunday'] as Map<String, dynamic>)
          : DayScheduleModel.empty,
    );
  }

  Map<String, dynamic> toJson() => {
    'monday': monday.toJson(),
    'tuesday': tuesday.toJson(),
    'wednesday': wednesday.toJson(),
    'thursday': thursday.toJson(),
    'friday': friday.toJson(),
    'saturday': saturday.toJson(),
    'sunday': sunday.toJson(),
  };

  static const WeeklyScheduleModel empty = WeeklyScheduleModel(
    monday: DayScheduleModel.empty,
    tuesday: DayScheduleModel.empty,
    wednesday: DayScheduleModel.empty,
    thursday: DayScheduleModel.empty,
    friday: DayScheduleModel.empty,
    saturday: DayScheduleModel.empty,
    sunday: DayScheduleModel.empty,
  );

  DayScheduleModel getDay(String dayKey) {
    switch (dayKey.toLowerCase()) {
      case 'monday':
        return monday;
      case 'tuesday':
        return tuesday;
      case 'wednesday':
        return wednesday;
      case 'thursday':
        return thursday;
      case 'friday':
        return friday;
      case 'saturday':
        return saturday;
      case 'sunday':
        return sunday;
      default:
        return DayScheduleModel.empty;
    }
  }

  WeeklyScheduleModel copyWithDay(String dayKey, DayScheduleModel updatedDay) {
    switch (dayKey.toLowerCase()) {
      case 'monday':
        return copyWith(monday: updatedDay);
      case 'tuesday':
        return copyWith(tuesday: updatedDay);
      case 'wednesday':
        return copyWith(wednesday: updatedDay);
      case 'thursday':
        return copyWith(thursday: updatedDay);
      case 'friday':
        return copyWith(friday: updatedDay);
      case 'saturday':
        return copyWith(saturday: updatedDay);
      case 'sunday':
        return copyWith(sunday: updatedDay);
      default:
        return this;
    }
  }

  WeeklyScheduleModel copyWith({
    DayScheduleModel? monday,
    DayScheduleModel? tuesday,
    DayScheduleModel? wednesday,
    DayScheduleModel? thursday,
    DayScheduleModel? friday,
    DayScheduleModel? saturday,
    DayScheduleModel? sunday,
  }) {
    return WeeklyScheduleModel(
      monday: monday ?? this.monday,
      tuesday: tuesday ?? this.tuesday,
      wednesday: wednesday ?? this.wednesday,
      thursday: thursday ?? this.thursday,
      friday: friday ?? this.friday,
      saturday: saturday ?? this.saturday,
      sunday: sunday ?? this.sunday,
    );
  }
}

@immutable
class StaffScheduleItemModel {
  final String membershipId;
  final String? userId;
  final String userName;
  final String? userEmail;
  final String role;
  final String? status;
  final String scheduleState; // 'CONFIGURED' | 'NOT_CONFIGURED' | 'EMPTY'
  final WeeklyScheduleModel weeklySchedule;

  const StaffScheduleItemModel({
    required this.membershipId,
    this.userId,
    required this.userName,
    this.userEmail,
    required this.role,
    this.status,
    required this.scheduleState,
    required this.weeklySchedule,
  });

  bool get isConfigured => scheduleState == 'CONFIGURED';

  factory StaffScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return StaffScheduleItemModel(
      membershipId: json['membership_id'] as String? ?? '',
      userId: json['user_id'] as String?,
      userName: json['user_name'] as String? ?? 'Colaborador',
      userEmail: json['user_email'] as String?,
      role: json['role'] as String? ?? 'PROFESSIONAL',
      status: json['status'] as String? ?? 'ACTIVE',
      scheduleState: json['schedule_state'] as String? ?? 'NOT_CONFIGURED',
      weeklySchedule: json['weekly_schedule'] is Map<String, dynamic>
          ? WeeklyScheduleModel.fromJson(json['weekly_schedule'] as Map<String, dynamic>)
          : WeeklyScheduleModel.empty,
    );
  }
}

@immutable
class StaffScheduleDetailModel {
  final String membershipId;
  final String establishmentId;
  final String tenantId;
  final String scheduleState;
  final bool outOfOperatingHoursWarning;
  final WeeklyScheduleModel weeklySchedule;

  const StaffScheduleDetailModel({
    required this.membershipId,
    required this.establishmentId,
    required this.tenantId,
    required this.scheduleState,
    required this.outOfOperatingHoursWarning,
    required this.weeklySchedule,
  });

  bool get isConfigured => scheduleState == 'CONFIGURED';

  factory StaffScheduleDetailModel.fromJson(Map<String, dynamic> json) {
    return StaffScheduleDetailModel(
      membershipId: json['membership_id'] as String? ?? '',
      establishmentId: json['establishment_id'] as String? ?? '',
      tenantId: json['tenant_id'] as String? ?? '',
      scheduleState: json['schedule_state'] as String? ?? 'NOT_CONFIGURED',
      outOfOperatingHoursWarning: json['out_of_operating_hours_warning'] as bool? ?? false,
      weeklySchedule: json['weekly_schedule'] is Map<String, dynamic>
          ? WeeklyScheduleModel.fromJson(json['weekly_schedule'] as Map<String, dynamic>)
          : WeeklyScheduleModel.empty,
    );
  }
}
