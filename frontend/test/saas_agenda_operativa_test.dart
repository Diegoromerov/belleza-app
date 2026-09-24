// frontend/test/saas_agenda_operativa_test.dart
// NODO-07 / SCR-10: Agenda Operativa Runtime Tests

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas/saas_agenda_models.dart';
import 'package:beauty_app/services/saas/saas_agenda_service.dart';
import 'package:beauty_app/screens/saas/agenda_operativa_screen.dart';
import 'package:beauty_app/services/active_context_holder.dart';

class MockSaasAgendaService extends SaasAgendaService {
  SaasAgendaProjection? mockProjection;
  SaasAppointmentDetailModel? mockDetail;
  bool shouldFailAgenda = false;
  bool shouldFailStatus = false;
  bool shouldFailDetail = false;

  String? lastTargetDate;
  String? lastMembershipIdFilter;
  String? lastUpdatedApptId;
  String? lastUpdatedStatus;
  String? lastCancellationReason;
  int getAgendaCallCount = 0;

  @override
  Future<SaasAgendaProjection> getAgendaProjection({
    required String targetDate,
    String? membershipId,
  }) async {
    getAgendaCallCount++;
    lastTargetDate = targetDate;
    lastMembershipIdFilter = membershipId;

    if (shouldFailAgenda) {
      throw SaasAgendaException(
        message: 'Error de servidor al consultar agenda.',
        code: 'INTERNAL_SERVER_ERROR',
        statusCode: 500,
      );
    }

    if (mockProjection != null) {
      return mockProjection!;
    }

    return SaasAgendaProjection(
      establishmentId: 'est-uuid-01',
      targetDate: targetDate,
      timezone: 'America/Bogota',
      professionals: [],
    );
  }

  @override
  Future<SaasAppointmentDetailModel> getAppointmentDetail(String appointmentId) async {
    if (shouldFailDetail) {
      throw SaasAgendaException(
        message: 'Error al consultar detalle.',
        code: 'FETCH_DETAIL_FAILED',
        statusCode: 404,
      );
    }
    if (mockDetail != null && mockDetail!.id == appointmentId) {
      return mockDetail!;
    }
    return SaasAppointmentDetailModel(
      id: appointmentId,
      tenantId: 1,
      establishmentId: 'est-uuid-01',
      serviceOfferId: 'offer-uuid-01',
      membershipId: 'mem-uuid-01',
      clientMode: 'GUEST',
      guestName: 'Laura Invitada',
      guestPhone: '3001234567',
      guestEmail: 'laura@invitada.com',
      scheduledAt: '2026-09-15T09:00:00-05:00',
      endTime: '2026-09-15T10:00:00-05:00',
      serviceNameSnapshot: 'Corte Dama Snapshot',
      durationMinutesSnapshot: 60,
      priceSnapshot: 45000.0,
      status: SaasAppointmentStatus.scheduled,
      createdAt: '2026-09-12T10:00:00Z',
      updatedAt: '2026-09-12T10:00:00Z',
    );
  }

  @override
  Future<SaasAppointmentDetailModel> updateAppointmentStatus({
    required String appointmentId,
    required String targetStatus,
    String? cancellationReason,
  }) async {
    if (shouldFailStatus) {
      throw SaasAgendaException(
        message: 'Transición inválida o no permitida.',
        code: 'INVALID_STATE_TRANSITION',
        statusCode: 422,
      );
    }
    lastUpdatedApptId = appointmentId;
    lastUpdatedStatus = targetStatus;
    lastCancellationReason = cancellationReason;

    return SaasAppointmentDetailModel(
      id: appointmentId,
      tenantId: 1,
      establishmentId: 'est-uuid-01',
      serviceOfferId: 'offer-uuid-01',
      membershipId: 'mem-uuid-01',
      clientMode: 'GUEST',
      guestName: 'Laura Invitada',
      guestPhone: '3001234567',
      scheduledAt: '2026-09-15T09:00:00-05:00',
      endTime: '2026-09-15T10:00:00-05:00',
      serviceNameSnapshot: 'Corte Dama Snapshot',
      durationMinutesSnapshot: 60,
      priceSnapshot: 45000.0,
      status: SaasAppointmentStatus.fromString(targetStatus),
      cancellationReason: cancellationReason,
      createdAt: '2026-09-12T10:00:00Z',
      updatedAt: '2026-09-12T10:30:00Z',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSaasAgendaService mockService;

  setUp(() {
    ActiveContextHolder().resetForTesting();
    ActiveContextHolder().setActiveMembershipId('mem-uuid-owner');
    mockService = MockSaasAgendaService();
  });

  tearDown(() {
    ActiveContextHolder().resetForTesting();
  });

  SaasAgendaProjection buildSampleProjection() {
    return const SaasAgendaProjection(
      establishmentId: 'est-uuid-01',
      targetDate: '2026-09-15',
      timezone: 'America/Bogota',
      professionals: [
        SaasAgendaProfessional(
          membershipId: 'mem-prof-01',
          userId: 101,
          name: 'María Pérez',
          shifts: [
            SaasAgendaShift(startTime: '08:00', endTime: '12:00'),
            SaasAgendaShift(startTime: '14:00', endTime: '18:00'),
          ],
          appointments: [
            SaasAgendaAppointment(
              id: 'appt-01',
              startTime: '09:00',
              endTime: '10:00',
              serviceName: 'Corte de Cabello Dama',
              clientName: 'Ana Gómez',
              status: SaasAppointmentStatus.scheduled,
            ),
            SaasAgendaAppointment(
              id: 'appt-02',
              startTime: '10:30',
              endTime: '11:30',
              serviceName: 'Tinte Completo',
              clientName: 'Laura Invitada',
              status: SaasAppointmentStatus.inService,
            ),
            SaasAgendaAppointment(
              id: 'appt-03',
              startTime: '16:00',
              endTime: '17:00',
              serviceName: 'Manicure Express',
              clientName: 'Carlos Gómez',
              status: SaasAppointmentStatus.completed,
            ),
          ],
          marketplaceBookings: [
            SaasAgendaMarketplaceBooking(
              id: 501,
              startTime: '15:00',
              endTime: '16:00',
              status: 'CONFIRMADA',
            ),
          ],
        ),
        SaasAgendaProfessional(
          membershipId: 'mem-prof-02',
          userId: 102,
          name: 'Carlos Barbero',
          shifts: [
            SaasAgendaShift(startTime: '10:00', endTime: '19:00'),
          ],
          appointments: [],
          marketplaceBookings: [],
        ),
      ],
    );
  }

  Widget createTestWidget({
    String? initialDate,
    String? userRole,
    FutureOr<bool?> Function()? onNavigateToCreateAppointment,
    VoidCallback? onNavigateBack,
  }) {
    return MaterialApp(
      home: AgendaOperativaScreen(
        agendaService: mockService,
        initialDate: initialDate ?? '2026-09-15',
        userRole: userRole,
        onNavigateToCreateAppointment: onNavigateToCreateAppointment,
        onNavigateBack: onNavigateBack,
      ),
    );
  }

  group('NODO-07 / SCR-10: Agenda Operativa Runtime Suite', () {
    testWidgets('1. Render inicial y verificación de Header y controles', (tester) async {
      mockService.mockProjection = buildSampleProjection();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Agenda Operativa'), findsOneWidget);
      expect(find.byKey(const Key('btn_nueva_cita')), findsOneWidget);
      expect(find.byKey(const Key('date_navigation_bar')), findsOneWidget);
      expect(find.text('2026-09-15'), findsOneWidget);
    });

    testWidgets('2. Carga correcta de agenda, profesionales, shifts y appointments', (tester) async {
      mockService.mockProjection = buildSampleProjection();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Profesionales
      expect(find.text('María Pérez'), findsNWidgets(2)); // Chip + Card
      expect(find.text('Carlos Barbero'), findsNWidgets(2)); // Chip + Card

      // Turnos
      expect(find.text('08:00 - 12:00'), findsOneWidget);
      expect(find.text('14:00 - 18:00'), findsOneWidget);
      expect(find.text('10:00 - 19:00'), findsOneWidget);

      // Citas
      expect(find.text('Corte de Cabello Dama'), findsOneWidget);
      expect(find.text('Ana Gómez'), findsOneWidget);
      expect(find.text('Tinte Completo'), findsOneWidget);
      expect(find.text('Manicure Express'), findsOneWidget);

      // Badges de Estado
      expect(find.text('Agendada'), findsOneWidget);
      expect(find.text('En Atención'), findsOneWidget);
      expect(find.text('Finalizada'), findsOneWidget);
    });

    testWidgets('3. Renderizado de bloqueos Marketplace B2C', (tester) async {
      mockService.mockProjection = buildSampleProjection();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('marketplace_tile_501')), findsOneWidget);
      expect(find.text('🔒 Ocupado (Reserva Marketplace B2C)'), findsOneWidget);
      expect(find.text('15:00 - 16:00'), findsOneWidget);
    });

    testWidgets('4. Navegación de fecha (Día anterior y Día siguiente)', (tester) async {
      mockService.mockProjection = buildSampleProjection();

      await tester.pumpWidget(createTestWidget(initialDate: '2026-09-15'));
      await tester.pumpAndSettle();

      expect(find.text('2026-09-15'), findsOneWidget);

      // Siguiente día
      await tester.tap(find.byKey(const Key('btn_next_day')));
      await tester.pumpAndSettle();

      expect(mockService.lastTargetDate, '2026-09-16');
      expect(find.text('2026-09-16'), findsOneWidget);

      // Anterior día
      await tester.tap(find.byKey(const Key('btn_prev_day')));
      await tester.pumpAndSettle();

      expect(mockService.lastTargetDate, '2026-09-15');
      expect(find.text('2026-09-15'), findsOneWidget);
    });

    testWidgets('5. Filtro de profesional para OWNER / MANAGER / RECEPTIONIST', (tester) async {
      mockService.mockProjection = buildSampleProjection();

      await tester.pumpWidget(createTestWidget(userRole: 'OWNER'));
      await tester.pumpAndSettle();

      // Barra de filtro visible
      expect(find.byKey(const Key('staff_filter_bar')), findsOneWidget);
      expect(find.byKey(const Key('chip_staff_all')), findsOneWidget);
      expect(find.byKey(const Key('chip_staff_mem-prof-01')), findsOneWidget);

      // Filtrar por María Pérez
      await tester.tap(find.byKey(const Key('chip_staff_mem-prof-01')));
      await tester.pumpAndSettle();

      expect(mockService.lastMembershipIdFilter, 'mem-prof-01');

      // Volver a Todos
      await tester.tap(find.byKey(const Key('chip_staff_all')));
      await tester.pumpAndSettle();

      expect(mockService.lastMembershipIdFilter, isNull);
    });

    testWidgets('6. Confinamiento RBAC para rol PROFESSIONAL (filtro oculto)', (tester) async {
      mockService.mockProjection = buildSampleProjection();

      await tester.pumpWidget(createTestWidget(userRole: 'PROFESSIONAL'));
      await tester.pumpAndSettle();

      // Selector de profesional debe estar oculto
      expect(find.byKey(const Key('staff_filter_bar')), findsNothing);
      expect(find.byKey(const Key('chip_staff_all')), findsNothing);
    });

    testWidgets('7. Transición de estado permitida y Demand Refresh', (tester) async {
      mockService.mockProjection = buildSampleProjection();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final initialCallCount = mockService.getAgendaCallCount;

      // Abrir menú de acciones de appt-01 (SCHEDULED)
      await tester.tap(find.byKey(const Key('btn_actions_appt-01')));
      await tester.pumpAndSettle();

      // Debe mostrar opciones de transición válidas desde SCHEDULED
      expect(find.text('Confirmada'), findsWidgets);
      expect(find.text('En Recepción'), findsOneWidget);
      expect(find.text('Cancelada'), findsOneWidget);
      expect(find.text('No Asistió'), findsOneWidget);

      // Seleccionar Confirmada del menú
      await tester.tap(find.text('Confirmada').last);
      await tester.pumpAndSettle();

      expect(mockService.lastUpdatedApptId, 'appt-01');
      expect(mockService.lastUpdatedStatus, 'CONFIRMED');
      // Debe haber ejecutado Demand Refresh
      expect(mockService.getAgendaCallCount, greaterThan(initialCallCount));
    });

    testWidgets('8. Cancelación desde IN_SERVICE requiere cancellation_reason', (tester) async {
      mockService.mockProjection = buildSampleProjection();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // appt-02 está IN_SERVICE
      await tester.tap(find.byKey(const Key('btn_actions_appt-02')));
      await tester.pumpAndSettle();

      expect(find.text('Finalizada'), findsWidgets);
      expect(find.text('Cancelada'), findsOneWidget);

      // Seleccionar Cancelada
      await tester.tap(find.text('Cancelada'));
      await tester.pumpAndSettle();

      // Diálogo de motivo obligatorio debe aparecer
      expect(find.byKey(const Key('dialog_cancellation_reason')), findsOneWidget);
      expect(find.text('Motivo de Cancelación'), findsOneWidget);

      // Escribir motivo y confirmar
      await tester.enterText(find.byKey(const Key('input_cancellation_reason')), 'Cliente tuvo emergencia familiar');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_confirm_cancel_reason')));
      await tester.pumpAndSettle();

      expect(mockService.lastUpdatedApptId, 'appt-02');
      expect(mockService.lastUpdatedStatus, 'CANCELLED');
      expect(mockService.lastCancellationReason, 'Cliente tuvo emergencia familiar');
    });

    testWidgets('9. Estados terminales no exponen botón de transiciones', (tester) async {
      mockService.mockProjection = buildSampleProjection();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // appt-03 está COMPLETED (Terminal) -> no debe tener botón de acciones
      expect(find.byKey(const Key('btn_actions_appt-03')), findsNothing);
    });

    testWidgets('10. Detalle secundario modal con guest_phone y snapshots', (tester) async {
      mockService.mockProjection = buildSampleProjection();
      mockService.mockDetail = const SaasAppointmentDetailModel(
        id: 'appt-02',
        tenantId: 1,
        establishmentId: 'est-uuid-01',
        serviceOfferId: 'offer-uuid-01',
        membershipId: 'mem-prof-01',
        clientMode: 'GUEST',
        guestName: 'Laura Invitada',
        guestPhone: '3009876543',
        guestEmail: 'laura@invitada.com',
        scheduledAt: '2026-09-15T10:30:00-05:00',
        endTime: '2026-09-15T11:30:00-05:00',
        serviceNameSnapshot: 'Tinte Completo Especial',
        durationMinutesSnapshot: 60,
        priceSnapshot: 120000.0,
        status: SaasAppointmentStatus.inService,
        createdAt: '2026-09-12T10:00:00Z',
        updatedAt: '2026-09-12T10:00:00Z',
      );

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap sobre la tarjeta de cita appt-02
      await tester.tap(find.byKey(const Key('appt_tile_appt-02')));
      await tester.pumpAndSettle();

      // Modal de detalle secundario debe abrirse
      expect(find.byKey(const Key('dialog_appointment_detail')), findsOneWidget);
      expect(find.text('Teléfono Invitado'), findsOneWidget);
      expect(find.text('3009876543'), findsOneWidget);
      expect(find.text('Tinte Completo Especial'), findsOneWidget);
      expect(find.text(r'$120000.00'), findsOneWidget);
    });

    testWidgets('11. Manejo de error de API y botón de reintento', (tester) async {
      mockService.shouldFailAgenda = true;

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('agenda_error')), findsOneWidget);
      expect(find.byKey(const Key('btn_retry_agenda')), findsOneWidget);

      // Arreglar mock y reintentar
      mockService.shouldFailAgenda = false;
      mockService.mockProjection = buildSampleProjection();

      await tester.tap(find.byKey(const Key('btn_retry_agenda')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('agenda_error')), findsNothing);
      expect(find.text('María Pérez'), findsNWidgets(2)); // Chip + Card
    });

    testWidgets('12. Boundary SCR-11: Acción Nueva Cita dispara callback', (tester) async {
      mockService.mockProjection = buildSampleProjection();
      bool createAppointmentCalled = false;

      await tester.pumpWidget(createTestWidget(
        onNavigateToCreateAppointment: () {
          createAppointmentCalled = true;
        },
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_nueva_cita')));
      await tester.pumpAndSettle();

      expect(createAppointmentCalled, isTrue);
    });
  });
}
