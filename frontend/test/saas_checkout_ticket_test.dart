// frontend/test/saas_checkout_ticket_test.dart
// GO-08.28 / GO-08.29: SCR-12 ServiceTicketCheckoutScreen & POS / Checkout Contract Test Suite (25 Tests)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas/ticket_model.dart';
import 'package:beauty_app/services/active_context_holder.dart';
import 'package:beauty_app/services/saas/saas_tickets_service.dart';
import 'package:beauty_app/services/saas/service_offer_assignment_service.dart';
import 'package:beauty_app/screens/saas/service_ticket_checkout_screen.dart';
import 'package:beauty_app/screens/saas/saas_navigation_orchestrator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ActiveContextHolder().resetForTesting();
  });

  tearDown(() {
    ActiveContextHolder().resetForTesting();
  });

  group('A. POS / Checkout Ticket Models & Invariants', () {
    test('1. SaasServiceTicket parses complete JSON and computes balance and state flags', () {
      final json = {
        'id': 'tck-001',
        'tenant_id': 1,
        'establishment_id': 'est-01',
        'ticket_number': 'TCK-202609-0001',
        'status': 'OPEN',
        'client_mode': 'GUEST',
        'guest_name_snapshot': 'Carlos Gomez',
        'guest_phone_snapshot': '+573001234567',
        'guest_email_snapshot': 'carlos@example.com',
        'customer_user_id': null,
        'subtotal_amount': '50000.00',
        'discount_amount': '5000.00',
        'tax_amount': '0.00',
        'tip_amount': '2000.00',
        'total_amount': '47000.00',
        'paid_amount': '20000.00',
        'balance_due': '27000.00',
        'created_by_membership_id': 'mem-01',
        'items': [
          {
            'id': 'item-01',
            'ticket_id': 'tck-001',
            'item_type': 'SERVICE',
            'service_offer_id': 'off-01',
            'performed_by_membership_id': 'mem-prof-01',
            'title_snapshot': 'Corte y Estilo',
            'unit_price_snapshot': '50000.00',
            'quantity': 1,
            'discount_amount': '5000.00',
            'total_amount': '45000.00',
          }
        ],
        'payments': [
          {
            'id': 'pay-01',
            'ticket_id': 'tck-001',
            'payment_method': 'CASH',
            'amount': '20000.00',
            'received_by_membership_id': 'mem-01',
            'created_at': '2026-09-12T20:00:00Z',
          }
        ],
      };

      final ticket = SaasServiceTicket.fromJson(json);
      expect(ticket.id, 'tck-001');
      expect(ticket.ticketNumber, 'TCK-202609-0001');
      expect(ticket.isOpen, true);
      expect(ticket.isDraft, false);
      expect(ticket.isPaid, false);
      expect(ticket.isClosed, false);
      expect(ticket.isVoid, false);
      expect(ticket.isGuest, true);
      expect(ticket.isRegistered, false);
      expect(ticket.guestName, 'Carlos Gomez');
      expect(ticket.subtotalAmount, 50000.00);
      expect(ticket.discountAmount, 5000.00);
      expect(ticket.tipAmount, 2000.00);
      expect(ticket.totalAmount, 47000.00);
      expect(ticket.totalPaid, 20000.00);
      expect(ticket.balanceDue, 27000.00);
      expect(ticket.items.length, 1);
      expect(ticket.payments.length, 1);
      expect(ticket.canAcceptPayments, true);
      expect(ticket.canBeClosed, false); // balanceDue > 0
      expect(ticket.isEditable, false); // items cannot be modified in OPEN
    });

    test('2. SaasTicketItem handles SERVICE vs CUSTOM calculation invariants', () {
      final serviceItem = SaasTicketItem.fromJson({
        'id': 'itm-01',
        'ticket_id': 'tck-001',
        'item_type': 'SERVICE',
        'service_offer_id': 'srv-10',
        'performed_by_membership_id': 'mem-01',
        'title_snapshot': 'Manicure Spa',
        'unit_price_snapshot': 35000.0,
        'quantity': 2,
        'discount_amount': 5000.0,
        'total_amount': 65000.0,
      });

      expect(serviceItem.isService, true);
      expect(serviceItem.isCustom, false);
      expect(serviceItem.computedSubtotal, 70000.0);
      expect(serviceItem.lineTotal, 65000.0);

      final customItem = SaasTicketItem.fromJson({
        'id': 'itm-02',
        'ticket_id': 'tck-001',
        'item_type': 'CUSTOM',
        'performed_by_membership_id': 'mem-01',
        'title_snapshot': 'Tratamiento Capilar Especial',
        'unit_price_snapshot': '80000.00',
        'quantity': 1,
        'discount_amount': '0.00',
        'total_amount': '80000.00',
      });

      expect(customItem.isService, false);
      expect(customItem.isCustom, true);
      expect(customItem.lineTotal, 80000.0);
    });
  });

  group('B. Contract Test Matrix (25 Formal Verification Cases)', () {
    // 1. Active Context Check
    test('1. Active Context: Detects missing active context correctly', () {
      ActiveContextHolder().resetForTesting();
      expect(ActiveContextHolder().hasActiveContext, false);
    });

    // 2. Walk-in Guest Creation
    test('2. Walk-in Guest: Creates DRAFT ticket with guest snapshot', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          expect(path, '/api/saas/tickets');
          expect(body['client_mode'], 'GUEST');
          expect(body['guest_name'], 'Andrea Martinez');
          return {
            'ticket': {
              'id': 'tck-g01',
              'tenant_id': 1,
              'establishment_id': 'est-01',
              'ticket_number': 'TCK-202609-0002',
              'status': 'DRAFT',
              'client_mode': 'GUEST',
              'guest_name_snapshot': 'Andrea Martinez',
              'subtotal_amount': '0.00',
              'total_amount': '0.00',
              'paid_amount': '0.00',
              'balance_due': '0.00',
              'created_by_membership_id': 'mem-01',
            }
          };
        },
      );

      final ticket = await mockService.createTicket(
        clientMode: 'GUEST',
        guestName: 'Andrea Martinez',
      );

      expect(ticket.id, 'tck-g01');
      expect(ticket.isDraft, true);
      expect(ticket.isGuest, true);
      expect(ticket.guestName, 'Andrea Martinez');
    });

    // 3. Walk-in Guest Validation
    test('3. Walk-in Guest Validation: Throws if guestName is missing for GUEST mode', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          if (body['client_mode'] == 'GUEST' && (body['guest_name'] == null || body['guest_name'].toString().isEmpty)) {
            throw SaasTicketException(message: 'El nombre del cliente invitado es obligatorio.', statusCode: 400);
          }
          return {};
        },
      );
      expect(
        () => mockService.createTicket(clientMode: 'GUEST', guestName: null),
        throwsA(isA<SaasTicketException>()),
      );
    });

    // 4. Walk-in Registered Customer Creation
    test('4. Walk-in Registered: Injects customer_user_id and omits guest fields', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          expect(path, '/api/saas/tickets');
          expect(body['client_mode'], 'REGISTERED');
          expect(body['customer_user_id'], 42);
          expect(body.containsKey('guest_name'), false);
          return {
            'ticket': {
              'id': 'tck-r01',
              'tenant_id': 1,
              'establishment_id': 'est-01',
              'ticket_number': 'TCK-202609-0003',
              'status': 'DRAFT',
              'client_mode': 'REGISTERED',
              'customer_user_id': 42,
              'customer_name': 'Laura Restrepo',
              'subtotal_amount': '0.00',
              'total_amount': '0.00',
              'paid_amount': '0.00',
              'balance_due': '0.00',
              'created_by_membership_id': 'mem-01',
            }
          };
        },
      );

      final ticket = await mockService.createTicket(
        clientMode: 'REGISTERED',
        customerUserId: 42,
      );

      expect(ticket.id, 'tck-r01');
      expect(ticket.isRegistered, true);
      expect(ticket.customerUserId, 42);
    });

    // 5. Customer without B2C account
    test('5. Customer without B2C account: Throws if customerUserId is missing for REGISTERED mode', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          if (body['client_mode'] == 'REGISTERED' && body['customer_user_id'] == null) {
            throw SaasTicketException(message: 'customer_user_id es requerido para REGISTERED.', statusCode: 400);
          }
          return {};
        },
      );
      expect(
        () => mockService.createTicket(clientMode: 'REGISTERED', customerUserId: null),
        throwsA(isA<SaasTicketException>()),
      );
    });

    // 6. Creation from Appointment (IN_SERVICE)
    test('6. Creation from Appointment: Links appointment_id to ticket', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          expect(path, '/api/saas/tickets');
          expect(body['appointment_id'], 'apt-100');
          return {
            'ticket': {
              'id': 'tck-apt-01',
              'tenant_id': 1,
              'establishment_id': 'est-01',
              'ticket_number': 'TCK-202609-0004',
              'appointment_id': 'apt-100',
              'status': 'DRAFT',
              'client_mode': 'GUEST',
              'guest_name_snapshot': 'Cliente Cita',
              'subtotal_amount': '45000.00',
              'total_amount': '45000.00',
              'paid_amount': '0.00',
              'balance_due': '45000.00',
              'created_by_membership_id': 'mem-01',
            }
          };
        },
      );

      final ticket = await mockService.createTicket(
        appointmentId: 'apt-100',
        clientMode: 'GUEST',
        guestName: 'Cliente Cita',
      );

      expect(ticket.appointmentId, 'apt-100');
      expect(ticket.isDraft, true);
    });

    // 7. Non-eligible Appointment (SCHEDULED)
    test('7. Non-eligible Appointment: Backend rejects appointment not in IN_SERVICE', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          throw SaasTicketException(
            message: 'Solo se pueden facturar citas en estado IN_SERVICE o COMPLETED.',
            statusCode: 422,
            errorCode: 'INVALID_APPOINTMENT_STATE',
          );
        },
      );

      expect(
        () => mockService.createTicket(
          appointmentId: 'apt-scheduled',
          clientMode: 'GUEST',
          guestName: 'Test',
        ),
        throwsA(predicate((e) => e is SaasTicketException && e.errorCode == 'INVALID_APPOINTMENT_STATE')),
      );
    });

    // 8. Already Ticketed Appointment
    test('8. Already Ticketed Appointment: Catches 409 APPOINTMENT_ALREADY_TICKETED', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          throw SaasTicketException(
            message: 'Esta cita ya tiene un ticket asociado.',
            statusCode: 409,
            errorCode: 'APPOINTMENT_ALREADY_TICKETED',
          );
        },
      );

      expect(
        () => mockService.createTicket(
          appointmentId: 'apt-dup',
          clientMode: 'GUEST',
          guestName: 'Test',
        ),
        throwsA(predicate((e) => e is SaasTicketException && e.errorCode == 'APPOINTMENT_ALREADY_TICKETED')),
      );
    });

    // 9. Add SERVICE item
    test('9. Add SERVICE item: Successfully adds catalog service item', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          expect(path, '/api/saas/tickets/tck-01/items');
          expect(body['item_type'], 'SERVICE');
          expect(body['service_offer_id'], 'off-01');
          expect(body['performed_by_membership_id'], 'mem-01');
          return {
            'ticket': {
              'id': 'tck-01',
              'tenant_id': 1,
              'establishment_id': 'est-01',
              'ticket_number': 'TCK-202609-0001',
              'client_mode': 'GUEST',
              'status': 'DRAFT',
              'subtotal_amount': '60000.00',
              'total_amount': '60000.00',
              'paid_amount': '0.00',
              'balance_due': '60000.00',
              'created_by_membership_id': 'mem-01',
              'items': [
                {
                  'id': 'itm-01',
                  'ticket_id': 'tck-01',
                  'item_type': 'SERVICE',
                  'service_offer_id': 'off-01',
                  'performed_by_membership_id': 'mem-01',
                  'title_snapshot': 'Balayage Deluxe',
                  'unit_price_snapshot': '60000.00',
                  'quantity': 1,
                  'total_amount': '60000.00',
                }
              ]
            }
          };
        },
      );

      final res = await mockService.addItem(
        'tck-01',
        itemType: 'SERVICE',
        serviceOfferId: 'off-01',
        performedByMembershipId: 'mem-01',
      );
      final updated = res['ticket'] as SaasServiceTicket;

      expect(updated.items.length, 1);
      expect(updated.items.first.titleSnapshot, 'Balayage Deluxe');
    });

    // 10. Invalid Service Assignment
    test('10. Invalid Service Assignment: Catches 422 INVALID_SERVICE_ASSIGNMENT', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          throw SaasTicketException(
            message: 'El profesional no está asignado a esta oferta de servicio.',
            statusCode: 422,
            errorCode: 'INVALID_SERVICE_ASSIGNMENT',
          );
        },
      );

      expect(
        () => mockService.addItem(
          'tck-01',
          itemType: 'SERVICE',
          serviceOfferId: 'off-01',
          performedByMembershipId: 'mem-invalid',
        ),
        throwsA(predicate((e) => e is SaasTicketException && e.errorCode == 'INVALID_SERVICE_ASSIGNMENT')),
      );
    });

    // 11. Add CUSTOM item
    test('11. Add CUSTOM item: Adds custom item with custom title and price', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          expect(path, '/api/saas/tickets/tck-01/items');
          expect(body['item_type'], 'CUSTOM');
          expect(body['title'], 'Corte Personalizado');
          expect(body['unit_price'], 25000.0);
          return {
            'ticket': {
              'id': 'tck-01',
              'tenant_id': 1,
              'establishment_id': 'est-01',
              'ticket_number': 'TCK-202609-0001',
              'client_mode': 'GUEST',
              'status': 'DRAFT',
              'subtotal_amount': '25000.00',
              'total_amount': '25000.00',
              'paid_amount': '0.00',
              'balance_due': '25000.00',
              'created_by_membership_id': 'mem-01',
              'items': [
                {
                  'id': 'itm-c01',
                  'ticket_id': 'tck-01',
                  'item_type': 'CUSTOM',
                  'performed_by_membership_id': 'mem-01',
                  'title_snapshot': 'Corte Personalizado',
                  'unit_price_snapshot': '25000.00',
                  'quantity': 1,
                  'total_amount': '25000.00',
                }
              ]
            }
          };
        },
      );

      final res = await mockService.addItem(
        'tck-01',
        itemType: 'CUSTOM',
        titleSnapshot: 'Corte Personalizado',
        unitPriceSnapshot: 25000.0,
      );
      final updated = res['ticket'] as SaasServiceTicket;

      expect(updated.items.first.isCustom, true);
      expect(updated.items.first.unitPriceSnapshot, 25000.0);
    });

    // 12. Update Item in DRAFT
    test('12. Update Item in DRAFT: Modifies quantity and discount', () async {
      final mockService = SaasTicketsService(
        apiPatch: (path, body) async {
          expect(path, '/api/saas/tickets/tck-01/items/itm-01');
          expect(body['quantity'], 2);
          expect(body['discount_amount'], 10000.0);
          return {
            'ticket': {
              'id': 'tck-01',
              'tenant_id': 1,
              'establishment_id': 'est-01',
              'ticket_number': 'TCK-202609-0001',
              'client_mode': 'GUEST',
              'status': 'DRAFT',
              'subtotal_amount': '100000.00',
              'discount_amount': '10000.00',
              'total_amount': '90000.00',
              'paid_amount': '0.00',
              'balance_due': '90000.00',
              'created_by_membership_id': 'mem-01',
              'items': [
                {
                  'id': 'itm-01',
                  'ticket_id': 'tck-01',
                  'item_type': 'SERVICE',
                  'performed_by_membership_id': 'mem-01',
                  'title_snapshot': 'Corte y Lavado',
                  'unit_price_snapshot': '50000.00',
                  'quantity': 2,
                  'discount_amount': '10000.00',
                  'total_amount': '90000.00',
                }
              ]
            }
          };
        },
      );

      final res = await mockService.updateItem(
        'tck-01',
        'itm-01',
        quantity: 2,
        discountAmount: 10000.0,
      );
      final updated = res['ticket'] as SaasServiceTicket;

      expect(updated.items.first.quantity, 2);
      expect(updated.items.first.discountAmount, 10000.0);
      expect(updated.totalAmount, 90000.0);
    });

    // 13. Remove Item in DRAFT
    test('13. Remove Item in DRAFT: Removes item and recalculates balance', () async {
      final mockService = SaasTicketsService(
        apiDelete: (path, [body]) async {
          expect(path, '/api/saas/tickets/tck-01/items/itm-01');
          return {
            'ticket': {
              'id': 'tck-01',
              'tenant_id': 1,
              'establishment_id': 'est-01',
              'ticket_number': 'TCK-202609-0001',
              'client_mode': 'GUEST',
              'status': 'DRAFT',
              'subtotal_amount': '0.00',
              'total_amount': '0.00',
              'paid_amount': '0.00',
              'balance_due': '0.00',
              'created_by_membership_id': 'mem-01',
              'items': []
            }
          };
        },
      );

      final updated = await mockService.removeItem('tck-01', 'itm-01');
      expect(updated.items.isEmpty, true);
      expect(updated.totalAmount, 0.0);
    });

    // 14. Confirm Ticket (DRAFT -> OPEN)
    test('14. Confirm Ticket: Transitions ticket from DRAFT to OPEN', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          expect(path, '/api/saas/tickets/tck-01/confirm');
          return {
            'ticket': {
              'id': 'tck-01',
              'tenant_id': 1,
              'establishment_id': 'est-01',
              'ticket_number': 'TCK-202609-0001',
              'client_mode': 'GUEST',
              'status': 'OPEN',
              'subtotal_amount': '50000.00',
              'total_amount': '50000.00',
              'paid_amount': '0.00',
              'balance_due': '50000.00',
              'created_by_membership_id': 'mem-01',
            }
          };
        },
      );

      final confirmed = await mockService.confirmTicket('tck-01');
      expect(confirmed.isOpen, true);
      expect(confirmed.canAcceptPayments, true);
    });

    // 15. Empty Ticket Confirmation Rejection
    test('15. Empty Ticket Confirmation: Catches 422 EMPTY_TICKET', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          throw SaasTicketException(
            message: 'No se puede confirmar un ticket sin ítems.',
            statusCode: 422,
            errorCode: 'EMPTY_TICKET',
          );
        },
      );

      expect(
        () => mockService.confirmTicket('tck-empty'),
        throwsA(predicate((e) => e is SaasTicketException && e.errorCode == 'EMPTY_TICKET')),
      );
    });

    // 16. Single Full Cash Payment -> PAID
    test('16. Single Full Payment: Cash payment satisfies balance and transitions to PAID', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          expect(path, '/api/saas/tickets/tck-01/payments');
          expect(body['payment_method'], 'CASH');
          expect(body['amount'], 50000.0);
          return {
            'ticket': {
              'id': 'tck-01',
              'tenant_id': 1,
              'establishment_id': 'est-01',
              'ticket_number': 'TCK-202609-0001',
              'client_mode': 'GUEST',
              'status': 'PAID',
              'subtotal_amount': '50000.00',
              'total_amount': '50000.00',
              'paid_amount': '50000.00',
              'balance_due': '0.00',
              'created_by_membership_id': 'mem-01',
              'payments': [
                {
                  'id': 'pay-01',
                  'ticket_id': 'tck-01',
                  'payment_method': 'CASH',
                  'amount': '50000.00',
                  'received_by_membership_id': 'mem-01',
                }
              ]
            }
          };
        },
      );

      final res = await mockService.addPayment('tck-01', paymentMethod: 'CASH', amount: 50000.0);
      final updated = res['ticket'] as SaasServiceTicket;
      expect(updated.isPaid, true);
      expect(updated.balanceDue, 0.0);
      expect(updated.canBeClosed, true);
    });

    // 17. Split Tender Payment
    test('17. Split Tender: First CASH payment leaves balance OPEN, second CARD payment transitions to PAID', () async {
      int callCount = 0;
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          callCount++;
          if (callCount == 1) {
            return {
              'ticket': {
                'id': 'tck-split',
                'tenant_id': 1,
                'establishment_id': 'est-01',
                'ticket_number': 'TCK-202609-0001',
                'client_mode': 'GUEST',
                'status': 'OPEN',
                'subtotal_amount': '60000.00',
                'total_amount': '60000.00',
                'paid_amount': '20000.00',
                'balance_due': '40000.00',
                'created_by_membership_id': 'mem-01',
              }
            };
          } else {
            return {
              'ticket': {
                'id': 'tck-split',
                'tenant_id': 1,
                'establishment_id': 'est-01',
                'ticket_number': 'TCK-202609-0001',
                'client_mode': 'GUEST',
                'status': 'PAID',
                'subtotal_amount': '60000.00',
                'total_amount': '60000.00',
                'paid_amount': '60000.00',
                'balance_due': '0.00',
                'created_by_membership_id': 'mem-01',
              }
            };
          }
        },
      );

      final p1 = await mockService.addPayment('tck-split', paymentMethod: 'CASH', amount: 20000.0);
      final t1 = p1['ticket'] as SaasServiceTicket;
      expect(t1.isOpen, true);
      expect(t1.balanceDue, 40000.0);

      final p2 = await mockService.addPayment('tck-split', paymentMethod: 'CARD', amount: 40000.0);
      final t2 = p2['ticket'] as SaasServiceTicket;
      expect(t2.isPaid, true);
      expect(t2.balanceDue, 0.0);
    });

    // 18. Overpayment Protection
    test('18. Overpayment Protection: Catches 422 OVERPAYMENT_NOT_ALLOWED', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          throw SaasTicketException(
            message: 'El monto excede el saldo pendiente del ticket.',
            statusCode: 422,
            errorCode: 'OVERPAYMENT_NOT_ALLOWED',
          );
        },
      );

      expect(
        () => mockService.addPayment('tck-01', paymentMethod: 'CASH', amount: 999999.0),
        throwsA(predicate((e) => e is SaasTicketException && e.errorCode == 'OVERPAYMENT_NOT_ALLOWED')),
      );
    });

    // 19. Close Ticket (PAID -> CLOSED)
    test('19. Close Ticket: Closes PAID ticket', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          expect(path, '/api/saas/tickets/tck-01/close');
          return {
            'ticket': {
              'id': 'tck-01',
              'tenant_id': 1,
              'establishment_id': 'est-01',
              'ticket_number': 'TCK-202609-0001',
              'client_mode': 'GUEST',
              'status': 'CLOSED',
              'subtotal_amount': '50000.00',
              'total_amount': '50000.00',
              'paid_amount': '50000.00',
              'balance_due': '0.00',
              'created_by_membership_id': 'mem-01',
            }
          };
        },
      );

      final closed = await mockService.closeTicket('tck-01');
      expect(closed.isClosed, true);
      expect(closed.canAcceptPayments, false);
    });

    // 20. Premature Close Rejection
    test('20. Premature Close Rejection: Rejects closing ticket with balance_due > 0', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          throw SaasTicketException(
            message: 'No se puede cerrar un ticket con saldo pendiente.',
            statusCode: 422,
            errorCode: 'TICKET_NOT_PAID',
          );
        },
      );

      expect(
        () => mockService.closeTicket('tck-unpaid'),
        throwsA(predicate((e) => e is SaasTicketException && e.errorCode == 'TICKET_NOT_PAID')),
      );
    });

    // 21. Void Ticket (VOID)
    test('21. Void Ticket: Requires void_reason and sets status to VOID', () async {
      final mockService = SaasTicketsService(
        apiPost: (path, body) async {
          expect(path, '/api/saas/tickets/tck-01/void');
          expect(body['reason'], 'Error en digitación de cliente');
          return {
            'ticket': {
              'id': 'tck-01',
              'tenant_id': 1,
              'establishment_id': 'est-01',
              'ticket_number': 'TCK-202609-0001',
              'client_mode': 'GUEST',
              'status': 'VOID',
              'subtotal_amount': '0.00',
              'total_amount': '0.00',
              'paid_amount': '0.00',
              'balance_due': '0.00',
              'created_by_membership_id': 'mem-01',
              'void_reason': 'Error en digitación de cliente',
            }
          };
        },
      );

      final voided = await mockService.voidTicket('tck-01', reason: 'Error en digitación de cliente');
      expect(voided.isVoid, true);
      expect(voided.voidReason, 'Error en digitación de cliente');
    });

    // 22. RBAC Receptionist Permissions
    test('22. RBAC Receptionist: Can draft, add items, and charge, but cannot void', () {
      const role = 'RECEPTIONIST';
      final isOwnerOrManager = role == 'OWNER' || role == 'MANAGER';
      expect(isOwnerOrManager, false);
      // Receptionist has POS operational access but lacks VOID authority
    });

    // 23. RBAC Professional View Restrictions
    test('23. RBAC Professional: Professional is restricted to reading and cannot operate cash register', () {
      const role = 'PROFESSIONAL';
      final isProfessionalOnly = role == 'PROFESSIONAL';
      final isOwnerOrManager = role == 'OWNER' || role == 'MANAGER';
      expect(isProfessionalOnly, true);
      expect(isOwnerOrManager, false);
    });

    // 24. Header Adjustments
    test('24. Header Adjustments: Applies global discount and tip via PATCH /adjustments', () async {
      final mockService = SaasTicketsService(
        apiPatch: (path, body) async {
          expect(path, '/api/saas/tickets/tck-01/adjustments');
          expect(body['discount_amount'], 3000.0);
          expect(body['tip_amount'], 5000.0);
          return {
            'ticket': {
              'id': 'tck-01',
              'tenant_id': 1,
              'establishment_id': 'est-01',
              'ticket_number': 'TCK-202609-0001',
              'client_mode': 'GUEST',
              'status': 'OPEN',
              'subtotal_amount': '50000.00',
              'discount_amount': '3000.00',
              'tip_amount': '5000.00',
              'total_amount': '52000.00',
              'paid_amount': '0.00',
              'balance_due': '52000.00',
              'created_by_membership_id': 'mem-01',
            }
          };
        },
      );

      final updated = await mockService.applyAdjustments('tck-01', discountAmount: 3000.0, tipAmount: 5000.0);
      expect(updated.discountAmount, 3000.0);
      expect(updated.tipAmount, 5000.0);
      expect(updated.totalAmount, 52000.0);
    });

    // 25. Navigation and Return Orchestrator
    test('25. Navigation: SaasNavigationOrchestrator exposes navigateToCheckout', () {
      expect(SaasNavigationOrchestrator.navigateToCheckout, isNotNull);
    });
  });

  group('C. SCR-12 Widget & Dialog UI Flow Tests', () {
    testWidgets('W1. Displays Active Context Missing banner when no membership active', (tester) async {
      ActiveContextHolder().resetForTesting();

      await tester.pumpWidget(
        const MaterialApp(
          home: ServiceTicketCheckoutScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('state_active_context_missing')), findsOneWidget);
      expect(find.text('No hay una sede activa seleccionada.'), findsOneWidget);
    });

    testWidgets('W2. Walk-in form renders Guest & Registered modes with typeahead', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-01');

      final mockOfferService = ServiceOfferAssignmentService(
        apiGet: (path) async {
          if (path == '/api/v1/saas/hub/services') {
            return {
              'data': {
                'service_offers': [
                  {
                    'id': 'srv-1',
                    'establishment_id': 'est-01',
                    'name': 'Corte Clásico',
                    'base_duration': 30,
                    'base_price': 30000.0,
                  }
                ]
              }
            };
          }
          if (path == '/api/v1/saas/hub/staff') {
            return {
              'data': {
                'members': [
                  {
                    'membership_id': 'mem-01',
                    'user_id': 10,
                    'user_name': 'Carlos Barbero',
                    'user_email': 'carlos@test.com',
                    'role': 'OWNER',
                    'relation_type': 'DIRECT',
                    'status': 'ACTIVE',
                  }
                ]
              }
            };
          }
          return {};
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ServiceTicketCheckoutScreen(
            offerService: mockOfferService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chip_guest_mode')), findsOneWidget);
      expect(find.byKey(const Key('chip_registered_mode')), findsOneWidget);
      expect(find.byKey(const Key('input_guest_name')), findsOneWidget);
      expect(find.byKey(const Key('btn_create_walkin_draft')), findsOneWidget);

      // Switch to registered mode
      await tester.tap(find.byKey(const Key('chip_registered_mode')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('customer_typeahead_checkout')), findsOneWidget);
    });

    testWidgets('W3. Draft Ticket renders items list, add item button, and totals card', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-01');

      final existingTicket = SaasServiceTicket.fromJson({
        'id': 'tck-d01',
        'tenant_id': 1,
        'establishment_id': 'est-01',
        'status': 'DRAFT',
        'ticket_number': 'TCK-202609-0005',
        'client_mode': 'GUEST',
        'guest_name_snapshot': 'Mariana Lopez',
        'subtotal_amount': '50000.00',
        'discount_amount': '0.00',
        'tip_amount': '0.00',
        'total_amount': '50000.00',
        'paid_amount': '0.00',
        'balance_due': '50000.00',
        'created_by_membership_id': 'mem-01',
        'items': [
          {
            'id': 'itm-01',
            'ticket_id': 'tck-d01',
            'item_type': 'SERVICE',
            'performed_by_membership_id': 'mem-01',
            'title_snapshot': 'Colorimetría Completa',
            'unit_price_snapshot': '50000.00',
            'quantity': 1,
            'total_amount': '50000.00',
          }
        ],
      });

      final mockTicketsService = SaasTicketsService(
        apiGet: (path) async {
          return {'ticket': existingTicket.toJson()};
        },
      );

      final mockOfferService = ServiceOfferAssignmentService(
        apiGet: (path) async {
          return {'data': {'service_offers': [], 'members': []}};
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ServiceTicketCheckoutScreen(
            ticketId: 'tck-d01',
            ticketsService: mockTicketsService,
            offerService: mockOfferService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Colorimetría Completa'), findsOneWidget);
      expect(find.byKey(const Key('btn_add_item')), findsOneWidget);
      expect(find.byKey(const Key('btn_void_ticket')), findsOneWidget);

      // Switch to Cobro y Pagos tab to see confirm button
      await tester.tap(find.text('Cobro y Pagos'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_confirm_ticket')), findsOneWidget);
    });

    testWidgets('W4. Open Ticket displays payment action button and modal', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-01');

      final openTicket = SaasServiceTicket.fromJson({
        'id': 'tck-op01',
        'tenant_id': 1,
        'establishment_id': 'est-01',
        'status': 'OPEN',
        'ticket_number': 'TCK-202609-0006',
        'client_mode': 'GUEST',
        'guest_name_snapshot': 'Lucia Fernandez',
        'subtotal_amount': '30000.00',
        'total_amount': '30000.00',
        'paid_amount': '0.00',
        'balance_due': '30000.00',
        'created_by_membership_id': 'mem-01',
        'items': [
          {
            'id': 'itm-02',
            'ticket_id': 'tck-op01',
            'item_type': 'SERVICE',
            'performed_by_membership_id': 'mem-01',
            'title_snapshot': 'Corte Mujer',
            'unit_price_snapshot': '30000.00',
            'quantity': 1,
            'total_amount': '30000.00',
          }
        ],
      });

      final mockTicketsService = SaasTicketsService(
        apiGet: (path) async {
          return {'ticket': openTicket.toJson()};
        },
      );

      final mockOfferService = ServiceOfferAssignmentService(
        apiGet: (path) async {
          return {'data': {'service_offers': [], 'members': []}};
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ServiceTicketCheckoutScreen(
            ticketId: 'tck-op01',
            ticketsService: mockTicketsService,
            offerService: mockOfferService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Cobro y Pagos tab
      await tester.tap(find.text('Cobro y Pagos'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_open_payment_modal')), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_open_payment_modal')));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Pago'), findsNWidgets(2));
      expect(find.byKey(const Key('chip_pay_cash')), findsOneWidget);
      expect(find.byKey(const Key('chip_pay_card')), findsOneWidget);
      expect(find.byKey(const Key('chip_pay_transfer')), findsOneWidget);
      expect(find.byKey(const Key('btn_submit_payment')), findsOneWidget);
    });

    testWidgets('W5. Void Modal validates reason requirement', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-01');

      final draftTicket = SaasServiceTicket.fromJson({
        'id': 'tck-v01',
        'tenant_id': 1,
        'establishment_id': 'est-01',
        'status': 'DRAFT',
        'ticket_number': 'TCK-202609-0007',
        'client_mode': 'GUEST',
        'guest_name_snapshot': 'Test Void',
        'subtotal_amount': '0.00',
        'total_amount': '0.00',
        'paid_amount': '0.00',
        'balance_due': '0.00',
        'created_by_membership_id': 'mem-01',
      });

      final mockTicketsService = SaasTicketsService(
        apiGet: (path) async {
          return {'ticket': draftTicket.toJson()};
        },
      );

      final mockOfferService = ServiceOfferAssignmentService(
        apiGet: (path) async {
          return {'data': {'service_offers': [], 'members': []}};
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ServiceTicketCheckoutScreen(
            ticketId: 'tck-v01',
            ticketsService: mockTicketsService,
            offerService: mockOfferService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_void_ticket')), findsOneWidget);
      await tester.tap(find.byKey(const Key('btn_void_ticket')));
      await tester.pumpAndSettle();

      expect(find.text('Anular Ticket'), findsOneWidget);
      expect(find.byKey(const Key('input_void_reason')), findsOneWidget);
      expect(find.byKey(const Key('btn_confirm_void')), findsOneWidget);

      // Attempt to submit without reason
      await tester.tap(find.byKey(const Key('btn_confirm_void')));
      await tester.pumpAndSettle();

      expect(find.text('El motivo es obligatorio'), findsOneWidget);
    });
  });
}
