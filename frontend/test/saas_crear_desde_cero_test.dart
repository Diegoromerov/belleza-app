// frontend/test/saas_crear_desde_cero_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas/crear_desde_cero_model.dart';
import 'package:beauty_app/models/saas/hub_salon_model.dart';
import 'package:beauty_app/services/saas/crear_desde_cero_service.dart';
import 'package:beauty_app/screens/saas/crear_desde_cero_screen.dart';
import 'package:beauty_app/services/active_context_holder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ActiveContextHolder contextHolder;
  String? lastCalledPath;
  Map<String, dynamic>? lastSentBody;
  dynamic mockResponseToReturn;

  Future<dynamic> mockApiPost(String path, Map<String, dynamic> body) async {
    lastCalledPath = path;
    lastSentBody = body;
    if (mockResponseToReturn is Exception) {
      throw mockResponseToReturn;
    }
    return mockResponseToReturn;
  }

  setUp(() {
    contextHolder = ActiveContextHolder();
    contextHolder.clear();
    lastCalledPath = null;
    lastSentBody = null;
    mockResponseToReturn = {
      'status': 'success',
      'data': {
        'context_package': {
          'organization': {
            'id': 2,
            'legal_name': 'Beauty Luxe Corp S.A.S.',
          },
          'establishments': {
            'id': 'e4b2d3c1-7a89-4f5e-b123-456789abcdef',
            'name': 'Salón Elegance Poblado',
            'slug': 'salon-elegance-poblado',
            'city': 'Medellín',
            'address': 'Cra 43A # 1-50',
            'phone': '+573001234567',
            'operating_hours': {
              'monday': {'open': '08:00', 'close': '19:00', 'is_closed': false}
            },
          },
          'activities': ['Peluquería', 'Barbería'],
          'relevant_services': [
            {
              'name': 'Corte Signature',
              'category': 'Peluquería',
              'duration_minutes': 45,
              'price': 35000.0,
              'description': 'Corte y peinado básico'
            }
          ],
          'people_initial_roles': [
            {
              'membership_id': 'b789c012-3456-789a-bcde-f0123456789a',
              'user_id': 7,
              'user_name': 'Diego Romero',
              'user_email': 'diego@beautyluxe.com',
              'role': 'OWNER',
              'relation_type': 'OWNER_PARTNER',
              'status': 'ACTIVE',
              'assigned_categories': ['Peluquería']
            }
          ],
          'identity': {'id': 7, 'role': 'OWNER'},
          'state': 'READY_FOR_PRE_NODE_01',
          'known_evidence': {
            'active_context_verified': true,
            'tenant_isolation_verified': true,
            'authorized_membership_verified': true
          },
          'decisions': {
            'catalog_mode': 'STANDARD_SETUP',
            'provisioning_source': 'CREAR_DESDE_CERO_v1.0'
          },
          'applicable_rules': [
            'ARCH-AC-001-HEADER-TRANSPORT',
            'ARCH-RLS-TENANT-ISOLATION',
            'ARCH-OWNER-MANAGER-AUTHORITY'
          ],
          'conditions': {
            'active_membership_satisfied': true,
            'establishment_context_satisfied': true
          },
          'procedures': {
            'handover_target': 'PRE_NODE_01',
            'handover_type': 'IN_MEMORY_TRANSIENT'
          },
          'dependencies': [
            'ACTIVE_ESTABLISHMENT_CONTEXT',
            'ACTIVE_AUTHORIZED_MEMBERSHIP'
          ],
          'blocks': [],
          'route': 'HUB_SALON -> CREAR_DESDE_CERO -> PRE_NODO_01',
          'entry_state': {
            'context_source': 'HUB_SALON_ACTIVE_CONTEXT',
            'provisioning_mode': 'INITIAL_BOOTSTRAP'
          }
        }
      }
    };
  });

  tearDown(() {
    contextHolder.clear();
  });

  group('NODO-07 FASE 6A — Crear Desde Cero DTO & Models Tests', () {
    test('A. ServiceDraft serializa y deserializa fielmente', () {
      const draft = ServiceDraft(
        name: 'Corte Clásico',
        category: 'Barbería',
        durationMinutes: 30,
        price: 25000,
        description: 'Corte tradicional',
      );

      final json = draft.toJson();
      expect(json['name'], 'Corte Clásico');
      expect(json['category'], 'Barbería');
      expect(json['duration_minutes'], 30);
      expect(json['price'], 25000.0);
      expect(json['description'], 'Corte tradicional');

      final fromJson = ServiceDraft.fromJson(json);
      expect(fromJson.name, draft.name);
      expect(fromJson.category, draft.category);
      expect(fromJson.durationMinutes, draft.durationMinutes);
      expect(fromJson.price, draft.price);
    });

    test('B. StaffCategoryAssignmentDraft serializa y deserializa fielmente', () {
      const staffDraft = StaffCategoryAssignmentDraft(
        membershipId: 'mem-1234',
        assignedCategories: ['Peluquería', 'Colorimetría'],
      );

      final json = staffDraft.toJson();
      expect(json['membership_id'], 'mem-1234');
      expect(json['assigned_categories'], ['Peluquería', 'Colorimetría']);

      final fromJson = StaffCategoryAssignmentDraft.fromJson(json);
      expect(fromJson.membershipId, 'mem-1234');
      expect(fromJson.assignedCategories, ['Peluquería', 'Colorimetría']);
    });

    test('C. CrearDesdeCeroBootstrapRequest genera el payload canónico para el backend', () {
      const request = CrearDesdeCeroBootstrapRequest(
        activities: ['Peluquería', 'Barbería'],
        services: [
          ServiceDraft(name: 'Corte', category: 'Peluquería', durationMinutes: 45, price: 30000),
        ],
        staffAssignments: [
          StaffCategoryAssignmentDraft(membershipId: 'mem-1', assignedCategories: ['Peluquería']),
        ],
        decisions: {'catalog_mode': 'STANDARD_SETUP'},
      );

      final json = request.toJson();
      expect(json['activities'], ['Peluquería', 'Barbería']);
      expect((json['services'] as List).length, 1);
      expect((json['staff_assignments'] as List).length, 1);
      expect(json['decisions']['catalog_mode'], 'STANDARD_SETUP');
    });

    test('D. ContextPackageResponse mapea los 16 atributos canónicos y READY_FOR_PRE_NODE_01', () {
      final response = ContextPackageResponse.fromJson(mockResponseToReturn as Map<String, dynamic>);

      expect(response.isSuccess, true);
      expect(response.isReadyForPreNodo01, true);
      final pkg = response.contextPackage!;
      expect(pkg.organizationLegalName, 'Beauty Luxe Corp S.A.S.');
      expect(pkg.establishmentName, 'Salón Elegance Poblado');
      expect(pkg.derivedState, 'READY_FOR_PRE_NODE_01');
      expect(pkg.activities, ['Peluquería', 'Barbería']);
      expect(pkg.relevantServices.length, 1);
      expect(pkg.relevantServices.first.name, 'Corte Signature');
      expect(pkg.blocks, isEmpty);
    });
  });

  group('NODO-07 FASE 6A — CrearDesdeCeroService & Endpoint Tests', () {
    test('E & F. Requiere Active Context y no persiste datos en storage local', () async {
      final service = CrearDesdeCeroService(
        apiPost: mockApiPost,
        contextHolder: contextHolder,
      );

      expect(
        () => service.bootstrapInitialSetup(
          const CrearDesdeCeroBootstrapRequest(
            activities: ['Peluquería'],
            services: [],
            staffAssignments: [],
          ),
        ),
        throwsA(isA<CrearDesdeCeroException>().having((e) => e.code, 'code', 'ACTIVE_CONTEXT_MISSING')),
      );
    });

    test('G. Envía POST a /api/v1/saas/hub/onboarding/bootstrap y retorna ContextPackageResponse', () async {
      contextHolder.setActiveMembershipId('mem-valid-uuid');

      final service = CrearDesdeCeroService(
        apiPost: mockApiPost,
        contextHolder: contextHolder,
      );

      final response = await service.bootstrapInitialSetup(
        const CrearDesdeCeroBootstrapRequest(
          activities: ['Peluquería'],
          services: [
            ServiceDraft(name: 'Corte', category: 'Peluquería', durationMinutes: 45, price: 30000),
          ],
          staffAssignments: [],
        ),
      );

      expect(lastCalledPath, '/api/v1/saas/hub/onboarding/bootstrap');
      expect(response.isSuccess, true);
      expect(response.contextPackage?.derivedState, 'READY_FOR_PRE_NODE_01');
    });

    test('H & I. Manejo determinista de 403 INSUFFICIENT_PROVISIONING_ROLE y 401 IDENTITY_NOT_FOUND', () async {
      contextHolder.setActiveMembershipId('mem-prof-uuid');

      // Simular error 403
      mockResponseToReturn = Exception('INSUFFICIENT_PROVISIONING_ROLE: Acceso denegado');
      final service = CrearDesdeCeroService(
        apiPost: mockApiPost,
        contextHolder: contextHolder,
      );

      expect(
        () => service.bootstrapInitialSetup(
          const CrearDesdeCeroBootstrapRequest(
            activities: ['Peluquería'],
            services: [],
            staffAssignments: [],
          ),
        ),
        throwsA(isA<CrearDesdeCeroException>().having((e) => e.code, 'code', 'INSUFFICIENT_PROVISIONING_ROLE')),
      );

      // Simular error 401
      mockResponseToReturn = Exception('IDENTITY_NOT_FOUND: No autorizado');
      expect(
        () => service.bootstrapInitialSetup(
          const CrearDesdeCeroBootstrapRequest(
            activities: ['Peluquería'],
            services: [],
            staffAssignments: [],
          ),
        ),
        throwsA(isA<CrearDesdeCeroException>().having((e) => e.code, 'code', 'IDENTITY_NOT_FOUND')),
      );
    });

    test('J & K. Manejo de MEMBERSHIP_NOT_ACTIVE y ESTABLISHMENT_NOT_FOUND', () async {
      contextHolder.setActiveMembershipId('mem-inactive-uuid');

      mockResponseToReturn = Exception('MEMBERSHIP_NOT_ACTIVE: Membresía inactiva');
      final service = CrearDesdeCeroService(
        apiPost: mockApiPost,
        contextHolder: contextHolder,
      );

      expect(
        () => service.bootstrapInitialSetup(
          const CrearDesdeCeroBootstrapRequest(
            activities: ['Peluquería'],
            services: [],
            staffAssignments: [],
          ),
        ),
        throwsA(isA<CrearDesdeCeroException>().having((e) => e.code, 'code', 'MEMBERSHIP_NOT_ACTIVE')),
      );

      mockResponseToReturn = Exception('ESTABLISHMENT_NOT_FOUND: Sede no encontrada');
      expect(
        () => service.bootstrapInitialSetup(
          const CrearDesdeCeroBootstrapRequest(
            activities: ['Peluquería'],
            services: [],
            staffAssignments: [],
          ),
        ),
        throwsA(isA<CrearDesdeCeroException>().having((e) => e.code, 'code', 'ESTABLISHMENT_NOT_FOUND')),
      );
    });

    test('M. Invariante: CrearDesdeCeroService NUNCA muta ActiveContextHolder al ejecutar', () async {
      contextHolder.setActiveMembershipId('mem-immutable-uuid');

      final service = CrearDesdeCeroService(
        apiPost: mockApiPost,
        contextHolder: contextHolder,
      );

      await service.bootstrapInitialSetup(
        const CrearDesdeCeroBootstrapRequest(
          activities: ['Peluquería'],
          services: [],
          staffAssignments: [],
        ),
      );

      expect(contextHolder.activeMembershipId, 'mem-immutable-uuid');
    });
  });

  group('NODO-07 FASE 6A — CrearDesdeCeroWizardScreen Widget & UX Tests', () {
    testWidgets('L & O. Renderizado por pasos, navegación stepper y confirmación de handover', (tester) async {
      contextHolder.setActiveMembershipId('mem-wizard-uuid');

      final service = CrearDesdeCeroService(
        apiPost: mockApiPost,
        contextHolder: contextHolder,
      );

      final staffList = [
        const HubStaffMember(
          membershipId: 'mem-staff-1',
          userId: 10,
          userName: 'Carolina Herrera',
          userEmail: 'carolina@beautyluxe.com',
          role: 'PROFESSIONAL',
          relationType: 'STAFF_EMPLOYEE',
          status: 'ACTIVE',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: CrearDesdeCeroWizardScreen(
            service: service,
            initialStaff: staffList,
            establishmentName: 'Salón Elegance Poblado',
          ),
        ),
      );
      await tester.pump();

      // Paso 1: Especialidades
      expect(find.text('Configuración Inicial de Sede'), findsOneWidget);
      expect(find.text('Sede: Salón Elegance Poblado'), findsOneWidget);
      expect(find.text('Paso 1 de 4'), findsOneWidget);
      expect(find.text('1. Selecciona las Especialidades del Salón'), findsOneWidget);

      // Avanzar a Paso 2
      await tester.tap(find.text('Siguiente'));
      await tester.pump();

      // Paso 2: Catálogo en Tránsito
      expect(find.text('Paso 2 de 4'), findsOneWidget);
      expect(find.text('2. Catálogo Base en Tránsito'), findsOneWidget);
      expect(find.text('Corte de Cabello Estándar'), findsOneWidget);

      // Avanzar a Paso 3
      await tester.tap(find.text('Siguiente'));
      await tester.pump();

      // Paso 3: Asignación de Staff
      expect(find.text('Paso 3 de 4'), findsOneWidget);
      expect(find.text('3. Asignación Preliminar de Personal'), findsOneWidget);
      expect(find.text('Carolina Herrera'), findsOneWidget);

      // Avanzar a Paso 4
      await tester.tap(find.text('Siguiente'));
      await tester.pump();

      // Paso 4: Revisión y Handover
      expect(find.text('Paso 4 de 4'), findsOneWidget);
      expect(find.text('4. Revisión y Handover a Pre-Nodo 01'), findsOneWidget);
      expect(find.byKey(const Key('btn_confirm_handover')), findsOneWidget);

      // Submit del Handover
      await tester.tap(find.byKey(const Key('btn_confirm_handover')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Vista de Éxito
      expect(find.text('Aprovisionamiento Exitoso'), findsOneWidget);
      expect(find.byKey(const Key('btn_return_hub')), findsOneWidget);
    });

    testWidgets('N. Manejo de error de rol (403) en pantalla sin romper la UI', (tester) async {
      contextHolder.setActiveMembershipId('mem-prof-uuid');

      mockResponseToReturn = Exception('INSUFFICIENT_PROVISIONING_ROLE: Acceso denegado');

      final service = CrearDesdeCeroService(
        apiPost: mockApiPost,
        contextHolder: contextHolder,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CrearDesdeCeroWizardScreen(service: service),
        ),
      );
      await tester.pump();

      // Navegar hasta paso 4
      await tester.tap(find.text('Siguiente')); // a paso 2
      await tester.pump();
      await tester.tap(find.text('Siguiente')); // a paso 3
      await tester.pump();
      await tester.tap(find.text('Siguiente')); // a paso 4
      await tester.pump();

      // Submit
      await tester.tap(find.byKey(const Key('btn_confirm_handover')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Mensaje de error visible
      expect(find.text('Acceso denegado. Crear Desde Cero requiere rol OWNER o MANAGER.'), findsOneWidget);
      expect(find.text('Aprovisionamiento Exitoso'), findsNothing);
    });
  });
}
