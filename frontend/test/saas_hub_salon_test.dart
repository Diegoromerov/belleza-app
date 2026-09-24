// frontend/test/saas_hub_salon_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas/hub_salon_model.dart';
import 'package:beauty_app/services/hub_salon_service.dart';
import 'package:beauty_app/screens/saas/hub_salon_screen.dart';
import 'package:beauty_app/services/active_context_holder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String testEstId = 'c625ebfa-fb6b-4b20-928d-cf42dca9c3da';
  const String testOrgId = 'e9a8d9b1-5360-4963-b847-a7ea6d123b38';
  const String testMembershipId = 'b3c2a1e0-7489-4a5f-8b2c-9d8e7f6a5b4c';
  const String staffMembershipId = 'f1e2d3c4-b5a6-4978-8899-001122334455';

  final sampleSummaryPayload = {
    'ok': true,
    'summary': {
      'establishment': {
        'id': testEstId,
        'name': 'Salón Central Chicó',
        'slug': 'salon-central-chico',
        'phone': '+573001112233',
        'address': 'Calle 100 # 15-20',
        'city': 'Bogotá',
        'is_active': true,
        'operating_hours': {
          'monday': {'open': '08:00', 'close': '20:00'}
        }
      },
      'organization': {
        'id': testOrgId,
        'legal_name': 'Belleza Integral S.A.S.'
      },
      'active_user_context': {
        'membership_id': testMembershipId,
        'role': 'OWNER',
        'relation_type': 'OWNER_PARTNER',
        'status': 'ACTIVE'
      },
      'staff_summary': {
        'active_members_count': 2
      }
    }
  };

  final sampleStaffPayload = {
    'ok': true,
    'establishment_id': testEstId,
    'staff_count': 2,
    'members': [
      {
        'membership_id': testMembershipId,
        'user_id': 7,
        'user_name': 'Diego Romero',
        'user_email': 'diego@glowapp.com',
        'role': 'OWNER',
        'relation_type': 'OWNER_PARTNER',
        'status': 'ACTIVE',
        'joined_at': '2026-03-01T10:00:00.000Z'
      },
      {
        'membership_id': staffMembershipId,
        'user_id': 12,
        'user_name': 'Laura Estilista',
        'user_email': 'laura@glowapp.com',
        'role': 'PROFESSIONAL',
        'relation_type': 'STAFF_EMPLOYEE',
        'status': 'ACTIVE',
        'joined_at': '2026-03-05T14:30:00.000Z'
      }
    ]
  };

  final sampleEmptyStaffPayload = {
    'ok': true,
    'establishment_id': testEstId,
    'staff_count': 0,
    'members': []
  };

  setUp(() {
    ActiveContextHolder().resetForTesting();
  });

  tearDown(() {
    ActiveContextHolder().resetForTesting();
  });

  group('NODO-07 FASE 4 — Hub Salon Model & DTO Tests', () {
    test('1. Parseo completo de HubSummaryResponse con datos canónicos', () {
      final response = HubSummaryResponse.fromJson(sampleSummaryPayload);
      expect(response.ok, isTrue);
      expect(response.summary.establishment.id, equals(testEstId));
      expect(response.summary.establishment.name, equals('Salón Central Chicó'));
      expect(response.summary.establishment.phone, equals('+573001112233'));
      expect(response.summary.establishment.isActive, isTrue);
      expect(response.summary.establishment.operatingHours?['monday']['open'], equals('08:00'));

      expect(response.summary.organization.id, equals(testOrgId));
      expect(response.summary.organization.legalName, equals('Belleza Integral S.A.S.'));

      expect(response.summary.activeUserContext.membershipId, equals(testMembershipId));
      expect(response.summary.activeUserContext.role, equals('OWNER'));
      expect(response.summary.activeUserContext.relationType, equals('OWNER_PARTNER'));

      expect(response.summary.staffSummary.activeMembersCount, equals(2));
    });

    test('2. Parseo completo de HubStaffResponse con rol canónico PROFESSIONAL', () {
      final response = HubStaffResponse.fromJson(sampleStaffPayload);
      expect(response.ok, isTrue);
      expect(response.establishmentId, equals(testEstId));
      expect(response.staffCount, equals(2));
      expect(response.members.length, equals(2));

      final member1 = response.members[0];
      expect(member1.membershipId, equals(testMembershipId));
      expect(member1.userName, equals('Diego Romero'));
      expect(member1.role, equals('OWNER'));
      expect(member1.joinedAt, isA<DateTime>());

      final member2 = response.members[1];
      expect(member2.membershipId, equals(staffMembershipId));
      expect(member2.userName, equals('Laura Estilista'));
      expect(member2.role, equals('PROFESSIONAL'));
    });

    test('3. Parseo de DTO con campos opcionales nulos', () {
      final minimalSummary = {
        'ok': true,
        'summary': {
          'establishment': {
            'id': testEstId,
            'name': 'Salón Mínimo',
            'slug': 'salon-minimo',
            'is_active': false
          },
          'organization': {
            'id': testOrgId,
            'legal_name': 'Org Demo'
          },
          'active_user_context': {
            'membership_id': testMembershipId,
            'role': 'PROFESSIONAL',
            'relation_type': 'STAFF_EMPLOYEE',
            'status': 'ACTIVE'
          },
          'staff_summary': {
            'active_members_count': 0
          }
        }
      };

      final response = HubSummaryResponse.fromJson(minimalSummary);
      expect(response.summary.establishment.phone, isNull);
      expect(response.summary.establishment.address, isNull);
      expect(response.summary.establishment.city, isNull);
      expect(response.summary.establishment.operatingHours, isNull);
      expect(response.summary.establishment.isActive, isFalse);

      final minimalStaffMember = HubStaffMember.fromJson({
        'membership_id': 'm1',
        'user_name': 'Sin Fecha',
        'role': 'RECEPTIONIST'
      });
      expect(minimalStaffMember.joinedAt, isNull);
      expect(minimalStaffMember.userEmail, isEmpty);
    });
  });

  group('NODO-07 FASE 4 — HubSalonService Tests', () {
    test('4. getSummary() ejecuta llamada y devuelve HubSummaryResponse', () async {
      final service = HubSalonService(
        apiGet: (path) async {
          expect(path, equals('/api/v1/saas/hub/summary'));
          return sampleSummaryPayload;
        },
      );

      final summary = await service.getSummary();
      expect(summary.ok, isTrue);
      expect(summary.summary.establishment.name, equals('Salón Central Chicó'));
    });

    test('5. getStaff() ejecuta llamada y devuelve HubStaffResponse', () async {
      final service = HubSalonService(
        apiGet: (path) async {
          expect(path, equals('/api/v1/saas/hub/staff'));
          return sampleStaffPayload;
        },
      );

      final staff = await service.getStaff();
      expect(staff.ok, isTrue);
      expect(staff.members.length, equals(2));
    });

    test('6. getCockpitData() maneja partial_success cuando staff falla pero summary es exitoso', () async {
      final service = HubSalonService(
        apiGet: (path) async {
          if (path == '/api/v1/saas/hub/summary') {
            return sampleSummaryPayload;
          }
          throw Exception('Timeout al consultar staff');
        },
      );

      final cockpit = await service.getCockpitData();
      expect(cockpit.summary.ok, isTrue);
      expect(cockpit.staff, isNull);
      expect(cockpit.hasStaffError, isTrue);
      expect(cockpit.staffError, contains('Timeout'));
    });
  });

  group('NODO-07 FASE 4 — HubSalonScreen Widget & State Tests', () {
    testWidgets('7. Estado: active_context_missing cuando activeMembershipId es null', (tester) async {
      // ActiveContextHolder está en null por setUp
      expect(ActiveContextHolder().activeMembershipId, isNull);

      await tester.pumpWidget(
        MaterialApp(
          home: HubSalonScreen(
            service: HubSalonService(
              apiGet: (path) async => throw Exception('No debe invocarse'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Contexto de Salón No Seleccionado'), findsOneWidget);
      expect(find.text('Seleccionar Sede Operativa'), findsOneWidget);
      expect(find.byKey(const Key('btn_seleccionar_contexto_missing')), findsOneWidget);
    });

    testWidgets('8. Estado: loaded con datos de sede, métricas y directorio de personal', (tester) async {
      ActiveContextHolder().setActiveMembershipId(testMembershipId);

      final mockService = HubSalonService(
        apiGet: (path) async {
          if (path == '/api/v1/saas/hub/summary') return sampleSummaryPayload;
          if (path == '/api/v1/saas/hub/staff') return sampleStaffPayload;
          throw Exception('Ruta no esperada: $path');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HubSalonScreen(service: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Sección AppBar y Contexto
      expect(find.text('Salón Central Chicó'), findsOneWidget);
      expect(find.text('Belleza Integral S.A.S.'), findsOneWidget);
      expect(find.text('OPERACIONAL'), findsOneWidget);
      expect(find.text('Rol Asignado: OWNER'), findsOneWidget);

      // Sección Sede
      expect(find.text('Calle 100 # 15-20 (Bogotá)'), findsOneWidget);
      expect(find.text('+573001112233'), findsOneWidget);

      // Sección Métricas (No data -> No card)
      expect(find.text('2 colaboradores'), findsOneWidget);
      expect(find.text('Citas Hoy'), findsNothing); // 🛡️ Regla crítica respetada

      // Sección Módulos
      expect(find.byKey(const Key('btn_modulo_catalogo')), findsOneWidget);
      expect(find.byKey(const Key('btn_modulo_personal')), findsOneWidget);
      expect(find.byKey(const Key('btn_modulo_agenda')), findsOneWidget);

      // Sección Directorio Staff
      expect(find.text('Diego Romero'), findsOneWidget);
      expect(find.text('Laura Estilista'), findsOneWidget);
      expect(find.text('PROFESSIONAL'), findsOneWidget);
    });

    testWidgets('9. Estado: empty_staff cuando la sede no tiene miembros adscritos', (tester) async {
      ActiveContextHolder().setActiveMembershipId(testMembershipId);

      final mockService = HubSalonService(
        apiGet: (path) async {
          if (path == '/api/v1/saas/hub/summary') return sampleSummaryPayload;
          if (path == '/api/v1/saas/hub/staff') return sampleEmptyStaffPayload;
          throw Exception('Ruta no esperada: $path');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HubSalonScreen(service: mockService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No hay personal registrado en esta sede'), findsOneWidget);
    });

    testWidgets('10. Estado: partial_success cuando staff falla y permite reintento', (tester) async {
      ActiveContextHolder().setActiveMembershipId(testMembershipId);

      int staffCalls = 0;

      final mockService = HubSalonService(
        apiGet: (path) async {
          if (path == '/api/v1/saas/hub/summary') return sampleSummaryPayload;
          if (path == '/api/v1/saas/hub/staff') {
            staffCalls++;
            if (staffCalls == 1) {
              throw Exception('Error temporal de staff');
            }
            return sampleStaffPayload;
          }
          throw Exception('Ruta no esperada: $path');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HubSalonScreen(service: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // Summary debe estar visible
      expect(find.text('Salón Central Chicó'), findsOneWidget);
      // Banner de fallo de staff
      expect(find.text('No se pudo sincronizar el detalle del personal.'), findsOneWidget);
      expect(find.byKey(const Key('btn_reintentar_staff')), findsOneWidget);

      // Scroll para asegurar visibilidad antes de tap
      await tester.ensureVisible(find.byKey(const Key('btn_reintentar_staff')));
      await tester.pumpAndSettle();

      // Ejecutar reintento de staff
      await tester.tap(find.byKey(const Key('btn_reintentar_staff')));
      await tester.pumpAndSettle();

      // Ahora el staff debe aparecer cargado
      expect(find.text('Laura Estilista'), findsOneWidget);
      expect(staffCalls, equals(2));
    });

    testWidgets('11. Estado: error_summary permite reintentar carga completa', (tester) async {
      ActiveContextHolder().setActiveMembershipId(testMembershipId);

      int summaryCalls = 0;

      final mockService = HubSalonService(
        apiGet: (path) async {
          if (path == '/api/v1/saas/hub/summary') {
            summaryCalls++;
            if (summaryCalls == 1) {
              throw Exception('Error 500 en backend');
            }
            return sampleSummaryPayload;
          }
          if (path == '/api/v1/saas/hub/staff') return sampleStaffPayload;
          throw Exception('Ruta no esperada: $path');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HubSalonScreen(service: mockService),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Error al Cargar Hub Salón'), findsOneWidget);
      expect(find.byKey(const Key('btn_reintentar_summary')), findsOneWidget);

      // Reintentar
      await tester.tap(find.byKey(const Key('btn_reintentar_summary')));
      await tester.pumpAndSettle();

      expect(find.text('Salón Central Chicó'), findsOneWidget);
      expect(summaryCalls, equals(2));
    });

    testWidgets('12. Invariante: HubScreen nunca muta setActiveMembershipId durante su carga', (tester) async {
      ActiveContextHolder().setActiveMembershipId(testMembershipId);

      final mockService = HubSalonService(
        apiGet: (path) async {
          if (path == '/api/v1/saas/hub/summary') return sampleSummaryPayload;
          if (path == '/api/v1/saas/hub/staff') return sampleStaffPayload;
          throw Exception('Error');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: HubSalonScreen(service: mockService),
        ),
      );

      await tester.pumpAndSettle();

      // El membership_id sigue siendo exactamente el mismo
      expect(ActiveContextHolder().activeMembershipId, equals(testMembershipId));
    });
  });
}
