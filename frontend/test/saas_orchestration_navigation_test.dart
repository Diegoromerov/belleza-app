// frontend/test/saas_orchestration_navigation_test.dart
// NODO-07: Hub Navigation Orchestration Verification Suite
// Under NODO-07-SAAS-HUB-NAVIGATION-ORCHESTRATION-CONTRACT-v1.0 (RATIFIED 🔒)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/screens/saas/saas_navigation_orchestrator.dart';
import 'package:beauty_app/screens/saas/hub_salon_screen.dart';
import 'package:beauty_app/screens/saas/service_offer_assignment_screen.dart';
import 'package:beauty_app/screens/saas/staff_schedule_screen.dart';
import 'package:beauty_app/screens/saas/agenda_operativa_screen.dart';
import 'package:beauty_app/screens/saas/reserva_interna_screen.dart';
import 'package:beauty_app/screens/saas/crear_desde_cero_screen.dart';
import 'package:beauty_app/screens/saas/available_context_selector_screen.dart';
import 'package:beauty_app/models/saas/hub_salon_model.dart';
import 'package:beauty_app/models/saas/saas_agenda_models.dart';
import 'package:beauty_app/models/saas/saas_reserva_interna_models.dart';
import 'package:beauty_app/models/saas/service_offer_assignment_model.dart';
import 'package:beauty_app/models/saas/available_context_model.dart';
import 'package:beauty_app/services/hub_salon_service.dart';
import 'package:beauty_app/services/saas/saas_agenda_service.dart';
import 'package:beauty_app/services/saas/saas_reserva_interna_service.dart';
import 'package:beauty_app/services/saas/service_offer_assignment_service.dart';
import 'package:beauty_app/services/saas/staff_schedule_service.dart';
import 'package:beauty_app/services/active_context_holder.dart';

class MockHubSalonService extends HubSalonService {
  @override
  Future<HubCockpitData> getCockpitData() async {
    return const HubCockpitData(
      summary: HubSummaryResponse(
        ok: true,
        summary: HubSummaryData(
          establishment: HubEstablishment(
            id: 'est-01',
            name: 'Salón Glow Central',
            slug: 'salon-glow-central',
            city: 'Bogotá',
            address: 'Calle 100 # 15-20',
            phone: '3001234567',
            isActive: true,
          ),
          organization: HubOrganization(
            id: 'org-01',
            legalName: 'Glow Beauty SAS',
          ),
          activeUserContext: HubActiveUserContext(
            membershipId: 'mem-owner-01',
            role: 'OWNER',
            relationType: 'PRIMARY',
            status: 'ACTIVE',
          ),
          staffSummary: HubStaffSummary(
            activeMembersCount: 3,
          ),
        ),
      ),
      staff: HubStaffResponse(
        ok: true,
        establishmentId: 'est-01',
        staffCount: 1,
        members: [
          HubStaffMember(
            membershipId: 'mem-owner-01',
            userId: 1,
            userName: 'Carlos Owner',
            userEmail: 'owner@glow.com',
            role: 'OWNER',
            relationType: 'PRIMARY',
            status: 'ACTIVE',
          ),
        ],
      ),
    );
  }
}

class MockSaasAgendaService extends SaasAgendaService {
  int getAgendaCallCount = 0;

  @override
  Future<SaasAgendaProjection> getAgendaProjection({
    required String targetDate,
    String? membershipId,
  }) async {
    getAgendaCallCount++;
    return SaasAgendaProjection(
      establishmentId: 'est-01',
      targetDate: targetDate,
      timezone: 'America/Bogota',
      professionals: [
        const SaasAgendaProfessional(
          membershipId: 'mem-prof-01',
          userId: 101,
          name: 'María Estilista',
          shifts: [
            SaasAgendaShift(
              startTime: '08:00',
              endTime: '17:00',
            ),
          ],
          appointments: [],
          marketplaceBookings: [],
        ),
      ],
    );
  }
}

class MockSaasReservaInternaService extends SaasReservaInternaService {
  @override
  Future<List<ServiceOfferModel>> getServiceOffers() async {
    return [
      const ServiceOfferModel(
        id: 'offer-01',
        establishmentId: 'est-01',
        name: 'Corte y Peinado',
        baseDuration: 45,
        basePrice: 50000.0,
      ),
    ];
  }

  @override
  Future<List<StaffMemberOption>> getStaffMembers() async {
    return [
      const StaffMemberOption(
        membershipId: 'mem-prof-01',
        name: 'María Estilista',
      ),
    ];
  }

  @override
  Future<SaasAvailabilityProjection> getAvailabilityProjection({
    required String serviceOfferId,
    required String targetDate,
    String? membershipId,
    String projectionMode = 'AGGREGATED',
    int stepMinutes = 15,
  }) async {
    return const SaasAvailabilityProjection(
      establishmentId: 'est-01',
      serviceOfferId: 'offer-01',
      targetDate: '2026-09-15',
      serviceDurationMinutes: 45,
      stepMinutes: 15,
      projectionMode: 'AGGREGATED',
      slots: [
        SaasAvailabilitySlot(
          startTime: '09:00',
          endTime: '09:45',
          availableMemberships: ['mem-prof-01'],
        ),
      ],
    );
  }

  @override
  Future<SaasAppointmentDetailModel> createAppointment(CreateAppointmentPayload payload) async {
    return SaasAppointmentDetailModel(
      id: 'appt-new-01',
      tenantId: 1,
      establishmentId: 'est-01',
      serviceOfferId: payload.serviceOfferId,
      membershipId: payload.membershipId,
      clientMode: payload.customerUserId != null ? 'REGISTERED' : 'GUEST',
      customerUserId: payload.customerUserId,
      guestName: payload.guestName,
      guestPhone: payload.guestPhone,
      guestEmail: payload.guestEmail,
      scheduledAt: payload.scheduledAt,
      endTime: '2026-09-15T09:45:00-05:00',
      serviceNameSnapshot: 'Corte y Peinado',
      durationMinutesSnapshot: 45,
      priceSnapshot: 50000.0,
      status: SaasAppointmentStatus.scheduled,
      createdAt: '2026-09-12T00:00:00Z',
      updatedAt: '2026-09-12T00:00:00Z',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ActiveContextHolder contextHolder;
  late MockHubSalonService mockHubService;
  late MockSaasAgendaService mockAgendaService;
  late MockSaasReservaInternaService mockReservaService;
  late ServiceOfferAssignmentService mockOfferService;
  late StaffScheduleService mockScheduleService;

  const sampleContextResponse = AvailableContextResponse(
    resolutionStatus: 'ONE_CONTEXT',
    availableContextsCount: 1,
    availableContexts: [
      AvailableContextItem(
        membershipId: 'mem-owner-01',
        organizationLegalName: 'Glow Beauty SAS',
        establishmentName: 'Salón Glow Central',
        establishmentSlug: 'salon-glow-central',
        establishmentIsActive: true,
        role: 'OWNER',
        relationType: 'PRIMARY',
        tenantName: 'Glow Beauty Group',
      ),
    ],
  );

  setUp(() {
    contextHolder = ActiveContextHolder();
    contextHolder.setActiveMembershipId('mem-owner-01');
    mockHubService = MockHubSalonService();
    mockAgendaService = MockSaasAgendaService();
    mockReservaService = MockSaasReservaInternaService();
    mockOfferService = ServiceOfferAssignmentService(
      apiGet: (path) async {
        if (path == '/api/v1/saas/hub/services') {
          return {
            'ok': true,
            'offers': [
              {
                'id': 'offer-01',
                'name': 'Corte Dama',
                'base_duration': 45,
                'base_price': 50000.0,
                'is_active': true,
                'created_at': '2026-09-12T00:00:00Z',
                'updated_at': '2026-09-12T00:00:00Z',
              }
            ],
          };
        }
        if (path == '/api/v1/saas/hub/staff/eligible') {
          return {
            'ok': true,
            'eligible_staff': [
              {
                'membership_id': 'mem-prof-01',
                'user_name': 'María Estilista',
                'role': 'PROFESSIONAL',
                'relation_type': 'EMPLOYEE',
                'status': 'ACTIVE',
              }
            ],
          };
        }
        return {'ok': true};
      },
    );
    mockScheduleService = StaffScheduleService(
      apiGet: (path) async {
        if (path == '/api/v1/saas/hub/staff/schedules') {
          return {
            'ok': true,
            'out_of_operating_hours_warning': false,
            'staff_schedules': [
              {
                'membership_id': 'mem-prof-01',
                'user_name': 'María Estilista',
                'role': 'PROFESSIONAL',
                'relation_type': 'EMPLOYEE',
                'status': 'ACTIVE',
                'schedule': {
                  'monday': {'is_working': true, 'time_blocks': [{'start': '08:00', 'end': '17:00'}]},
                  'tuesday': {'is_working': true, 'time_blocks': [{'start': '08:00', 'end': '17:00'}]},
                  'wednesday': {'is_working': true, 'time_blocks': [{'start': '08:00', 'end': '17:00'}]},
                  'thursday': {'is_working': true, 'time_blocks': [{'start': '08:00', 'end': '17:00'}]},
                  'friday': {'is_working': true, 'time_blocks': [{'start': '08:00', 'end': '17:00'}]},
                  'saturday': {'is_working': false, 'time_blocks': []},
                  'sunday': {'is_working': false, 'time_blocks': []},
                },
              }
            ],
          };
        }
        return {'ok': true};
      },
    );
  });

  tearDown(() {
    contextHolder.resetForTesting();
  });

  Widget buildOrchestratedApp() {
    return MaterialApp(
      initialRoute: '/saas/hub',
      routes: {
        '/saas/hub': (_) => SaasNavigationOrchestrator(
              hubService: mockHubService,
              agendaService: mockAgendaService,
              reservaService: mockReservaService,
              serviceOfferService: mockOfferService,
              staffScheduleService: mockScheduleService,
              contextLoader: () async => sampleContextResponse,
            ),
      },
    );
  }

  group('NODO-07: Hub Navigation Orchestration Integration Tests (RATIFIED 🔒)', () {
    testWidgets('1. Hub (SCR-05) -> Catálogo (SCR-08) navegación y retorno limpio', (tester) async {
      await tester.pumpWidget(buildOrchestratedApp());
      await tester.pumpAndSettle();

      expect(find.byType(HubSalonScreen), findsOneWidget);
      expect(find.byKey(const Key('btn_modulo_catalogo')), findsOneWidget);

      // Tap botón catálogo
      await tester.tap(find.byKey(const Key('btn_modulo_catalogo')));
      await tester.pumpAndSettle();

      // Verificar que se montó SCR-08
      expect(find.byType(ServiceOfferAssignmentScreen), findsOneWidget);

      // Retorno vía pop
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.byType(HubSalonScreen), findsOneWidget);
    });

    testWidgets('2. Hub (SCR-05) -> Horarios (SCR-09) navegación y retorno limpio', (tester) async {
      await tester.pumpWidget(buildOrchestratedApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_modulo_personal')), findsOneWidget);

      // Tap botón horarios
      await tester.tap(find.byKey(const Key('btn_modulo_personal')));
      await tester.pumpAndSettle();

      // Verificar que se montó SCR-09
      expect(find.byType(StaffScheduleScreen), findsOneWidget);

      // Retorno vía pop
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.byType(HubSalonScreen), findsOneWidget);
    });

    testWidgets('3. Hub (SCR-05) -> Agenda (SCR-10) navegación y retorno limpio', (tester) async {
      await tester.pumpWidget(buildOrchestratedApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_modulo_agenda')), findsOneWidget);

      // Tap botón agenda
      await tester.tap(find.byKey(const Key('btn_modulo_agenda')));
      await tester.pumpAndSettle();

      // Verificar que se montó SCR-10
      expect(find.byType(AgendaOperativaScreen), findsOneWidget);

      // Retorno vía botón físico de back en AppBar
      await tester.tap(find.byKey(const Key('btn_back_agenda')));
      await tester.pumpAndSettle();

      expect(find.byType(HubSalonScreen), findsOneWidget);
    });

    testWidgets('4. Hub -> Crear Desde Cero (SCR-06) navegación modular', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                key: const Key('btn_test_cdc'),
                onPressed: () => SaasNavigationOrchestrator.navigateToCreateFromScratch(context),
                child: const Text('Crear Desde Cero'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_test_cdc')));
      await tester.pumpAndSettle();

      expect(find.byType(CrearDesdeCeroWizardScreen), findsOneWidget);
    });

    testWidgets('5. Hub (SCR-05) -> Selector de Contexto (SCR-04) vía Branch Switcher', (tester) async {
      await tester.pumpWidget(buildOrchestratedApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_cambiar_sede')), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_cambiar_sede')));
      await tester.pumpAndSettle();

      expect(find.byType(AvailableContextSelectorScreen), findsOneWidget);
    });

    testWidgets('6. SCR-10 -> SCR-11 Transición hacia Reserva Interna', (tester) async {
      await tester.pumpWidget(buildOrchestratedApp());
      await tester.pumpAndSettle();

      // Entrar a SCR-10
      await tester.tap(find.byKey(const Key('btn_modulo_agenda')));
      await tester.pumpAndSettle();

      expect(find.byType(AgendaOperativaScreen), findsOneWidget);
      expect(find.byKey(const Key('btn_nueva_cita')), findsOneWidget);

      // Tap Nueva Cita -> Dispara transición a SCR-11
      await tester.tap(find.byKey(const Key('btn_nueva_cita')));
      await tester.pumpAndSettle();

      expect(find.byType(ReservaInternaScreen), findsOneWidget);
    });

    testWidgets('7. SCR-11 Éxito -> Navigator.pop(true) -> Retorno a SCR-10 y ejecución de DEMAND REFRESH', (tester) async {
      mockAgendaService.getAgendaCallCount = 0;

      await tester.pumpWidget(buildOrchestratedApp());
      await tester.pumpAndSettle();

      // Navegar a SCR-10
      await tester.tap(find.byKey(const Key('btn_modulo_agenda')));
      await tester.pumpAndSettle();

      expect(find.byType(AgendaOperativaScreen), findsOneWidget);
      expect(mockAgendaService.getAgendaCallCount, equals(1)); // Carga inicial

      // Navegar a SCR-11
      await tester.tap(find.byKey(const Key('btn_nueva_cita')));
      await tester.pumpAndSettle();

      expect(find.byType(ReservaInternaScreen), findsOneWidget);

      // Simular retorno con éxito (true)
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop(true);
      await tester.pumpAndSettle();

      // Vuelve a SCR-10 y dispara _loadAgenda() (Demand Refresh)
      expect(find.byType(AgendaOperativaScreen), findsOneWidget);
      expect(mockAgendaService.getAgendaCallCount, equals(2)); // Demand Refresh ejecutado
    });

    testWidgets('8. SCR-11 Cancelar -> Navigator.pop(false) -> Retorno a SCR-10 SIN refresh derivado de éxito', (tester) async {
      mockAgendaService.getAgendaCallCount = 0;

      await tester.pumpWidget(buildOrchestratedApp());
      await tester.pumpAndSettle();

      // Navegar a SCR-10
      await tester.tap(find.byKey(const Key('btn_modulo_agenda')));
      await tester.pumpAndSettle();

      expect(find.byType(AgendaOperativaScreen), findsOneWidget);
      expect(mockAgendaService.getAgendaCallCount, equals(1)); // Carga inicial

      // Navegar a SCR-11
      await tester.tap(find.byKey(const Key('btn_nueva_cita')));
      await tester.pumpAndSettle();

      expect(find.byType(ReservaInternaScreen), findsOneWidget);

      // Tap botón de retorno/cancelar en AppBar de SCR-11
      await tester.tap(find.byKey(const Key('btn_back_reserva')));
      await tester.pumpAndSettle();

      // Retorna a SCR-10 sin recarga adicional
      expect(find.byType(AgendaOperativaScreen), findsOneWidget);
      expect(mockAgendaService.getAgendaCallCount, equals(1)); // SIN refresh derivado de éxito
    });

    testWidgets('9. Invarianza de Active Context durante toda la navegación profunda (SCR-05 -> SCR-10 -> SCR-11)', (tester) async {
      expect(contextHolder.activeMembershipId, equals('mem-owner-01'));

      await tester.pumpWidget(buildOrchestratedApp());
      await tester.pumpAndSettle();

      expect(contextHolder.activeMembershipId, equals('mem-owner-01'));

      // Navegar a SCR-10
      await tester.tap(find.byKey(const Key('btn_modulo_agenda')));
      await tester.pumpAndSettle();

      expect(contextHolder.activeMembershipId, equals('mem-owner-01'));

      // Navegar a SCR-11
      await tester.tap(find.byKey(const Key('btn_nueva_cita')));
      await tester.pumpAndSettle();

      expect(contextHolder.activeMembershipId, equals('mem-owner-01'));

      // Retornar a SCR-10 y a Hub
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(contextHolder.activeMembershipId, equals('mem-owner-01'));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(contextHolder.activeMembershipId, equals('mem-owner-01'));
    });

    testWidgets('10. Missing Active Context -> Renderiza vista de guarda y recupera vía SCR-04', (tester) async {
      contextHolder.clear();
      expect(contextHolder.activeMembershipId, isNull);

      await tester.pumpWidget(buildOrchestratedApp());
      await tester.pumpAndSettle();

      // Hub presenta vista missing
      expect(find.text('Contexto de Salón No Seleccionado'), findsOneWidget);
      expect(find.byKey(const Key('btn_seleccionar_contexto_missing')), findsOneWidget);

      // Tap botón de recuperación
      await tester.tap(find.byKey(const Key('btn_seleccionar_contexto_missing')));
      await tester.pumpAndSettle();

      // Redirige a SCR-04
      expect(find.byType(AvailableContextSelectorScreen), findsOneWidget);
    });

    testWidgets('11. Production-entry integration: /saas/hub monta SaasNavigationOrchestrator y conecta callbacks reales', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/home',
          routes: {
            '/home': (_) => const Scaffold(body: Text('Home Screen')),
            '/saas/hub': (_) => const SaasNavigationOrchestrator(),
          },
        ),
      );
      await tester.pumpAndSettle();

      final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
      navigatorState.pushNamed('/saas/hub');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verifica que /saas/hub monta el orquestador y la pantalla Hub
      expect(find.byType(SaasNavigationOrchestrator), findsOneWidget);
      expect(find.byType(HubSalonScreen), findsOneWidget);

      // Verifica que los callbacks están conectados (no son null)
      final hubWidget = tester.widget<HubSalonScreen>(find.byType(HubSalonScreen));
      expect(hubWidget.onNavigateToCatalog, isNotNull);
      expect(hubWidget.onNavigateToStaffSchedules, isNotNull);
      expect(hubWidget.onNavigateToAgenda, isNotNull);
      expect(hubWidget.onNavigateToContextSelector, isNotNull);
    });
  });
}
