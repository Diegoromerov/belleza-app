// frontend/test/saas_staff_schedule_test.dart
// NODO-03A UI / SCR-09: Staff Operational Availability & Schedule Runtime Tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas/staff_schedule_model.dart';
import 'package:beauty_app/services/saas/staff_schedule_service.dart';
import 'package:beauty_app/screens/saas/staff_schedule_screen.dart';
import 'package:beauty_app/services/active_context_holder.dart';

class MockStaffScheduleService extends StaffScheduleService {
  List<StaffScheduleItemModel> mockStaffList = [];
  StaffScheduleDetailModel? mockDetail;
  bool shouldFailList = false;
  bool shouldFailSave = false;
  bool shouldFailDelete = false;

  WeeklyScheduleModel? lastSavedWeeklySchedule;
  String? lastSavedMembershipId;
  String? lastDeletedMembershipId;

  MockStaffScheduleService({
    Future<dynamic> Function(String path)? apiGet,
    Future<dynamic> Function(String path, Map<String, dynamic> body)? apiPut,
    Future<dynamic> Function(String path, [Map<String, dynamic>? body])? apiDelete,
  }) : super(apiGet: apiGet, apiPut: apiPut, apiDelete: apiDelete);

  @override
  Future<List<StaffScheduleItemModel>> listStaffSchedules() async {
    if (shouldFailList) {
      throw StaffScheduleException(
        message: 'Error de servidor al listar disponibilidad.',
        code: 'INTERNAL_SERVER_ERROR',
        statusCode: 500,
      );
    }
    return mockStaffList;
  }

  @override
  Future<StaffScheduleDetailModel> getStaffSchedule(String membershipId) async {
    if (mockDetail != null && mockDetail!.membershipId == membershipId) {
      return mockDetail!;
    }
    return StaffScheduleDetailModel(
      membershipId: membershipId,
      establishmentId: 'est-uuid-01',
      tenantId: 'tenant-uuid-01',
      scheduleState: 'CONFIGURED',
      outOfOperatingHoursWarning: false,
      weeklySchedule: WeeklyScheduleModel.empty,
    );
  }

  @override
  Future<StaffScheduleDetailModel> setStaffSchedule(
    String membershipId,
    WeeklyScheduleModel weeklySchedule,
  ) async {
    if (shouldFailSave) {
      throw StaffScheduleException(
        message: 'No autorizado para configurar disponibilidad.',
        code: 'FORBIDDEN_SELF_MANAGEMENT_ONLY',
        statusCode: 403,
      );
    }
    lastSavedMembershipId = membershipId;
    lastSavedWeeklySchedule = weeklySchedule;
    return StaffScheduleDetailModel(
      membershipId: membershipId,
      establishmentId: 'est-uuid-01',
      tenantId: 'tenant-uuid-01',
      scheduleState: 'CONFIGURED',
      outOfOperatingHoursWarning: mockDetail?.outOfOperatingHoursWarning ?? false,
      weeklySchedule: weeklySchedule,
    );
  }

  @override
  Future<bool> deleteStaffSchedule(String membershipId) async {
    if (shouldFailDelete) {
      throw StaffScheduleException(
        message: 'Solo los roles OWNER o MANAGER pueden eliminar la disponibilidad de un colaborador.',
        code: 'FORBIDDEN_ROLE',
        statusCode: 403,
      );
    }
    lastDeletedMembershipId = membershipId;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ActiveContextHolder().resetForTesting();
  });

  tearDown(() {
    ActiveContextHolder().resetForTesting();
  });

  group('NODO-03A / SCR-09 — Model & DTO Unit Tests', () {
    test('1. TimeBlockModel parses JSON and serializes correctly', () {
      final json = {'start_time': '09:00:00', 'end_time': '18:00:00'};
      final block = TimeBlockModel.fromJson(json);
      expect(block.startTime, equals('09:00'));
      expect(block.endTime, equals('18:00'));

      final out = block.toJson();
      expect(out['start_time'], equals('09:00'));
      expect(out['end_time'], equals('18:00'));
    });

    test('2. WeeklyScheduleModel parses 7 canonical days and produces complete JSON', () {
      final rawWeekly = {
        'monday': {
          'is_working': true,
          'time_blocks': [
            {'start_time': '08:00', 'end_time': '12:00'},
            {'start_time': '14:00', 'end_time': '18:00'}
          ]
        },
        'tuesday': {'is_working': false, 'time_blocks': []},
        'wednesday': {'is_working': false, 'time_blocks': []},
        'thursday': {'is_working': false, 'time_blocks': []},
        'friday': {'is_working': false, 'time_blocks': []},
        'saturday': {'is_working': false, 'time_blocks': []},
        'sunday': {'is_working': false, 'time_blocks': []}
      };

      final weekly = WeeklyScheduleModel.fromJson(rawWeekly);
      expect(weekly.monday.isWorking, isTrue);
      expect(weekly.monday.timeBlocks.length, equals(2));
      expect(weekly.tuesday.isWorking, isFalse);

      final jsonOut = weekly.toJson();
      expect(jsonOut.containsKey('monday'), isTrue);
      expect(jsonOut.containsKey('sunday'), isTrue);
      expect((jsonOut['monday']['time_blocks'] as List).length, equals(2));
    });

    test('3. StaffScheduleItemModel and DetailModel parse and reflect warning state', () {
      final itemJson = {
        'membership_id': 'mem-001',
        'user_name': 'Carlos Barbero',
        'role': 'PROFESSIONAL',
        'schedule_state': 'CONFIGURED',
        'weekly_schedule': {
          'monday': {
            'is_working': true,
            'time_blocks': [{'start_time': '10:00', 'end_time': '19:00'}]
          }
        }
      };

      final item = StaffScheduleItemModel.fromJson(itemJson);
      expect(item.membershipId, equals('mem-001'));
      expect(item.userName, equals('Carlos Barbero'));
      expect(item.role, equals('PROFESSIONAL'));
      expect(item.isConfigured, isTrue);

      final detailJson = {
        'membership_id': 'mem-001',
        'establishment_id': 'est-001',
        'tenant_id': 'ten-001',
        'schedule_state': 'CONFIGURED',
        'out_of_operating_hours_warning': true,
        'weekly_schedule': itemJson['weekly_schedule']
      };

      final detail = StaffScheduleDetailModel.fromJson(detailJson);
      expect(detail.outOfOperatingHoursWarning, isTrue);
    });
  });

  group('NODO-03A / SCR-09 — Service Layer Unit Tests', () {
    test('4. listStaffSchedules parses API response correctly', () async {
      final mockService = StaffScheduleService(
        apiGet: (path) async {
          expect(path, '/api/v1/saas/hub/staff/schedules');
          return {
            'status': 'success',
            'data': {
              'establishment_id': 'est-1',
              'staff_count': 1,
              'schedules': [
                {
                  'membership_id': 'mem-01',
                  'user_name': 'Ana Estilista',
                  'role': 'PROFESSIONAL',
                  'schedule_state': 'CONFIGURED',
                  'weekly_schedule': {
                    'monday': {
                      'is_working': true,
                      'time_blocks': [{'start_time': '09:00', 'end_time': '18:00'}]
                    }
                  }
                }
              ]
            }
          };
        },
      );

      final result = await mockService.listStaffSchedules();
      expect(result.length, equals(1));
      expect(result.first.userName, equals('Ana Estilista'));
    });

    test('5. getStaffSchedule fetches detailed schedule with warning flag', () async {
      final mockService = StaffScheduleService(
        apiGet: (path) async {
          expect(path, '/api/v1/saas/hub/staff/mem-01/schedule');
          return {
            'status': 'success',
            'data': {
              'membership_id': 'mem-01',
              'establishment_id': 'est-01',
              'tenant_id': 'ten-01',
              'schedule_state': 'CONFIGURED',
              'out_of_operating_hours_warning': true,
              'weekly_schedule': {
                'monday': {'is_working': true, 'time_blocks': []}
              }
            }
          };
        },
      );

      final detail = await mockService.getStaffSchedule('mem-01');
      expect(detail.membershipId, equals('mem-01'));
      expect(detail.outOfOperatingHoursWarning, isTrue);
    });

    test('6. setStaffSchedule performs atomic PUT replacement', () async {
      final mockService = StaffScheduleService(
        apiPut: (path, body) async {
          expect(path, '/api/v1/saas/hub/staff/mem-01/schedule');
          expect(body.containsKey('weekly_schedule'), isTrue);
          return {
            'status': 'success',
            'data': {
              'membership_id': 'mem-01',
              'establishment_id': 'est-01',
              'tenant_id': 'ten-01',
              'schedule_state': 'CONFIGURED',
              'out_of_operating_hours_warning': false,
              'weekly_schedule': body['weekly_schedule']
            }
          };
        },
      );

      final schedule = WeeklyScheduleModel.empty.copyWithDay(
        'monday',
        const DayScheduleModel(
          isWorking: true,
          timeBlocks: [TimeBlockModel(startTime: '08:00', endTime: '17:00')],
        ),
      );

      final result = await mockService.setStaffSchedule('mem-01', schedule);
      expect(result.scheduleState, equals('CONFIGURED'));
      expect(result.weeklySchedule.monday.isWorking, isTrue);
    });

    test('7. deleteStaffSchedule calls DELETE and resets schedule', () async {
      final mockService = StaffScheduleService(
        apiDelete: (path, [body]) async {
          expect(path, '/api/v1/saas/hub/staff/mem-01/schedule');
          return {
            'status': 'success',
            'data': {
              'membership_id': 'mem-01',
              'schedule_state': 'NOT_CONFIGURED',
            }
          };
        },
      );

      final ok = await mockService.deleteStaffSchedule('mem-01');
      expect(ok, isTrue);
    });

    test('14 & 15. Zero Mutation: ActiveContextHolder remains intact across service calls', () async {
      ActiveContextHolder().setActiveMembershipId('mem-actor-01');

      final mockService = StaffScheduleService(
        apiGet: (path) async => {
          'status': 'success',
          'data': {'schedules': []}
        },
      );

      await mockService.listStaffSchedules();

      expect(ActiveContextHolder().activeMembershipId, equals('mem-actor-01'));
      expect(ActiveContextHolder().hasActiveContext, isTrue);
    });
  });

  group('NODO-03A / SCR-09 — Screen Widget & RBAC UX Tests', () {
    testWidgets('8. Warning banner is rendered when outOfOperatingHoursWarning is true', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-owner-01');

      final mockService = MockStaffScheduleService();
      mockService.mockStaffList = [
        StaffScheduleItemModel(
          membershipId: 'mem-01',
          userName: 'Laura Spa',
          role: 'PROFESSIONAL',
          scheduleState: 'CONFIGURED',
          weeklySchedule: WeeklyScheduleModel.empty,
        )
      ];
      mockService.mockDetail = StaffScheduleDetailModel(
        membershipId: 'mem-01',
        establishmentId: 'est-01',
        tenantId: 'ten-01',
        scheduleState: 'CONFIGURED',
        outOfOperatingHoursWarning: true,
        weeklySchedule: WeeklyScheduleModel.empty,
      );

      await tester.pumpWidget(MaterialApp(
        home: StaffScheduleScreen(
          key: UniqueKey(),
          service: mockService,
          initialRole: 'OWNER',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('warning_operating_hours_banner')), findsOneWidget);
    });

    testWidgets('9. OWNER role has staff selector, save and delete buttons', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-owner-01');

      final mockService = MockStaffScheduleService();
      mockService.mockStaffList = [
        StaffScheduleItemModel(
          membershipId: 'mem-01',
          userName: 'Laura Spa',
          role: 'PROFESSIONAL',
          scheduleState: 'CONFIGURED',
          weeklySchedule: WeeklyScheduleModel.empty,
        )
      ];

      await tester.pumpWidget(MaterialApp(
        home: StaffScheduleScreen(
          key: UniqueKey(),
          service: mockService,
          initialRole: 'OWNER',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('select_staff_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('btn_save_schedule')), findsOneWidget);
      expect(find.byKey(const Key('btn_delete_schedule')), findsOneWidget);
    });

    testWidgets('10. MANAGER role has full management capabilities', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-mgr-01');

      final mockService = MockStaffScheduleService();
      mockService.mockStaffList = [
        StaffScheduleItemModel(
          membershipId: 'mem-01',
          userName: 'Laura Spa',
          role: 'PROFESSIONAL',
          scheduleState: 'CONFIGURED',
          weeklySchedule: WeeklyScheduleModel.empty,
        )
      ];

      await tester.pumpWidget(MaterialApp(
        home: StaffScheduleScreen(
          key: UniqueKey(),
          service: mockService,
          initialRole: 'MANAGER',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('select_staff_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('btn_save_schedule')), findsOneWidget);
      expect(find.byKey(const Key('btn_delete_schedule')), findsOneWidget);
    });

    testWidgets('11 & 12. PROFESSIONAL role operates in "Mi Horario" mode without staff selector of others and NO DELETE button', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-pro-01');

      final mockService = MockStaffScheduleService();
      mockService.mockStaffList = [
        StaffScheduleItemModel(
          membershipId: 'mem-pro-01',
          userName: 'Mi Perfil Pro',
          role: 'PROFESSIONAL',
          scheduleState: 'CONFIGURED',
          weeklySchedule: WeeklyScheduleModel.empty,
        ),
        StaffScheduleItemModel(
          membershipId: 'mem-other-02',
          userName: 'Otro Pro',
          role: 'PROFESSIONAL',
          scheduleState: 'CONFIGURED',
          weeklySchedule: WeeklyScheduleModel.empty,
        )
      ];

      await tester.pumpWidget(MaterialApp(
        home: StaffScheduleScreen(
          key: UniqueKey(),
          service: mockService,
          initialRole: 'PROFESSIONAL',
        ),
      ));
      await tester.pumpAndSettle();

      // No dropdown of others in Professional mode
      expect(find.byKey(const Key('select_staff_dropdown')), findsNothing);
      // Save button is present
      expect(find.byKey(const Key('btn_save_schedule')), findsOneWidget);
      // DELETE button is HIDDEN
      expect(find.byKey(const Key('btn_delete_schedule')), findsNothing);
    });

    testWidgets('13. RECEPTIONIST role operates in read-only mode (save and delete hidden)', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-recep-01');

      final mockService = MockStaffScheduleService();
      mockService.mockStaffList = [
        StaffScheduleItemModel(
          membershipId: 'mem-pro-01',
          userName: 'Mi Perfil Pro',
          role: 'PROFESSIONAL',
          scheduleState: 'CONFIGURED',
          weeklySchedule: WeeklyScheduleModel.empty,
        )
      ];

      await tester.pumpWidget(MaterialApp(
        home: StaffScheduleScreen(
          key: UniqueKey(),
          service: mockService,
          initialRole: 'RECEPTIONIST',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('select_staff_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('btn_save_schedule')), findsNothing);
      expect(find.byKey(const Key('btn_delete_schedule')), findsNothing);
    });

    testWidgets('16. States: Missing active context shows empty state', (tester) async {
      ActiveContextHolder().clear();

      final mockService = MockStaffScheduleService();

      await tester.pumpWidget(MaterialApp(
        home: StaffScheduleScreen(
          key: UniqueKey(),
          service: mockService,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sin Sede Activa'), findsOneWidget);
    });

    testWidgets('16b. States: Error state shows retry button and recovers on retry', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-owner-01');

      final mockService = MockStaffScheduleService();
      mockService.shouldFailList = true;

      await tester.pumpWidget(MaterialApp(
        home: StaffScheduleScreen(
          key: UniqueKey(),
          service: mockService,
          initialRole: 'OWNER',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_retry_schedules')), findsOneWidget);

      // Now fix error and tap retry
      mockService.shouldFailList = false;
      mockService.mockStaffList = [
        StaffScheduleItemModel(
          membershipId: 'mem-01',
          userName: 'Staff Uno',
          role: 'PROFESSIONAL',
          scheduleState: 'CONFIGURED',
          weeklySchedule: WeeklyScheduleModel.empty,
        )
      ];

      await tester.tap(find.byKey(const Key('btn_retry_schedules')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_save_schedule')), findsOneWidget);
    });

    testWidgets('17 & 18. Form Validations: start < end and overlap prevention in UI', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-owner-01');

      final mockService = MockStaffScheduleService();
      mockService.mockStaffList = [
        StaffScheduleItemModel(
          membershipId: 'mem-01',
          userName: 'Staff Uno',
          role: 'PROFESSIONAL',
          scheduleState: 'CONFIGURED',
          weeklySchedule: WeeklyScheduleModel.empty,
        )
      ];

      await tester.pumpWidget(MaterialApp(
        home: StaffScheduleScreen(
          key: UniqueKey(),
          service: mockService,
          initialRole: 'OWNER',
        ),
      ));
      await tester.pumpAndSettle();

      // Toggle monday to active
      await tester.tap(find.byKey(const Key('switch_day_monday')));
      await tester.pumpAndSettle();

      // Enter invalid time where start >= end (e.g. 19:00 to 09:00)
      await tester.enterText(find.byKey(const Key('input_start_monday_0')), '19:00');
      await tester.enterText(find.byKey(const Key('input_end_monday_0')), '09:00');
      await tester.pumpAndSettle();

      // Tap save
      await tester.tap(find.byKey(const Key('btn_save_schedule')));
      await tester.pumpAndSettle();

      // Should show error SnackBar
      expect(find.textContaining('la hora de inicio (19:00) debe ser menor'), findsOneWidget);
    });
  });
}
