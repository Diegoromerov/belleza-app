// frontend/test/saas_service_offer_assignment_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas/hub_salon_model.dart';
import 'package:beauty_app/models/saas/service_offer_assignment_model.dart';
import 'package:beauty_app/screens/saas/service_offer_assignment_screen.dart';
import 'package:beauty_app/services/active_context_holder.dart';
import 'package:beauty_app/services/saas/service_offer_assignment_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ActiveContextHolder().resetForTesting();
  });

  tearDown(() {
    ActiveContextHolder().resetForTesting();
  });

  group('NODO-02 / SCR-08 — DTO & Model Unit Tests', () {
    test('ServiceOfferModel parses valid JSON correctly', () {
      final json = {
        'id': 'offer-uuid-1',
        'tenant_id': 2,
        'establishment_id': 'est-uuid-1',
        'name': 'Corte Clásico',
        'description': 'Corte y peinado',
        'base_duration': 45,
        'base_price': '50000.00',
        'created_at': '2026-03-01T10:00:00.000Z',
        'updated_at': '2026-03-01T10:30:00.000Z',
      };

      final model = ServiceOfferModel.fromJson(json);

      expect(model.id, 'offer-uuid-1');
      expect(model.tenantId, 2);
      expect(model.establishmentId, 'est-uuid-1');
      expect(model.name, 'Corte Clásico');
      expect(model.description, 'Corte y peinado');
      expect(model.baseDuration, 45);
      expect(model.basePrice, 50000.00);
      expect(model.createdAt, isNotNull);
      expect(model.updatedAt, isNotNull);

      final outJson = model.toJson();
      expect(outJson['name'], 'Corte Clásico');
      expect(outJson['base_duration'], 45);
      expect(outJson['base_price'], 50000.00);
    });

    test('ServiceAssignmentModel parses valid JSON correctly', () {
      final json = {
        'id': 'assign-uuid-1',
        'tenant_id': 2,
        'establishment_id': 'est-uuid-1',
        'service_offer_id': 'offer-uuid-1',
        'membership_id': 'mem-uuid-1',
        'created_at': '2026-03-01T10:00:00.000Z',
      };

      final model = ServiceAssignmentModel.fromJson(json);

      expect(model.id, 'assign-uuid-1');
      expect(model.tenantId, 2);
      expect(model.establishmentId, 'est-uuid-1');
      expect(model.serviceOfferId, 'offer-uuid-1');
      expect(model.membershipId, 'mem-uuid-1');
      expect(model.createdAt, isNotNull);
    });

    test('ServiceOfferFormData validation enforces domain boundaries', () {
      final valid = ServiceOfferFormData(
        name: 'Manicura Spa',
        description: 'Limpieza e hidratación',
        baseDuration: 60,
        basePrice: 35000.0,
      );
      expect(valid.validate(), isNull);

      final emptyName = ServiceOfferFormData(
        name: '   ',
        baseDuration: 60,
        basePrice: 10000.0,
      );
      expect(emptyName.validate(), contains('nombre'));

      final badDuration = ServiceOfferFormData(
        name: 'Tinte',
        baseDuration: 0,
        basePrice: 10000.0,
      );
      expect(badDuration.validate(), contains('duración'));

      final tooLongDuration = ServiceOfferFormData(
        name: 'Tinte',
        baseDuration: 1500,
        basePrice: 10000.0,
      );
      expect(tooLongDuration.validate(), contains('duración'));

      final negativePrice = ServiceOfferFormData(
        name: 'Lavado',
        baseDuration: 15,
        basePrice: -500.0,
      );
      expect(negativePrice.validate(), contains('precio'));
    });

    test('ServiceAssignmentFormData validation requires both IDs', () {
      final valid = ServiceAssignmentFormData(
        serviceOfferId: 'offer-1',
        membershipId: 'mem-1',
      );
      expect(valid.validate(), isNull);

      final emptyOffer = ServiceAssignmentFormData(
        serviceOfferId: '',
        membershipId: 'mem-1',
      );
      expect(emptyOffer.validate(), isNotNull);

      final emptyMember = ServiceAssignmentFormData(
        serviceOfferId: 'offer-1',
        membershipId: '',
      );
      expect(emptyMember.validate(), isNotNull);
    });
  });

  group('NODO-02 / SCR-08 — Service Layer Unit Tests', () {
    test('listServiceOffers parses API response correctly', () async {
      final mockService = ServiceOfferAssignmentService(
        apiGet: (path) async {
          expect(path, '/api/v1/saas/hub/services');
          return {
            'status': 'success',
            'data': {
              'service_offers': [
                {
                  'id': 'offer-1',
                  'tenant_id': 2,
                  'establishment_id': 'est-1',
                  'name': 'Corte',
                  'description': 'Corte estándar',
                  'base_duration': 30,
                  'base_price': 25000.0,
                },
              ],
              'count': 1,
            },
          };
        },
      );

      final offers = await mockService.listServiceOffers();
      expect(offers.length, 1);
      expect(offers.first.id, 'offer-1');
      expect(offers.first.name, 'Corte');
    });

    test('createServiceOffer sends validated payload and returns created model', () async {
      final mockService = ServiceOfferAssignmentService(
        apiPost: (path, body) async {
          expect(path, '/api/v1/saas/hub/services');
          expect(body['name'], 'Peinado Fiesta');
          expect(body['base_duration'], 45);
          expect(body['base_price'], 40000.0);
          return {
            'status': 'success',
            'data': {
              'service_offer': {
                'id': 'offer-new',
                'tenant_id': 2,
                'establishment_id': 'est-1',
                'name': 'Peinado Fiesta',
                'description': null,
                'base_duration': 45,
                'base_price': 40000.0,
              },
            },
          };
        },
      );

      final form = ServiceOfferFormData(
        name: 'Peinado Fiesta',
        baseDuration: 45,
        basePrice: 40000.0,
      );

      final created = await mockService.createServiceOffer(form);
      expect(created.id, 'offer-new');
      expect(created.name, 'Peinado Fiesta');
    });

    test('updateServiceOffer sends PUT request and returns updated model', () async {
      final mockService = ServiceOfferAssignmentService(
        apiPut: (path, body) async {
          expect(path, '/api/v1/saas/hub/services/offer-1');
          expect(body['name'], 'Corte Deluxe');
          return {
            'status': 'success',
            'data': {
              'service_offer': {
                'id': 'offer-1',
                'tenant_id': 2,
                'establishment_id': 'est-1',
                'name': 'Corte Deluxe',
                'description': 'Corte y barba',
                'base_duration': 60,
                'base_price': 35000.0,
              },
            },
          };
        },
      );

      final form = ServiceOfferFormData(
        name: 'Corte Deluxe',
        description: 'Corte y barba',
        baseDuration: 60,
        basePrice: 35000.0,
      );

      final updated = await mockService.updateServiceOffer('offer-1', form);
      expect(updated.id, 'offer-1');
      expect(updated.name, 'Corte Deluxe');
      expect(updated.baseDuration, 60);
    });

    test('getEligibleStaff filters ACTIVE status and excludes RECEPTIONIST', () async {
      final mockService = ServiceOfferAssignmentService(
        apiGet: (path) async {
          expect(path, '/api/v1/saas/hub/staff');
          return {
            'status': 'success',
            'data': {
              'establishment_id': 'est-1',
              'staff_count': 5,
              'members': [
                {
                  'membership_id': 'mem-owner',
                  'user_id': 1,
                  'user_name': 'Owner User',
                  'user_email': 'owner@test.com',
                  'role': 'OWNER',
                  'relation_type': 'OWNER',
                  'status': 'ACTIVE',
                },
                {
                  'membership_id': 'mem-manager',
                  'user_id': 2,
                  'user_name': 'Manager User',
                  'user_email': 'manager@test.com',
                  'role': 'MANAGER',
                  'relation_type': 'STAFF_EMPLOYEE',
                  'status': 'ACTIVE',
                },
                {
                  'membership_id': 'mem-prof',
                  'user_id': 3,
                  'user_name': 'Prof User',
                  'user_email': 'prof@test.com',
                  'role': 'PROFESSIONAL',
                  'relation_type': 'STAFF_EMPLOYEE',
                  'status': 'ACTIVE',
                },
                {
                  'membership_id': 'mem-recep',
                  'user_id': 4,
                  'user_name': 'Recep User',
                  'user_email': 'recep@test.com',
                  'role': 'RECEPTIONIST',
                  'relation_type': 'STAFF_EMPLOYEE',
                  'status': 'ACTIVE',
                },
                {
                  'membership_id': 'mem-suspended',
                  'user_id': 5,
                  'user_name': 'Suspended Prof',
                  'user_email': 'susp@test.com',
                  'role': 'PROFESSIONAL',
                  'relation_type': 'STAFF_EMPLOYEE',
                  'status': 'SUSPENDED',
                },
              ],
            },
          };
        },
      );

      final eligible = await mockService.getEligibleStaff();

      expect(eligible.length, 3);
      final roles = eligible.map((m) => m.role).toList();
      expect(roles, containsAll(['OWNER', 'MANAGER', 'PROFESSIONAL']));
      expect(roles, isNot(contains('RECEPTIONIST')));
      expect(eligible.any((m) => m.status != 'ACTIVE'), isFalse);
    });

    test('createAssignment sends payload and handles 409 duplicate assignment correctly', () async {
      final mockService = ServiceOfferAssignmentService(
        apiPost: (path, body) async {
          throw Exception('ASSIGNMENT_ALREADY_EXISTS: 409 Conflict');
        },
      );

      final form = ServiceAssignmentFormData(
        serviceOfferId: 'offer-1',
        membershipId: 'mem-prof',
      );

      try {
        await mockService.createAssignment(form);
        fail('Debe lanzar ServiceOfferAssignmentException con status 409');
      } catch (e) {
        expect(e, isA<ServiceOfferAssignmentException>());
        final err = e as ServiceOfferAssignmentException;
        expect(err.statusCode, 409);
        expect(err.errorCode, 'ASSIGNMENT_ALREADY_EXISTS');
      }
    });

    test('deleteAssignment sends DELETE request and returns true (pure unassignment)', () async {
      final mockService = ServiceOfferAssignmentService(
        apiDelete: (path, [body]) async {
          expect(path, '/api/v1/saas/hub/assignments/assign-1');
          return {
            'status': 'success',
            'data': {
              'deleted_id': 'assign-1',
              'unassigned': true,
            },
          };
        },
      );

      final result = await mockService.deleteAssignment('assign-1');
      expect(result, isTrue);
    });

    test('Zero Mutation: Queries do not alter ActiveContextHolder', () async {
      ActiveContextHolder().setActiveMembershipId('mem-test-id');

      final mockService = ServiceOfferAssignmentService(
        apiGet: (path) async => {
          'status': 'success',
          'data': {'service_offers': []}
        },
      );

      await mockService.listServiceOffers();

      expect(ActiveContextHolder().activeMembershipId, 'mem-test-id');
      expect(ActiveContextHolder().hasActiveContext, isTrue);
    });
  });

  group('NODO-02 / SCR-08 — Screen Widget & UX Tests', () {
    Widget createWidgetUnderTest(ServiceOfferAssignmentService service, {String? initialRole}) {
      return MaterialApp(
        home: ServiceOfferAssignmentScreen(
          service: service,
          initialRole: initialRole,
        ),
      );
    }

    final dummyOffers = [
      const ServiceOfferModel(
        id: 'offer-1',
        establishmentId: 'est-1',
        name: 'Corte de Cabello',
        description: 'Corte unisex',
        baseDuration: 30,
        basePrice: 30000.0,
      ),
    ];

    final dummyStaff = [
      const HubStaffMember(
        membershipId: 'mem-1',
        userId: 10,
        userName: 'Carlos Barbero',
        userEmail: 'carlos@test.com',
        role: 'PROFESSIONAL',
        relationType: 'STAFF_EMPLOYEE',
        status: 'ACTIVE',
      ),
    ];

    final dummyAssignments = [
      const ServiceAssignmentModel(
        id: 'assign-1',
        establishmentId: 'est-1',
        serviceOfferId: 'offer-1',
        membershipId: 'mem-1',
      ),
    ];

    testWidgets('Renders loading indicator and then loaded data', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-1');

      final mockService = ServiceOfferAssignmentService(
        apiGet: (path) async {
          if (path.contains('/services')) {
            return {
              'status': 'success',
              'data': {
                'service_offers': [dummyOffers.first.toJson()],
              },
            };
          }
          if (path.contains('/assignments')) {
            return {
              'status': 'success',
              'data': {
                'assignments': [dummyAssignments.first.toJson()],
              },
            };
          }
          if (path.contains('/staff')) {
            return {
              'status': 'success',
              'data': {
                'members': [dummyStaff.first.toJson()],
              },
            };
          }
          return {};
        },
      );

      await tester.pumpWidget(createWidgetUnderTest(mockService));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Servicios y Asignaciones'), findsOneWidget);
      expect(find.text('Corte de Cabello'), findsOneWidget);
      expect(find.text('30 min'), findsOneWidget);
      expect(find.text('\$30000.00'), findsOneWidget);
    });

    testWidgets('OWNER role displays mutation buttons (+ Nueva Oferta)', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-owner');

      final ownerStaff = [
        const HubStaffMember(
          membershipId: 'mem-owner',
          userId: 1,
          userName: 'Owner Person',
          userEmail: 'owner@test.com',
          role: 'OWNER',
          relationType: 'OWNER',
          status: 'ACTIVE',
        ),
      ];

      final mockService = ServiceOfferAssignmentService(
        apiGet: (path) async => {
          'status': 'success',
          'data': {
            'service_offers': [dummyOffers.first.toJson()],
            'assignments': [],
            'members': [ownerStaff.first.toJson()],
          }
        },
      );

      await tester.pumpWidget(createWidgetUnderTest(mockService, initialRole: 'OWNER'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('PROFESSIONAL role operates in read-only mode (mutation buttons hidden)', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-prof');

      final profStaff = [
        const HubStaffMember(
          membershipId: 'mem-prof',
          userId: 2,
          userName: 'Prof Person',
          userEmail: 'prof@test.com',
          role: 'PROFESSIONAL',
          relationType: 'STAFF_EMPLOYEE',
          status: 'ACTIVE',
        ),
      ];

      final mockService = ServiceOfferAssignmentService(
        apiGet: (path) async => {
          'status': 'success',
          'data': {
            'service_offers': [dummyOffers.first.toJson()],
            'assignments': [],
            'members': [profStaff.first.toJson()],
          }
        },
      );

      await tester.pumpWidget(createWidgetUnderTest(mockService, initialRole: 'PROFESSIONAL'));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('Switching tabs displays Assignments list', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-1');

      final mockService = ServiceOfferAssignmentService(
        apiGet: (path) async {
          if (path.contains('/services')) {
            return {
              'status': 'success',
              'data': {'service_offers': [dummyOffers.first.toJson()]},
            };
          }
          if (path.contains('/assignments')) {
            return {
              'status': 'success',
              'data': {'assignments': [dummyAssignments.first.toJson()]},
            };
          }
          if (path.contains('/staff')) {
            return {
              'status': 'success',
              'data': {'members': [dummyStaff.first.toJson()]},
            };
          }
          return {};
        },
      );

      await tester.pumpWidget(createWidgetUnderTest(mockService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Asignaciones (1)'));
      await tester.pumpAndSettle();

      expect(find.text('Carlos Barbero'), findsOneWidget);
      expect(find.text('PROFESSIONAL'), findsOneWidget);
    });

    testWidgets('Missing active context shows informative empty state', (tester) async {
      ActiveContextHolder().clear();

      final mockService = ServiceOfferAssignmentService();

      await tester.pumpWidget(createWidgetUnderTest(mockService));
      await tester.pumpAndSettle();

      expect(find.text('Sin Sede Activa'), findsOneWidget);
      expect(find.text('Seleccionar Sede'), findsOneWidget);
    });
  });
}
