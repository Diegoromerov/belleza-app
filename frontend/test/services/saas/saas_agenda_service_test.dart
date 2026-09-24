// frontend/test/services/saas/saas_agenda_service_test.dart
// NODO-07 / SCR-10: Saas Agenda Service Unit Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas/saas_agenda_models.dart';
import 'package:beauty_app/services/saas/saas_agenda_service.dart';

void main() {
  group('SaasAgendaService Unit Tests', () {
    test('1. getAgendaProjection serializa parámetros y parsea DTO correctamente', () async {
      String? requestedPath;

      final service = SaasAgendaService(
        apiGet: (path) async {
          requestedPath = path;
          return {
            'establishment_id': 'est-uuid-01',
            'target_date': '2026-09-15',
            'timezone': 'America/Bogota',
            'professionals': [
              {
                'membership_id': 'mem-01',
                'user_id': 101,
                'name': 'María Pérez',
                'shifts': [
                  {'start_time': '08:00', 'end_time': '14:00'}
                ],
                'appointments': [
                  {
                    'id': 'appt-01',
                    'start_time': '09:00',
                    'end_time': '10:00',
                    'service_name': 'Corte Dama',
                    'client_name': 'Ana',
                    'status': 'SCHEDULED'
                  }
                ],
                'marketplace_bookings': [
                  {
                    'id': 1,
                    'start_time': '11:00',
                    'end_time': '12:00',
                    'status': 'CONFIRMADA'
                  }
                ]
              }
            ]
          };
        },
      );

      final result = await service.getAgendaProjection(
        targetDate: '2026-09-15',
        membershipId: 'mem-01',
      );

      expect(requestedPath, '/api/v1/saas/hub/appointments/agenda?target_date=2026-09-15&membership_id=mem-01');
      expect(result.establishmentId, 'est-uuid-01');
      expect(result.targetDate, '2026-09-15');
      expect(result.timezone, 'America/Bogota');
      expect(result.professionals.length, 1);

      final prof = result.professionals.first;
      expect(prof.name, 'María Pérez');
      expect(prof.shifts.first.startTime, '08:00');
      expect(prof.appointments.first.status, SaasAppointmentStatus.scheduled);
      expect(prof.marketplaceBookings.first.id, 1);
    });

    test('2. getAgendaProjection rechaza target_date vacío', () async {
      final service = SaasAgendaService();
      expect(
        () => service.getAgendaProjection(targetDate: '  '),
        throwsA(isA<SaasAgendaException>()),
      );
    });

    test('3. getAppointmentDetail parsea modelo secundario completo', () async {
      String? requestedPath;

      final service = SaasAgendaService(
        apiGet: (path) async {
          requestedPath = path;
          return {
            'id': 'appt-uuid-99',
            'tenant_id': 1,
            'establishment_id': 'est-uuid-01',
            'service_offer_id': 'offer-01',
            'membership_id': 'mem-01',
            'client_mode': 'GUEST',
            'guest_name': 'Carmen Invitada',
            'guest_phone': '3109876543',
            'guest_email': 'carmen@test.com',
            'scheduled_at': '2026-09-15T09:00:00-05:00',
            'end_time': '2026-09-15T10:00:00-05:00',
            'service_name_snapshot': 'Corte Dama',
            'duration_minutes_snapshot': 60,
            'price_snapshot': 50000.0,
            'status': 'CONFIRMED',
            'created_at': '2026-09-12T08:00:00Z',
            'updated_at': '2026-09-12T08:30:00Z',
          };
        },
      );

      final detail = await service.getAppointmentDetail('appt-uuid-99');

      expect(requestedPath, '/api/v1/saas/hub/appointments/appt-uuid-99');
      expect(detail.id, 'appt-uuid-99');
      expect(detail.guestName, 'Carmen Invitada');
      expect(detail.guestPhone, '3109876543');
      expect(detail.status, SaasAppointmentStatus.confirmed);
      expect(detail.priceSnapshot, 50000.0);
    });

    test('4. updateAppointmentStatus envía payload y cancellation_reason', () async {
      String? requestedPath;
      Map<String, dynamic>? requestedBody;

      final service = SaasAgendaService(
        apiPatch: (path, body) async {
          requestedPath = path;
          requestedBody = body;
          return {
            'id': 'appt-uuid-99',
            'tenant_id': 1,
            'establishment_id': 'est-uuid-01',
            'service_offer_id': 'offer-01',
            'membership_id': 'mem-01',
            'client_mode': 'GUEST',
            'guest_name': 'Carmen Invitada',
            'guest_phone': '3109876543',
            'scheduled_at': '2026-09-15T09:00:00-05:00',
            'end_time': '2026-09-15T10:00:00-05:00',
            'service_name_snapshot': 'Corte Dama',
            'duration_minutes_snapshot': 60,
            'price_snapshot': 50000.0,
            'status': 'CANCELLED',
            'cancellation_reason': 'Cliente no pudo asistir',
            'created_at': '2026-09-12T08:00:00Z',
            'updated_at': '2026-09-12T09:00:00Z',
          };
        },
      );

      final result = await service.updateAppointmentStatus(
        appointmentId: 'appt-uuid-99',
        targetStatus: 'CANCELLED',
        cancellationReason: 'Cliente no pudo asistir',
      );

      expect(requestedPath, '/api/v1/saas/hub/appointments/appt-uuid-99/status');
      expect(requestedBody?['status'], 'CANCELLED');
      expect(requestedBody?['cancellation_reason'], 'Cliente no pudo asistir');
      expect(result.status, SaasAppointmentStatus.cancelled);
      expect(result.cancellationReason, 'Cliente no pudo asistir');
    });

    test('5. updateAppointmentStatus maneja errores del backend', () async {
      final service = SaasAgendaService(
        apiPatch: (path, body) async {
          throw Exception('INVALID_STATE_TRANSITION');
        },
      );

      expect(
        () => service.updateAppointmentStatus(
          appointmentId: 'appt-uuid-99',
          targetStatus: 'CONFIRMED',
        ),
        throwsA(isA<SaasAgendaException>()),
      );
    });
  });
}
