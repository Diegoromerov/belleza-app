// frontend/test/saas_reserva_interna_test.dart
// NODO-07 / SCR-11: Reserva Interna Runtime Tests

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas/saas_agenda_models.dart';
import 'package:beauty_app/models/saas/saas_reserva_interna_models.dart';
import 'package:beauty_app/models/saas/service_offer_assignment_model.dart';
import 'package:beauty_app/services/saas/saas_reserva_interna_service.dart';
import 'package:beauty_app/screens/saas/reserva_interna_screen.dart';

class MockSaasReservaInternaService extends SaasReservaInternaService {
  List<ServiceOfferModel> mockOffers = [];
  List<StaffMemberOption> mockStaff = [];
  SaasAvailabilityProjection? mockProjection;
  SaasAppointmentDetailModel? mockCreatedDetail;

  bool shouldFailOffers = false;
  bool shouldFailStaff = false;
  bool shouldFailProjection = false;
  bool shouldFailCreate409 = false;
  bool shouldFailCreateGeneric = false;

  int getProjectionCallCount = 0;
  String? lastProjectionServiceOfferId;
  String? lastProjectionTargetDate;
  String? lastProjectionMembershipId;
  String? lastProjectionMode;

  CreateAppointmentPayload? lastCreatedPayload;

  @override
  Future<List<ServiceOfferModel>> getServiceOffers() async {
    if (shouldFailOffers) {
      throw SaasReservaInternaException(
        message: 'Error al consultar catálogo de servicios.',
        code: 'FETCH_SERVICES_FAILED',
        statusCode: 500,
      );
    }
    return mockOffers;
  }

  @override
  Future<List<StaffMemberOption>> getStaffMembers() async {
    if (shouldFailStaff) {
      throw SaasReservaInternaException(
        message: 'Error al consultar personal de la sede.',
        code: 'FETCH_STAFF_FAILED',
        statusCode: 500,
      );
    }
    return mockStaff;
  }

  @override
  Future<SaasAvailabilityProjection> getAvailabilityProjection({
    required String serviceOfferId,
    required String targetDate,
    String? membershipId,
    String projectionMode = 'AGGREGATED',
    int stepMinutes = 15,
  }) async {
    getProjectionCallCount++;
    lastProjectionServiceOfferId = serviceOfferId;
    lastProjectionTargetDate = targetDate;
    lastProjectionMembershipId = membershipId;
    lastProjectionMode = projectionMode;

    if (shouldFailProjection) {
      throw SaasReservaInternaException(
        message: 'Error al consultar disponibilidad.',
        code: 'FETCH_AVAILABILITY_FAILED',
        statusCode: 500,
      );
    }

    if (mockProjection != null) {
      return mockProjection!;
    }

    return SaasAvailabilityProjection(
      establishmentId: 'est-01',
      serviceOfferId: serviceOfferId,
      targetDate: targetDate,
      serviceDurationMinutes: 45,
      stepMinutes: stepMinutes,
      projectionMode: projectionMode,
      slots: const [],
    );
  }

  @override
  Future<SaasAppointmentDetailModel> createAppointment(CreateAppointmentPayload payload) async {
    lastCreatedPayload = payload;

    if (shouldFailCreate409) {
      throw SaasReservaInternaException(
        message: 'El horario seleccionado acaba de ser ocupado por otra reserva.',
        code: 'APPOINTMENT_OCCUPANCY_COLLISION',
        statusCode: 409,
      );
    }

    if (shouldFailCreateGeneric) {
      throw SaasReservaInternaException(
        message: 'Error inesperado al crear la cita.',
        code: 'CREATE_APPOINTMENT_FAILED',
        statusCode: 500,
      );
    }

    if (mockCreatedDetail != null) {
      return mockCreatedDetail!;
    }

    return SaasAppointmentDetailModel(
      id: 'appt-uuid-auto-1',
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
      serviceNameSnapshot: 'Servicio Creado',
      durationMinutesSnapshot: 45,
      priceSnapshot: 40000.0,
      status: SaasAppointmentStatus.scheduled,
      createdAt: '2026-09-12T10:00:00Z',
      updatedAt: '2026-09-12T10:00:00Z',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockSaasReservaInternaService mockService;

  final sampleOffers = [
    const ServiceOfferModel(
      id: 'offer-01',
      establishmentId: 'est-01',
      name: 'Corte Dama',
      baseDuration: 45,
      basePrice: 45000.0,
    ),
    const ServiceOfferModel(
      id: 'offer-02',
      establishmentId: 'est-01',
      name: 'Colorimetría / Balayage',
      baseDuration: 120,
      basePrice: 150000.0,
    ),
  ];

  final sampleStaff = [
    const StaffMemberOption(membershipId: 'mem-01', name: 'Ana Gómez'),
    const StaffMemberOption(membershipId: 'mem-02', name: 'Carlos Ruiz'),
  ];

  const sampleProjectionAggregated = SaasAvailabilityProjection(
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
        availableMemberships: ['mem-01', 'mem-02'],
      ),
      SaasAvailabilitySlot(
        startTime: '10:00',
        endTime: '10:45',
        availableMemberships: ['mem-01'],
      ),
    ],
  );

  setUp(() {
    mockService = MockSaasReservaInternaService();
    mockService.mockOffers = List.from(sampleOffers);
    mockService.mockStaff = List.from(sampleStaff);
    mockService.mockProjection = sampleProjectionAggregated;
  });

  Widget buildTestableScreen({
    String? initialDate,
    String? preselectedMembershipId,
    String? userRole,
    VoidCallback? onAppointmentCreated,
    VoidCallback? onCancel,
  }) {
    return MaterialApp(
      home: ReservaInternaScreen(
        service: mockService,
        initialDate: initialDate,
        preselectedMembershipId: preselectedMembershipId,
        userRole: userRole,
        onAppointmentCreated: onAppointmentCreated,
        onCancel: onCancel,
      ),
    );
  }

  void setupViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('SCR-11 Reserva Interna Widget Tests', () {
    testWidgets('1. Render inicial hereda fecha (DEC-S11-003) y carga catálogo', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(buildTestableScreen(
        initialDate: '2026-09-15',
        userRole: 'OWNER',
      ));
      await tester.pumpAndSettle();

      expect(find.text('SCR-11 — Reserva Interna'), findsOneWidget);
      expect(find.text('2026-09-15'), findsWidgets);
      expect(find.text('Corte Dama (45 min - \$45000)'), findsOneWidget);
      expect(find.text('3. Horarios Disponibles'), findsOneWidget);
      expect(find.text('09:00 - 09:45'), findsOneWidget);
      expect(find.text('10:00 - 10:45'), findsOneWidget);
    });

    testWidgets('2. PROFESSIONAL queda confinado a su propia agenda (DEC-S11-001 & DEC-S11-005)', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(buildTestableScreen(
        initialDate: '2026-09-15',
        preselectedMembershipId: 'mem-01',
        userRole: 'PROFESSIONAL',
      ));
      await tester.pumpAndSettle();

      // Debe consultar TARGETED directamente
      expect(mockService.lastProjectionMode, 'TARGETED');
      expect(mockService.lastProjectionMembershipId, 'mem-01');
      // No debe existir opción de "Todos los profesionales (Aggregated)"
      expect(find.text('Todos los profesionales (Aggregated)'), findsNothing);
      expect(find.text('Agenda Confinada: Ana Gómez'), findsOneWidget);
    });

    testWidgets('3. DEC-S11-004: Slot multi-profesional en AGGREGATED exige selección explícita', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(buildTestableScreen(
        initialDate: '2026-09-15',
        userRole: 'MANAGER',
      ));
      await tester.pumpAndSettle();

      // Tap slot 09:00 (tiene mem-01 y mem-02)
      final slot09 = find.text('09:00 - 09:45');
      expect(slot09, findsOneWidget);
      await tester.tap(slot09);
      await tester.pumpAndSettle();

      // Aparece selector explícito de profesional
      expect(find.text('4. Seleccionar Profesional para este Horario (DEC-S11-004):'), findsOneWidget);
      expect(find.byKey(const Key('chip_explicit_staff_mem-01')), findsOneWidget);
      expect(find.byKey(const Key('chip_explicit_staff_mem-02')), findsOneWidget);

      // Botón debe estar deshabilitado hasta seleccionar profesional y llenar cliente
      final confirmBtn = tester.widget<ElevatedButton>(find.byKey(const Key('btn_confirm_create_appointment')));
      expect(confirmBtn.onPressed, isNull);

      // Selecciona Carlos Ruiz (mem-02)
      await tester.tap(find.byKey(const Key('chip_explicit_staff_mem-02')));
      await tester.pumpAndSettle();

      // Llenar datos de cliente
      await tester.enterText(find.byKey(const Key('input_guest_name')), 'Sofía');
      await tester.enterText(find.byKey(const Key('input_guest_phone')), '3001234567');
      await tester.pumpAndSettle();

      // Ahora el botón se habilita
      final enabledBtn = tester.widget<ElevatedButton>(find.byKey(const Key('btn_confirm_create_appointment')));
      expect(enabledBtn.onPressed, isNotNull);
    });

    testWidgets('4. DEC-S11-006: Slot con único profesional en AGGREGATED exige selección explícita y no autoasigna', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(buildTestableScreen(
        initialDate: '2026-09-15',
        userRole: 'RECEPTIONIST',
      ));
      await tester.pumpAndSettle();

      // Tap slot 10:00 (solo tiene mem-01: Ana Gómez)
      final slot10 = find.text('10:00 - 10:45');
      await tester.tap(slot10);
      await tester.pumpAndSettle();

      // DEC-S11-006: No se autoasigna. Debe aparecer el selector con el chip solitario
      expect(find.text('4. Seleccionar Profesional para este Horario (DEC-S11-004):'), findsOneWidget);
      expect(find.byKey(const Key('chip_explicit_staff_mem-01')), findsOneWidget);

      // Llenar datos cliente antes de seleccionar profesional
      await tester.enterText(find.byKey(const Key('input_guest_name')), 'Lucía');
      await tester.enterText(find.byKey(const Key('input_guest_phone')), '3001234567');
      await tester.pumpAndSettle();

      // El botón debe seguir DESHABILITADO porque no se ha hecho tap en el profesional
      var confirmBtn = tester.widget<ElevatedButton>(find.byKey(const Key('btn_confirm_create_appointment')));
      expect(confirmBtn.onPressed, isNull);

      // Tap explícito en Ana Gómez (mem-01)
      await tester.tap(find.byKey(const Key('chip_explicit_staff_mem-01')));
      await tester.pumpAndSettle();

      // Ahora sí se habilita
      confirmBtn = tester.widget<ElevatedButton>(find.byKey(const Key('btn_confirm_create_appointment')));
      expect(confirmBtn.onPressed, isNotNull);
    });

    testWidgets('5. DEC-S11-002: Modo Invitado (GUEST) por defecto y validación de campos', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(buildTestableScreen(
        initialDate: '2026-09-15',
        userRole: 'OWNER',
      ));
      await tester.pumpAndSettle();

      // Por defecto pestaña Invitado activa
      expect(find.byKey(const Key('input_guest_name')), findsOneWidget);
      expect(find.byKey(const Key('input_guest_phone')), findsOneWidget);
      expect(find.byKey(const Key('input_customer_user_id')), findsNothing);

      // Cambiar a Registrado
      await tester.tap(find.byKey(const Key('tab_client_registered')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('input_guest_name')), findsNothing);
      expect(find.byKey(const Key('input_customer_user_id')), findsOneWidget);
    });

    testWidgets('6. Creación exitosa (201) de cita GUEST con XOR estricto', (tester) async {
      setupViewport(tester);
      bool createdCallbackFired = false;

      await tester.pumpWidget(buildTestableScreen(
        initialDate: '2026-09-15',
        userRole: 'OWNER',
        onAppointmentCreated: () {
          createdCallbackFired = true;
        },
      ));
      await tester.pumpAndSettle();

      // Seleccionar slot 10:00
      await tester.tap(find.text('10:00 - 10:45'));
      await tester.pumpAndSettle();

      // Seleccionar explícitamente profesional (DEC-S11-006)
      await tester.tap(find.byKey(const Key('chip_explicit_staff_mem-01')));
      await tester.pumpAndSettle();

      // Llenar datos de invitado
      await tester.enterText(find.byKey(const Key('input_guest_name')), 'Mariana López');
      await tester.enterText(find.byKey(const Key('input_guest_phone')), '3151234567');
      await tester.enterText(find.byKey(const Key('input_guest_email')), 'mariana@test.com');
      await tester.pumpAndSettle();

      // Confirmar cita
      final confirmBtn = find.byKey(const Key('btn_confirm_create_appointment'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(mockService.lastCreatedPayload, isNotNull);
      expect(mockService.lastCreatedPayload!.serviceOfferId, 'offer-01');
      expect(mockService.lastCreatedPayload!.membershipId, 'mem-01');
      expect(mockService.lastCreatedPayload!.guestName, 'Mariana López');
      expect(mockService.lastCreatedPayload!.guestPhone, '3151234567');
      expect(mockService.lastCreatedPayload!.guestEmail, 'mariana@test.com');
      expect(mockService.lastCreatedPayload!.customerUserId, isNull);
      expect(createdCallbackFired, isTrue);
    });

    testWidgets('7. Manejo de colisión de concurrencia 409 y recarga automática de disponibilidad', (tester) async {
      setupViewport(tester);
      mockService.shouldFailCreate409 = true;

      await tester.pumpWidget(buildTestableScreen(
        initialDate: '2026-09-15',
        userRole: 'OWNER',
      ));
      await tester.pumpAndSettle();

      final initialProjectionCalls = mockService.getProjectionCallCount;

      // Seleccionar slot 10:00
      await tester.tap(find.text('10:00 - 10:45'));
      await tester.pumpAndSettle();

      // Seleccionar explícitamente profesional (DEC-S11-006)
      await tester.tap(find.byKey(const Key('chip_explicit_staff_mem-01')));
      await tester.pumpAndSettle();

      // Llenar datos
      await tester.enterText(find.byKey(const Key('input_guest_name')), 'Mariana López');
      await tester.enterText(find.byKey(const Key('input_guest_phone')), '3151234567');
      await tester.pumpAndSettle();

      // Confirmar
      final confirmBtn = find.byKey(const Key('btn_confirm_create_appointment'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Banner de error de colisión 409
      expect(find.textContaining('Conflicto de concurrencia'), findsOneWidget);
      // Debe haber vuelto a consultar disponibilidad (auto-reload)
      expect(mockService.getProjectionCallCount, initialProjectionCalls + 1);
    });

    testWidgets('8. Estado vacío cuando no hay slots disponibles', (tester) async {
      setupViewport(tester);
      mockService.mockProjection = const SaasAvailabilityProjection(
        establishmentId: 'est-01',
        serviceOfferId: 'offer-01',
        targetDate: '2026-09-15',
        serviceDurationMinutes: 45,
        stepMinutes: 15,
        projectionMode: 'AGGREGATED',
        slots: [],
      );

      await tester.pumpWidget(buildTestableScreen(
        initialDate: '2026-09-15',
        userRole: 'OWNER',
      ));
      await tester.pumpAndSettle();

      expect(find.text('No hay disponibilidad para los criterios seleccionados.'), findsOneWidget);
    });

    testWidgets('9. Cambio de fecha solicita nueva proyección', (tester) async {
      setupViewport(tester);
      await tester.pumpWidget(buildTestableScreen(
        initialDate: '2026-09-15',
        userRole: 'OWNER',
      ));
      await tester.pumpAndSettle();

      expect(mockService.lastProjectionTargetDate, '2026-09-15');

      // Tap botón día siguiente
      final nextDayBtn = find.byKey(const Key('btn_next_date_reserva'));
      await tester.tap(nextDayBtn);
      await tester.pumpAndSettle();

      expect(mockService.lastProjectionTargetDate, '2026-09-16');
      expect(find.text('2026-09-16'), findsWidgets);
    });

    testWidgets('10. Botón cancelar dispara onCancel callback', (tester) async {
      setupViewport(tester);
      bool cancelFired = false;

      await tester.pumpWidget(buildTestableScreen(
        initialDate: '2026-09-15',
        userRole: 'OWNER',
        onCancel: () {
          cancelFired = true;
        },
      ));
      await tester.pumpAndSettle();

      final cancelBtn = find.byKey(const Key('btn_cancel_reserva'));
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(cancelFired, isTrue);
    });
  });
}
