// frontend/test/saas_customer_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas/customer_model.dart';
import 'package:beauty_app/services/active_context_holder.dart';
import 'package:beauty_app/services/saas/saas_customers_service.dart';
import 'package:beauty_app/screens/saas/customer_directory_screen.dart';
import 'package:beauty_app/screens/saas/widgets/customer_duplicate_modal.dart';
import 'package:beauty_app/screens/saas/widgets/customer_typeahead.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ActiveContextHolder().resetForTesting();
  });

  tearDown(() {
    ActiveContextHolder().resetForTesting();
  });

  group('A. Customer Models & Serialization Unit Tests', () {
    test('1. SaasCustomerSummary parses JSON and handles fullName', () {
      final json = {
        'id': 'c001',
        'tenant_id': 't001',
        'user_id': 'u100',
        'first_name': 'Laura',
        'last_name': 'Restrepo',
        'phone': '+573001112233',
        'email': 'laura@example.com',
        'status': 'ACTIVE',
        'is_associated_with_active_establishment': true,
      };

      final model = SaasCustomerSummary.fromJson(json);
      expect(model.id, 'c001');
      expect(model.fullName, 'Laura Restrepo');
      expect(model.hasLinkedUser, true);
      expect(model.isAssociatedWithActiveEstablishment, true);

      final outJson = model.toJson();
      expect(outJson['first_name'], 'Laura');
      expect(outJson['last_name'], 'Restrepo');
    });

    test('2. SaasCustomerDetail parses JSON with localEstablishment', () {
      final json = {
        'customer': {
          'id': 'c002',
          'first_name': 'Carlos',
          'last_name': 'Mendoza',
          'status': 'INACTIVE',
          'notes': 'Cliente VIP del tenant',
        },
        'local_establishment': {
          'customer_id': 'c002',
          'establishment_id': 'est-01',
          'local_notes': 'Alergia al amoniaco',
          'is_active': true,
        }
      };

      final detail = SaasCustomerDetail.fromJson(json);
      expect(detail.id, 'c002');
      expect(detail.firstName, 'Carlos');
      expect(detail.status, 'INACTIVE');
      expect(detail.notes, 'Cliente VIP del tenant');
      expect(detail.localNotes, 'Alergia al amoniaco');
      expect(detail.isLocallyActive, true);
    });

    test('3. CustomerHistoryResult parses ATTRIBUTED vs UNLINKED states', () {
      final attributedJson = {
        'attribution_status': 'ATTRIBUTED_VIA_USER_ACCOUNT',
        'count': 1,
        'appointments': [
          {
            'id': 'apt-01',
            'appointment_date': '2026-09-15',
            'start_time': '10:00:00',
            'status': 'COMPLETED',
            'service_title': 'Corte de Cabello',
            'professional_name': 'Ana Profesional',
          }
        ]
      };

      final histAttributed = CustomerHistoryResult.fromJson(attributedJson);
      expect(histAttributed.isAttributed, true);
      expect(histAttributed.count, 1);
      expect(histAttributed.appointments.first.serviceTitle, 'Corte de Cabello');

      final unlinkedJson = {
        'attribution_status': 'UNLINKED_NO_ATTRIBUTED_HISTORY',
        'count': 0,
        'appointments': []
      };

      final histUnlinked = CustomerHistoryResult.fromJson(unlinkedJson);
      expect(histUnlinked.isAttributed, false);
      expect(histUnlinked.count, 0);
    });
  });

  group('B. SaasCustomersService Unit Tests', () {
    test('4. listCustomers sends query params and parses result', () async {
      final service = SaasCustomersService(
        apiGet: (path) async {
          expect(path, contains('/api/saas/customers?scope=establishment&page=1&limit=20'));
          return {
            'scope': 'establishment',
            'pagination': {'total': 1, 'page': 1, 'limit': 20, 'total_pages': 1},
            'data': [
              {'id': 'c001', 'first_name': 'María', 'last_name': 'Pérez', 'status': 'ACTIVE'}
            ]
          };
        },
      );

      final result = await service.listCustomers();
      expect(result.customers.length, 1);
      expect(result.customers.first.fullName, 'María Pérez');
    });

    test('5. searchCustomers trims and rejects queries < 3 chars', () async {
      int getCalls = 0;
      final service = SaasCustomersService(
        apiGet: (path) async {
          getCalls++;
          return {'data': []};
        },
      );

      final shortResult = await service.searchCustomers('ab');
      expect(shortResult, isEmpty);
      expect(getCalls, 0);

      final validResult = await service.searchCustomers('mari');
      expect(getCalls, 1);
    });

    test('6. createCustomer sends payload and parses created detail', () async {
      final service = SaasCustomersService(
        apiPost: (path, body) async {
          expect(path, '/api/saas/customers');
          expect(body['first_name'], 'Lucía');
          expect(body['confirm_duplicate'], false);
          return {
            'customer': {'id': 'c999', 'first_name': 'Lucía', 'status': 'ACTIVE'},
            'local_establishment': {'is_active': true}
          };
        },
      );

      final created = await service.createCustomer(
        firstName: 'Lucía',
        confirmDuplicate: false,
      );
      expect(created.id, 'c999');
      expect(created.firstName, 'Lucía');
    });

    test('7. updateCustomer sends PATCH to /api/saas/customers/:id', () async {
      final service = SaasCustomersService(
        apiPatch: (path, body) async {
          expect(path, '/api/saas/customers/c999');
          expect(body['notes'], 'Notas actualizadas');
          return {
            'customer': {'id': 'c999', 'first_name': 'Lucía', 'notes': 'Notas actualizadas', 'status': 'ACTIVE'},
          };
        },
      );

      final updated = await service.updateCustomer('c999', notes: 'Notas actualizadas');
      expect(updated.notes, 'Notas actualizadas');
    });

    test('8. associateEstablishment and updateEstablishmentRelation send requests', () async {
      int assocCalls = 0;
      int patchCalls = 0;

      final service = SaasCustomersService(
        apiPost: (path, body) async {
          if (path.contains('/establishments')) {
            assocCalls++;
            expect(body['local_notes'], 'Nota inicial');
            return {'relation': {'customer_id': 'c1', 'local_notes': 'Nota inicial', 'is_active': true}};
          }
          throw Exception();
        },
        apiPatch: (path, body) async {
          if (path.contains('/establishments/current')) {
            patchCalls++;
            expect(body['is_active'], false);
            return {'relation': {'customer_id': 'c1', 'is_active': false}};
          }
          throw Exception();
        },
      );

      final assoc = await service.associateEstablishment('c1', localNotes: 'Nota inicial');
      expect(assocCalls, 1);
      expect(assoc.localNotes, 'Nota inicial');

      final updated = await service.updateEstablishmentRelation('c1', isActive: false);
      expect(patchCalls, 1);
      expect(updated.isActive, false);
    });

    test('9. linkUser and unlinkUser send POST to respective sub-routes', () async {
      int linkCalls = 0;
      int unlinkCalls = 0;

      final service = SaasCustomersService(
        apiPost: (path, body) async {
          if (path.contains('/link-user')) {
            linkCalls++;
            expect(body['user_id'], 'u-123');
            return {'success': true, 'message': 'Linked'};
          }
          if (path.contains('/unlink-user')) {
            unlinkCalls++;
            return {'success': true, 'message': 'Unlinked'};
          }
          throw Exception('Unknown path');
        },
      );

      final linkRes = await service.linkUser('c100', userId: 'u-123');
      expect(linkRes['success'], true);
      expect(linkCalls, 1);

      final unlinkRes = await service.unlinkUser('c100');
      expect(unlinkRes['success'], true);
      expect(unlinkCalls, 1);
    });

    test('10. getCustomerHistory returns parsed CustomerHistoryResult', () async {
      final service = SaasCustomersService(
        apiGet: (path) async {
          expect(path, '/api/saas/customers/c100/history');
          return {
            'attribution_status': 'ATTRIBUTED_VIA_USER_ACCOUNT',
            'count': 1,
            'appointments': [
              {
                'id': 'apt-1',
                'appointment_date': '2026-09-12',
                'start_time': '14:00:00',
                'status': 'CONFIRMED',
                'service_title': 'Manicure Spa',
                'professional_name': 'Diana',
              }
            ]
          };
        },
      );

      final hist = await service.getCustomerHistory('c100');
      expect(hist.isAttributed, true);
      expect(hist.appointments.first.serviceTitle, 'Manicure Spa');
    });
  });

  group('C. CustomerDuplicateModal Widget Tests', () {
    testWidgets('11. Duplicate modal renders candidate comparison and fires callbacks', (tester) async {
      bool usedExisting = false;
      bool createdDistinct = false;
      bool cancelled = false;

      final candidates = [
        const CustomerDuplicateCandidate(
          id: 'c-dup-1',
          firstName: 'Valentina',
          lastName: 'Gómez',
          phone: '+573009998877',
          email: 'valen@example.com',
          status: 'ACTIVE',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerDuplicateModal(
              candidates: candidates,
              onUseExisting: () => usedExisting = true,
              onCreateDistinct: () => createdDistinct = true,
              onCancel: () => cancelled = true,
            ),
          ),
        ),
      );

      expect(find.text('Posible Duplicado'), findsOneWidget);
      expect(find.text('Valentina Gómez'), findsOneWidget);
      expect(find.text('+573009998877'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_duplicate_use_existing')));
      await tester.pump();
      expect(usedExisting, true);

      await tester.tap(find.byKey(const Key('btn_duplicate_create_distinct')));
      await tester.pump();
      expect(createdDistinct, true);

      await tester.tap(find.byKey(const Key('btn_duplicate_cancel')));
      await tester.pump();
      expect(cancelled, true);
    });
  });

  group('D. CustomerTypeahead Widget Tests', () {
    testWidgets('12. Typeahead debounces 400ms and displays search results', (tester) async {
      SaasCustomerSummary? selectedCustomer;

      final service = SaasCustomersService(
        apiGet: (path) async {
          return {
            'data': [
              {
                'id': 'c-search-1',
                'first_name': 'Camila',
                'last_name': 'Duque',
                'phone': '+573112223344',
                'status': 'ACTIVE',
                'is_associated_with_active_establishment': true,
              }
            ]
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomerTypeahead(
              service: service,
              onCustomerSelected: (cust) => selectedCustomer = cust,
            ),
          ),
        ),
      );

      // Typing only 2 chars -> No dropdown
      await tester.enterText(find.byKey(const Key('input_customer_typeahead')), 'ca');
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Camila Duque'), findsNothing);

      // Typing 3+ chars -> Triggers search after 400ms debounce
      await tester.enterText(find.byKey(const Key('input_customer_typeahead')), 'camila');
      await tester.pump(const Duration(milliseconds: 500)); // debounce & async get
      await tester.pump(); // render dropdown

      expect(find.text('Camila Duque'), findsOneWidget);

      // Select candidate
      await tester.tap(find.text('Camila Duque'));
      await tester.pump();

      expect(selectedCustomer?.id, 'c-search-1');
      expect(selectedCustomer?.fullName, 'Camila Duque');
    });
  });

  group('E. CustomerDirectoryScreen (SCR-13) Integration & RBAC Tests', () {
    testWidgets('13. Renders active_context_missing when no active membership in RAM', (tester) async {
      ActiveContextHolder().resetForTesting(); // Ensure null

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerDirectoryScreen(),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('state_active_context_missing')), findsOneWidget);
      expect(find.text('Contexto de Sede Requerido'), findsOneWidget);
    });

    testWidgets('14. Loads directory and displays customer cards for OWNER role', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-owner-1');

      final service = SaasCustomersService(
        apiGet: (path) async {
          if (path.contains('/api/saas/customers')) {
            return {
              'scope': 'establishment',
              'pagination': {'total': 2, 'page': 1, 'limit': 20, 'total_pages': 1},
              'data': [
                {
                  'id': 'c-01',
                  'first_name': 'Sofía',
                  'last_name': 'Vergara',
                  'phone': '+573001234567',
                  'email': 'sofia@example.com',
                  'status': 'ACTIVE',
                  'is_associated_with_active_establishment': true,
                },
                {
                  'id': 'c-02',
                  'first_name': 'Mariana',
                  'last_name': 'Pajón',
                  'phone': '+573009876543',
                  'status': 'INACTIVE',
                  'is_associated_with_active_establishment': false,
                }
              ]
            };
          }
          return {};
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDirectoryScreen(
            service: service,
            initialRole: 'OWNER',
          ),
        ),
      );

      await tester.pump(); // trigger loading
      await tester.pump(); // loaded

      expect(find.text('Sofía Vergara'), findsOneWidget);
      expect(find.text('Mariana Pajón'), findsOneWidget);
      expect(find.text('Otra Sede'), findsOneWidget);

      // RBAC OWNER has scope selector and new customer button
      expect(find.byKey(const Key('dropdown_scope')), findsOneWidget);
      expect(find.byKey(const Key('btn_nuevo_cliente')), findsOneWidget);
    });

    testWidgets('15. RBAC MANAGER role has full management capabilities', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-mgr-1');

      final service = SaasCustomersService(
        apiGet: (path) async {
          return {
            'scope': 'establishment',
            'pagination': {'total': 1, 'page': 1, 'limit': 20, 'total_pages': 1},
            'data': [
              {
                'id': 'c-01',
                'first_name': 'Sofía',
                'last_name': 'Vergara',
                'status': 'ACTIVE',
              }
            ]
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDirectoryScreen(
            service: service,
            initialRole: 'MANAGER',
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('btn_nuevo_cliente')), findsOneWidget);
      expect(find.byKey(const Key('dropdown_scope')), findsOneWidget);
    });

    testWidgets('16. RBAC RECEPTIONIST role allows create but hides tenant scope', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-rec-1');

      final service = SaasCustomersService(
        apiGet: (path) async {
          return {
            'scope': 'establishment',
            'pagination': {'total': 1, 'page': 1, 'limit': 20, 'total_pages': 1},
            'data': [
              {
                'id': 'c-01',
                'first_name': 'Sofía',
                'last_name': 'Vergara',
                'status': 'ACTIVE',
              }
            ]
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDirectoryScreen(
            service: service,
            initialRole: 'RECEPTIONIST',
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      // RECEPTIONIST can create (+ Nuevo is visible)
      expect(find.byKey(const Key('btn_nuevo_cliente')), findsOneWidget);
      // RECEPTIONIST cannot query tenant scope (Scope dropdown is HIDDEN)
      expect(find.byKey(const Key('dropdown_scope')), findsNothing);
    });

    testWidgets('17. RBAC PROFESSIONAL hides mutation buttons and scope selector', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-prof-1');

      final service = SaasCustomersService(
        apiGet: (path) async {
          return {
            'scope': 'establishment',
            'pagination': {'total': 1, 'page': 1, 'limit': 20, 'total_pages': 1},
            'data': [
              {
                'id': 'c-01',
                'first_name': 'Sofía',
                'last_name': 'Vergara',
                'status': 'ACTIVE',
              }
            ]
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDirectoryScreen(
            service: service,
            initialRole: 'PROFESSIONAL',
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Sofía Vergara'), findsOneWidget);
      // Button "+ Nuevo" and Scope dropdown are HIDDEN for PROFESSIONAL
      expect(find.byKey(const Key('btn_nuevo_cliente')), findsNothing);
      expect(find.byKey(const Key('dropdown_scope')), findsNothing);
    });

    testWidgets('18. Opens Customer Detail Dialog and renders tabs', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-owner-1');

      final service = SaasCustomersService(
        apiGet: (path) async {
          if (path.contains('/api/saas/customers/c-01/history')) {
            return {
              'attribution_status': 'UNLINKED_NO_ATTRIBUTED_HISTORY',
              'count': 0,
              'appointments': []
            };
          }
          if (path.contains('/api/saas/customers/c-01')) {
            return {
              'customer': {
                'id': 'c-01',
                'first_name': 'Sofía',
                'last_name': 'Vergara',
                'status': 'ACTIVE',
                'notes': 'Notas globales del cliente',
              },
              'local_establishment': {
                'customer_id': 'c-01',
                'establishment_id': 'est-01',
                'local_notes': 'Notas de la sede',
                'is_active': true,
              }
            };
          }
          return {
            'scope': 'establishment',
            'pagination': {'total': 1, 'page': 1, 'limit': 20, 'total_pages': 1},
            'data': [
              {'id': 'c-01', 'first_name': 'Sofía', 'last_name': 'Vergara', 'status': 'ACTIVE'}
            ]
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDirectoryScreen(
            service: service,
            initialRole: 'OWNER',
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      // Tap on card to open detail
      await tester.tap(find.text('Sofía Vergara'));
      await tester.pumpAndSettle();

      expect(find.text('Canónico'), findsOneWidget);
      expect(find.text('Sede Local'), findsOneWidget);
      expect(find.text('Cuenta B2C'), findsOneWidget);
      expect(find.text('Historial'), findsOneWidget);

      // Verify unlinked history state
      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('state_unlinked_history')), findsOneWidget);
      expect(find.text('Sin Historial Atribuido'), findsOneWidget);

      // Close dialog
      await tester.tap(find.byKey(const Key('btn_close_detail')));
      await tester.pumpAndSettle();
    });

    testWidgets('19. Customer Detail with linked account displays attributed appointments', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-owner-1');

      final service = SaasCustomersService(
        apiGet: (path) async {
          if (path.contains('/api/saas/customers/c-01/history')) {
            return {
              'attribution_status': 'ATTRIBUTED_VIA_USER_ACCOUNT',
              'count': 1,
              'appointments': [
                {
                  'id': 'apt-99',
                  'appointment_date': '2026-09-20',
                  'start_time': '11:00:00',
                  'status': 'CONFIRMED',
                  'service_title': 'Balayage Premium',
                  'professional_name': 'Mateo Estilista',
                }
              ]
            };
          }
          if (path.contains('/api/saas/customers/c-01')) {
            return {
              'customer': {
                'id': 'c-01',
                'user_id': 'u-99',
                'first_name': 'Sofía',
                'last_name': 'Vergara',
                'status': 'ACTIVE',
              },
            };
          }
          return {
            'scope': 'establishment',
            'pagination': {'total': 1, 'page': 1, 'limit': 20, 'total_pages': 1},
            'data': [
              {'id': 'c-01', 'user_id': 'u-99', 'first_name': 'Sofía', 'last_name': 'Vergara', 'status': 'ACTIVE'}
            ]
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDirectoryScreen(
            service: service,
            initialRole: 'OWNER',
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Sofía Vergara'));
      await tester.pumpAndSettle();

      // Go to B2C Tab -> shows linked badge and unlink button
      await tester.tap(find.text('Cuenta B2C'));
      await tester.pumpAndSettle();

      expect(find.text('Cuenta Digital Vinculada'), findsOneWidget);
      expect(find.byKey(const Key('btn_unlink_user')), findsOneWidget);

      // Go to History Tab -> shows appointment
      await tester.tap(find.text('Historial'));
      await tester.pumpAndSettle();

      expect(find.text('Balayage Premium'), findsOneWidget);
      expect(find.text('2026-09-20 11:00:00 • Mateo Estilista'), findsOneWidget);
    });

    testWidgets('20. Error state renders retry button and recovers on retry', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-owner-1');
      bool shouldFail = true;

      final service = SaasCustomersService(
        apiGet: (path) async {
          if (shouldFail) {
            throw Exception('Fallo de conexión al servidor');
          }
          return {
            'scope': 'establishment',
            'pagination': {'total': 1, 'page': 1, 'limit': 20, 'total_pages': 1},
            'data': [
              {'id': 'c-01', 'first_name': 'Cliente', 'last_name': 'Recuperado', 'status': 'ACTIVE'}
            ]
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDirectoryScreen(
            service: service,
            initialRole: 'OWNER',
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('state_error')), findsOneWidget);
      expect(find.text('Error: Fallo de conexión al servidor'), findsOneWidget);

      // Recover
      shouldFail = false;
      await tester.tap(find.byKey(const Key('btn_retry_customers')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Cliente Recuperado'), findsOneWidget);
    });

    testWidgets('21. Empty state renders invitation to create first customer', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-owner-1');

      final service = SaasCustomersService(
        apiGet: (path) async {
          return {
            'scope': 'establishment',
            'pagination': {'total': 0, 'page': 1, 'limit': 20, 'total_pages': 1},
            'data': []
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDirectoryScreen(
            service: service,
            initialRole: 'OWNER',
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('state_empty_customers')), findsOneWidget);
      expect(find.text('No hay clientes registrados'), findsOneWidget);
      expect(find.byKey(const Key('btn_empty_create_customer')), findsOneWidget);
    });

    testWidgets('22. Opens Create Dialog, validates required first_name and creates', (tester) async {
      ActiveContextHolder().setActiveMembershipId('mem-owner-1');
      bool customerCreated = false;

      final service = SaasCustomersService(
        apiGet: (path) async {
          return {
            'scope': 'establishment',
            'pagination': {'total': 0, 'page': 1, 'limit': 20, 'total_pages': 1},
            'data': []
          };
        },
        apiPost: (path, body) async {
          customerCreated = true;
          expect(body['first_name'], 'Andrés');
          return {
            'customer': {'id': 'c-new', 'first_name': 'Andrés', 'status': 'ACTIVE'},
          };
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDirectoryScreen(
            service: service,
            initialRole: 'OWNER',
          ),
        ),
      );

      await tester.pump();
      await tester.pump();

      // Tap + Nuevo
      await tester.tap(find.byKey(const Key('btn_nuevo_cliente')));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Nuevo Cliente'), findsOneWidget);

      // Submit without name -> validation error
      await tester.tap(find.byKey(const Key('btn_submit_create')));
      await tester.pump();
      expect(find.text('El nombre es obligatorio'), findsOneWidget);

      // Enter name and submit
      await tester.enterText(find.byKey(const Key('input_first_name')), 'Andrés');
      await tester.tap(find.byKey(const Key('btn_submit_create')));
      await tester.pumpAndSettle();

      expect(customerCreated, true);
    });
  });
}
