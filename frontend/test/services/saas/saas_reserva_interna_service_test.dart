// frontend/test/services/saas/saas_reserva_interna_service_test.dart
// NODO-07 / SCR-11: Saas Reserva Interna Service Unit Tests

import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas/saas_agenda_models.dart';
import 'package:beauty_app/models/saas/saas_reserva_interna_models.dart';
import 'package:beauty_app/services/saas/saas_reserva_interna_service.dart';

void main() {
  group('SaasReservaInternaService DTO and Unit Tests', () {
    test('1. SaasAvailabilitySlot and Projection parse correctly from JSON', () {
      final json = {
        'establishment_id': 'est-123',
        'service_offer_id': 'srv-999',
        'target_date': '2026-09-15',
        'service_duration_minutes': 45,
        'step_minutes': 15,
        'projection_mode': 'AGGREGATED',
        'slots': [
          {
            'start_time': '09:00',
            'end_time': '09:45',
            'available_memberships': ['mem-01', 'mem-02']
          },
          {
            'start_time': '10:00',
            'end_time': '10:45',
            'available_memberships': ['mem-01']
          }
        ]
      };

      final proj = SaasAvailabilityProjection.fromJson(json);
      expect(proj.establishmentId, 'est-123');
      expect(proj.serviceOfferId, 'srv-999');
      expect(proj.targetDate, '2026-09-15');
      expect(proj.serviceDurationMinutes, 45);
      expect(proj.stepMinutes, 15);
      expect(proj.projectionMode, 'AGGREGATED');
      expect(proj.slots.length, 2);

      final slot1 = proj.slots[0];
      expect(slot1.startTime, '09:00');
      expect(slot1.endTime, '09:45');
      expect(slot1.availableMemberships, ['mem-01', 'mem-02']);

      final slot2 = proj.slots[1];
      expect(slot2.startTime, '10:00');
      expect(slot2.endTime, '10:45');
      expect(slot2.availableMemberships, ['mem-01']);
    });

    test('2. CreateAppointmentPayload serialization with GUEST XOR', () {
      final payload = CreateAppointmentPayload(
        serviceOfferId: 'srv-1',
        membershipId: 'mem-1',
        scheduledAt: '2026-09-15T09:00:00-05:00',
        guestName: 'Laura Invitada',
        guestPhone: '3001234567',
        guestEmail: 'laura@example.com',
      );

      final map = payload.toJson();
      expect(map['service_offer_id'], 'srv-1');
      expect(map['membership_id'], 'mem-1');
      expect(map['scheduled_at'], '2026-09-15T09:00:00-05:00');
      expect(map['guest_name'], 'Laura Invitada');
      expect(map['guest_phone'], '3001234567');
      expect(map['guest_email'], 'laura@example.com');
      expect(map.containsKey('customer_user_id'), isFalse);
    });

    test('3. CreateAppointmentPayload serialization with REGISTERED XOR', () {
      final payload = CreateAppointmentPayload(
        serviceOfferId: 'srv-1',
        membershipId: 'mem-1',
        scheduledAt: '2026-09-15T09:00:00-05:00',
        customerUserId: 402,
      );

      final map = payload.toJson();
      expect(map['service_offer_id'], 'srv-1');
      expect(map['membership_id'], 'mem-1');
      expect(map['customer_user_id'], 402);
      expect(map.containsKey('guest_name'), isFalse);
      expect(map.containsKey('guest_phone'), isFalse);
      expect(map.containsKey('guest_email'), isFalse);
    });

    test('4. getServiceOffers sends GET and parses ServiceOfferModel list', () async {
      String? requestedPath;
      final service = SaasReservaInternaService(
        apiGet: (path) async {
          requestedPath = path;
          return {
            'success': true,
            'data': {
              'service_offers': [
                {
                  'id': 'offer-01',
                  'establishment_id': 'est-01',
                  'name': 'Corte Dama',
                  'base_duration': 45,
                  'base_price': 40000.0,
                },
                {
                  'id': 'offer-02',
                  'establishment_id': 'est-01',
                  'name': 'Barba y Perfilado',
                  'base_duration': 30,
                  'base_price': 25000.0,
                }
              ]
            }
          };
        },
      );

      final offers = await service.getServiceOffers();
      expect(requestedPath, '/api/v1/saas/hub/services');
      expect(offers.length, 2);
      expect(offers[0].id, 'offer-01');
      expect(offers[0].name, 'Corte Dama');
      expect(offers[0].baseDuration, 45);
      expect(offers[0].basePrice, 40000.0);
    });

    test('5. getStaffMembers sends GET and parses StaffMemberOption list', () async {
      String? requestedPath;
      final service = SaasReservaInternaService(
        apiGet: (path) async {
          requestedPath = path;
          return {
            'success': true,
            'data': {
              'staff': [
                {'membership_id': 'mem-01', 'name': 'Camila Estilista'},
                {'membership_id': 'mem-02', 'name': 'Daniel Barbero'},
              ]
            }
          };
        },
      );

      final staff = await service.getStaffMembers();
      expect(requestedPath, '/api/v1/saas/hub/staff');
      expect(staff.length, 2);
      expect(staff[0].membershipId, 'mem-01');
      expect(staff[0].name, 'Camila Estilista');
    });

    test('6. getAvailabilityProjection constructs correct query string for AGGREGATED mode', () async {
      String? requestedPath;
      final service = SaasReservaInternaService(
        apiGet: (path) async {
          requestedPath = path;
          return {
            'establishment_id': 'est-01',
            'service_offer_id': 'srv-1',
            'target_date': '2026-09-15',
            'service_duration_minutes': 45,
            'step_minutes': 15,
            'projection_mode': 'AGGREGATED',
            'slots': [
              {
                'start_time': '09:00',
                'end_time': '09:45',
                'available_memberships': ['mem-01']
              }
            ]
          };
        },
      );

      final proj = await service.getAvailabilityProjection(
        serviceOfferId: 'srv-1',
        targetDate: '2026-09-15',
        projectionMode: 'AGGREGATED',
      );

      expect(requestedPath, contains('/api/v1/saas/hub/availability/projection'));
      expect(requestedPath, contains('service_offer_id=srv-1'));
      expect(requestedPath, contains('target_date=2026-09-15'));
      expect(requestedPath, contains('projection_mode=AGGREGATED'));
      expect(proj.slots.length, 1);
    });

    test('7. createAppointment sends POST and returns SaasAppointmentDetailModel', () async {
      String? requestedPath;
      Map<String, dynamic>? postedBody;

      final service = SaasReservaInternaService(
        apiPost: (path, body) async {
          requestedPath = path;
          postedBody = body;
          return {
            'id': 'appt-uuid-99',
            'tenant_id': 1,
            'establishment_id': 'est-01',
            'service_offer_id': 'srv-1',
            'membership_id': 'mem-01',
            'client_mode': 'GUEST',
            'guest_name': 'Camila Invitada',
            'guest_phone': '3129876543',
            'scheduled_at': '2026-09-15T09:00:00-05:00',
            'end_time': '2026-09-15T09:45:00-05:00',
            'service_name_snapshot': 'Corte Dama',
            'duration_minutes_snapshot': 45,
            'price_snapshot': 40000.0,
            'status': 'SCHEDULED',
            'created_at': '2026-09-12T10:00:00Z',
            'updated_at': '2026-09-12T10:00:00Z',
          };
        },
      );

      final detail = await service.createAppointment(
        CreateAppointmentPayload(
          serviceOfferId: 'srv-1',
          membershipId: 'mem-01',
          scheduledAt: '2026-09-15T09:00:00-05:00',
          guestName: 'Camila Invitada',
          guestPhone: '3129876543',
        ),
      );

      expect(requestedPath, '/api/v1/saas/hub/appointments');
      expect(postedBody?['guest_name'], 'Camila Invitada');
      expect(detail.id, 'appt-uuid-99');
      expect(detail.status, SaasAppointmentStatus.scheduled);
    });

    test('8. createAppointment catches 409 collision and rethrows SaasReservaInternaException with 409', () async {
      final service = SaasReservaInternaService(
        apiPost: (path, body) async {
          throw Exception('409 APPOINTMENT_OCCUPANCY_COLLISION: Slot overlaps with an existing active appointment');
        },
      );

      expect(
        () => service.createAppointment(
          CreateAppointmentPayload(
            serviceOfferId: 'srv-1',
            membershipId: 'mem-01',
            scheduledAt: '2026-09-15T09:00:00-05:00',
            guestName: 'Camila Invitada',
            guestPhone: '3129876543',
          ),
        ),
        throwsA(isA<SaasReservaInternaException>().having((e) => e.statusCode, 'statusCode', 409)),
      );
    });
  });
}
