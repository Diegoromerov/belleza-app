// frontend/test/saas_cash_drawer_test.dart
// GO-08.55: SaaS Cash Drawer Frontend Implementation Test Suite

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas/saas_cash_model.dart';
import 'package:beauty_app/services/active_context_holder.dart';
import 'package:beauty_app/services/saas/saas_cash_service.dart';
import 'package:beauty_app/screens/saas/cash_drawer_screen.dart';
import 'package:beauty_app/screens/saas/widgets/cash_drawer_modals.dart';
import 'package:beauty_app/screens/saas/widgets/ticket_payment_modal.dart';
import 'package:beauty_app/screens/saas/saas_navigation_orchestrator.dart';
import 'package:beauty_app/screens/saas/hub_salon_screen.dart';
import 'package:beauty_app/models/saas/ticket_model.dart';
import 'package:beauty_app/services/saas/saas_tickets_service.dart';
import 'package:beauty_app/models/saas/hub_salon_model.dart';
import 'package:beauty_app/services/hub_salon_service.dart';

class MockHubSalonService extends HubSalonService {
  @override
  Future<HubCockpitData> getCockpitData() async {
    return HubCockpitData(
      summary: const HubSummaryResponse(
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
            membershipId: 'mem-01',
            role: 'OWNER',
            relationType: 'PRIMARY',
            status: 'ACTIVE',
          ),
          staffSummary: HubStaffSummary(
            activeMembersCount: 1,
          ),
        ),
      ),
      staff: HubStaffResponse(
        ok: true,
        establishmentId: 'est-01',
        staffCount: 1,
        members: [
          HubStaffMember(
            membershipId: 'mem-01',
            userId: 10,
            userName: 'Carlos Owner',
            userEmail: 'carlos@glow.com',
            role: 'OWNER',
            relationType: 'OWNER_PARTNER',
            status: 'ACTIVE',
            joinedAt: DateTime(2026, 1, 15),
          ),
        ],
      ),
    );
  }
}

class MockSaasCashService extends SaasCashService {
  SaasCashStatusResponse? statusResponse;
  SaasCashHistoryResponse? historyResponse;
  SaasCashSessionDetail? sessionDetail;

  bool shouldFail = false;
  String failureCode = 'ERROR';
  String failureMessage = 'Simulated service error';

  bool openSessionCalled = false;
  double? lastOpeningBalance;
  String? lastOpeningNotes;

  bool addCashInCalled = false;
  String? lastCashInCategory;
  double? lastCashInAmount;
  String? lastCashInReason;

  bool addCashOutCalled = false;
  String? lastCashOutCategory;
  double? lastCashOutAmount;
  String? lastCashOutReason;

  bool closeSessionCalled = false;
  double? lastCountedCash;
  String? lastClosingNotes;

  MockSaasCashService({
    this.statusResponse,
    this.historyResponse,
    this.sessionDetail,
  });

  @override
  Future<SaasCashStatusResponse> getCurrentStatus() async {
    if (shouldFail) {
      throw SaasCashException(message: failureMessage, errorCode: failureCode);
    }
    return statusResponse ??
        SaasCashStatusResponse(
          isOpen: false,
          session: null,
          role: 'OWNER',
        );
  }

  @override
  Future<SaasCashSession> openSession({
    required double openingBalance,
    String? notes,
  }) async {
    if (shouldFail) {
      throw SaasCashException(message: failureMessage, errorCode: failureCode);
    }
    openSessionCalled = true;
    lastOpeningBalance = openingBalance;
    lastOpeningNotes = notes;

    final session = SaasCashSession(
      id: 'session-new-01',
      tenantId: 'tenant-01',
      establishmentId: 'est-01',
      openedByUserId: 10,
      openedByUserName: 'Operador Test',
      status: 'OPEN',
      openedAt: DateTime.now(),
      openingBalance: openingBalance,
      openingNotes: notes,
      expectedCash: openingBalance,
      cashSalesTotal: 0.0,
      cashInTotal: 0.0,
      cashOutTotal: 0.0,
      movements: [
        SaasCashMovement(
          id: 'mov-open-01',
          sessionId: 'session-new-01',
          movementType: 'OPENING',
          amount: openingBalance,
          performedByUserId: 10,
          performedByUserName: 'Operador Test',
          notes: notes,
          createdAt: DateTime.now(),
        ),
      ],
    );

    statusResponse = SaasCashStatusResponse(
      isOpen: true,
      session: session,
      role: 'OWNER',
    );
    return session;
  }

  @override
  Future<SaasCashMovement> addCashIn({
    required String sessionId,
    required String category,
    required double amount,
    required String reason,
    String? notes,
  }) async {
    if (shouldFail) {
      throw SaasCashException(message: failureMessage, errorCode: failureCode);
    }
    addCashInCalled = true;
    lastCashInCategory = category;
    lastCashInAmount = amount;
    lastCashInReason = reason;

    return SaasCashMovement(
      id: 'mov-in-01',
      sessionId: sessionId,
      movementType: 'CASH_IN',
      category: category,
      amount: amount,
      reason: reason,
      notes: notes,
      performedByUserId: 10,
      performedByUserName: 'Operador Test',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<SaasCashMovement> addCashOut({
    required String sessionId,
    required String category,
    required double amount,
    required String reason,
    String? notes,
  }) async {
    if (shouldFail) {
      throw SaasCashException(message: failureMessage, errorCode: failureCode);
    }
    addCashOutCalled = true;
    lastCashOutCategory = category;
    lastCashOutAmount = amount;
    lastCashOutReason = reason;

    return SaasCashMovement(
      id: 'mov-out-01',
      sessionId: sessionId,
      movementType: 'CASH_OUT',
      category: category,
      amount: amount,
      reason: reason,
      notes: notes,
      performedByUserId: 10,
      performedByUserName: 'Operador Test',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<SaasCashReconciliation> closeSession({
    required String sessionId,
    required double countedCash,
    String? notes,
  }) async {
    if (shouldFail) {
      throw SaasCashException(message: failureMessage, errorCode: failureCode);
    }
    closeSessionCalled = true;
    lastCountedCash = countedCash;
    lastClosingNotes = notes;

    final expected = statusResponse?.session?.expectedCash ?? 100.0;
    final diff = countedCash - expected;
    String status = 'BALANCED';
    if (diff > 0.001) status = 'SURPLUS';
    if (diff < -0.001) status = 'SHORTAGE';

    final reconciliation = SaasCashReconciliation(
      sessionId: sessionId,
      status: 'CLOSED',
      reconciliationStatus: status,
      openingBalance: statusResponse?.session?.openingBalance ?? 100.0,
      cashSalesTotal: statusResponse?.session?.cashSalesTotal ?? 0.0,
      cashInTotal: statusResponse?.session?.cashInTotal ?? 0.0,
      cashOutTotal: statusResponse?.session?.cashOutTotal ?? 0.0,
      expectedCash: expected,
      countedCash: countedCash,
      difference: diff,
      notes: notes,
      closedAt: DateTime.now(),
    );

    statusResponse = SaasCashStatusResponse(
      isOpen: false,
      session: null,
      role: 'OWNER',
    );

    return reconciliation;
  }

  @override
  Future<SaasCashHistoryResponse> getHistory({
    int page = 1,
    int limit = 20,
    String? fromDate,
    String? toDate,
  }) async {
    if (shouldFail) {
      throw SaasCashException(message: failureMessage, errorCode: failureCode);
    }
    return historyResponse ??
        SaasCashHistoryResponse(
          items: [],
          total: 0,
          page: page,
          limit: limit,
          totalPages: 1,
        );
  }

  @override
  Future<SaasCashSessionDetail> getSessionDetail(String sessionId) async {
    if (shouldFail) {
      throw SaasCashException(message: failureMessage, errorCode: failureCode);
    }
    return sessionDetail ??
        SaasCashSessionDetail(
          session: SaasCashSession(
            id: sessionId,
            tenantId: 'tenant-01',
            establishmentId: 'est-01',
            openedByUserId: 10,
            openedByUserName: 'Operador Test',
            status: 'CLOSED',
            openedAt: DateTime.now().subtract(const Duration(hours: 8)),
            closedAt: DateTime.now(),
            openingBalance: 100.0,
            expectedCash: 250.0,
            countedCash: 250.0,
            difference: 0.0,
            reconciliationStatus: 'BALANCED',
          ),
          movements: [
            SaasCashMovement(
              id: 'mov-hist-01',
              sessionId: sessionId,
              movementType: 'OPENING',
              amount: 100.0,
              performedByUserId: 10,
              performedByUserName: 'Operador Test',
              createdAt: DateTime.now().subtract(const Duration(hours: 8)),
            ),
            SaasCashMovement(
              id: 'mov-hist-02',
              sessionId: sessionId,
              movementType: 'CASH_SALE',
              amount: 150.0,
              ticketNumber: 'TKT-001',
              performedByUserId: 10,
              performedByUserName: 'Operador Test',
              createdAt: DateTime.now().subtract(const Duration(hours: 4)),
            ),
          ],
        );
  }
}

class MockSaasTicketsServiceForCash extends SaasTicketsService {
  bool shouldThrowCashDrawerNotOpen = false;

  @override
  Future<Map<String, dynamic>> addPayment(
    String ticketId, {
    required String paymentMethod,
    required double amount,
    String? referenceCode,
  }) async {
    if (shouldThrowCashDrawerNotOpen && paymentMethod == 'CASH') {
      throw SaasTicketException(
        message: 'No hay un turno de caja abierto para registrar cobros en efectivo (CASH_DRAWER_NOT_OPEN)',
        errorCode: 'CASH_DRAWER_NOT_OPEN',
      );
    }
    final ticket = SaasServiceTicket(
      id: ticketId,
      tenantId: 1,
      establishmentId: 'est-01',
      ticketNumber: 'TKT-001',
      status: 'PAID',
      clientMode: 'GUEST',
      guestNameSnapshot: 'Cliente Test',
      subtotalAmount: 100.0,
      totalAmount: 100.0,
      paidAmount: 100.0,
      balanceDue: 0.0,
      createdByMembershipId: 'mem-01',
      items: [],
      payments: [
        SaasTicketPayment(
          id: 'pay-01',
          ticketId: ticketId,
          paymentMethod: paymentMethod,
          amount: amount,
          receivedByMembershipId: 'mem-01',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ],
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    return {'ticket': ticket};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ActiveContextHolder contextHolder;

  setUp(() {
    contextHolder = ActiveContextHolder();
    contextHolder.setActiveMembershipId('mem-01');
  });

  tearDown(() {
    contextHolder.resetForTesting();
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('1. DTO & Models Serialization Tests', () {
    test('SaasCashSession fromJson and getters', () {
      final json = {
        'id': 'sess-100',
        'tenant_id': 'tenant-01',
        'establishment_id': 'est-01',
        'opened_by_user_id': 10,
        'opened_by_user_name': 'Carlos Operador',
        'closed_by_user_id': 10,
        'closed_by_user_name': 'Carlos Operador',
        'status': 'OPEN',
        'opened_at': '2026-09-13T10:00:00.000Z',
        'opening_balance': '150.50',
        'opening_notes': 'Base inicial',
        'cash_sales_total': '200.00',
        'cash_in_total': '50.00',
        'cash_out_total': '20.00',
        'expected_cash': '380.50',
        'movements': [
          {
            'id': 'mov-1',
            'session_id': 'sess-100',
            'movement_type': 'OPENING',
            'amount': '150.50',
            'performed_by_user_id': 10,
            'performed_by_user_name': 'Carlos Operador',
            'created_at': '2026-09-13T10:00:00.000Z',
          }
        ],
      };

      final session = SaasCashSession.fromJson(json);
      expect(session.id, equals('sess-100'));
      expect(session.isOpen, isTrue);
      expect(session.isClosed, isFalse);
      expect(session.openingBalance, equals(150.50));
      expect(session.expectedCash, equals(380.50));
      expect(session.movements.length, equals(1));
      expect(session.movements.first.movementType, equals('OPENING'));
    });

    test('SaasCashMovement fromJson with all movement types', () {
      final jsonSale = {
        'id': 'mov-sale-1',
        'session_id': 'sess-100',
        'movement_type': 'CASH_SALE',
        'ticket_id': 'tkt-01',
        'ticket_number': 'TKT-001',
        'payment_id': 'pay-01',
        'amount': '80.00',
        'performed_by_user_id': 10,
        'performed_by_user_name': 'Ana Cajera',
        'created_at': '2026-09-13T11:00:00.000Z',
      };
      final sale = SaasCashMovement.fromJson(jsonSale);
      expect(sale.isCashSale, isTrue);
      expect(sale.ticketNumber, equals('TKT-001'));
      expect(sale.amount, equals(80.00));

      final jsonIn = {
        'id': 'mov-in-1',
        'session_id': 'sess-100',
        'movement_type': 'CASH_IN',
        'category': 'CAMBIO_SENCILLO',
        'amount': '30.00',
        'reason': 'Cambio sencillo de billetes',
        'performed_by_user_id': 10,
        'created_at': '2026-09-13T11:30:00.000Z',
      };
      final cashIn = SaasCashMovement.fromJson(jsonIn);
      expect(cashIn.isCashIn, isTrue);
      expect(cashIn.category, equals('CAMBIO_SENCILLO'));

      final jsonOut = {
        'id': 'mov-out-1',
        'session_id': 'sess-100',
        'movement_type': 'CASH_OUT',
        'category': 'GASTO_MENOR',
        'amount': '15.00',
        'reason': 'Compra de insumos de aseo',
        'performed_by_user_id': 10,
        'created_at': '2026-09-13T12:00:00.000Z',
      };
      final cashOut = SaasCashMovement.fromJson(jsonOut);
      expect(cashOut.isCashOut, isTrue);
      expect(cashOut.category, equals('GASTO_MENOR'));
    });

    test('SaasCashReconciliation fromJson with BALANCED, SURPLUS, SHORTAGE', () {
      final jsonBalanced = {
        'session_id': 'sess-1',
        'status': 'CLOSED',
        'reconciliation_status': 'BALANCED',
        'opening_balance': '100.00',
        'cash_sales_total': '150.00',
        'expected_cash': '250.00',
        'counted_cash': '250.00',
        'difference': '0.00',
        'closed_at': '2026-09-13T18:00:00.000Z',
      };
      final recBalanced = SaasCashReconciliation.fromJson(jsonBalanced);
      expect(recBalanced.isBalanced, isTrue);
      expect(recBalanced.difference, equals(0.0));

      final jsonSurplus = {
        'session_id': 'sess-2',
        'status': 'CLOSED',
        'reconciliation_status': 'SURPLUS',
        'expected_cash': '250.00',
        'counted_cash': '260.00',
        'difference': '10.00',
      };
      final recSurplus = SaasCashReconciliation.fromJson(jsonSurplus);
      expect(recSurplus.isSurplus, isTrue);
      expect(recSurplus.difference, equals(10.0));

      final jsonShortage = {
        'session_id': 'sess-3',
        'status': 'CLOSED',
        'reconciliation_status': 'SHORTAGE',
        'expected_cash': '250.00',
        'counted_cash': '240.00',
        'difference': '-10.00',
      };
      final recShortage = SaasCashReconciliation.fromJson(jsonShortage);
      expect(recShortage.isShortage, isTrue);
      expect(recShortage.difference, equals(-10.0));
    });
  });

  group('2. Initial State & Open Session Modal (SCR-16-M4)', () {
    testWidgets('1 & 2: Renders state_no_open_session and opens CashOpenModal to start session', (tester) async {
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: false, session: null, role: 'OWNER'),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService)));
      await tester.pumpAndSettle();

      // Verifica estado sin sesión abierta
      expect(find.byKey(const Key('state_no_open_session')), findsOneWidget);
      expect(find.byKey(const Key('btn_open_session_modal')), findsOneWidget);
      expect(find.text('No hay un turno de caja abierto'), findsOneWidget);

      // Abre modal de apertura
      await tester.tap(find.byKey(const Key('btn_open_session_modal')));
      await tester.pumpAndSettle();

      expect(find.text('Apertura de Caja'), findsOneWidget);
      expect(find.byKey(const Key('input_opening_balance')), findsOneWidget);

      // Escribe monto inicial y notas
      await tester.enterText(find.byKey(const Key('input_opening_balance')), '250.00');
      await tester.enterText(find.byKey(const Key('input_opening_notes')), 'Apertura turno mañana');
      await tester.tap(find.byKey(const Key('btn_submit_open_session')));
      await tester.pumpAndSettle();

      expect(mockService.openSessionCalled, isTrue);
      expect(mockService.lastOpeningBalance, equals(250.00));
      expect(mockService.lastOpeningNotes, equals('Apertura turno mañana'));

      // Verifica que ahora se renderiza el estado abierto
      expect(find.byKey(const Key('state_open_session')), findsOneWidget);
      expect(find.text('Turno de Caja Abierto'), findsOneWidget);
    });

    testWidgets('3: Conflict error (409) in CashOpenModal displays error banner', (tester) async {
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: false, session: null, role: 'OWNER'),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_open_session_modal')));
      await tester.pumpAndSettle();

      mockService.shouldFail = true;
      mockService.failureCode = 'CASH_DRAWER_ALREADY_OPEN';
      mockService.failureMessage = 'Ya existe un turno de caja abierto para esta sede';

      await tester.enterText(find.byKey(const Key('input_opening_balance')), '100.00');
      await tester.tap(find.byKey(const Key('btn_submit_open_session')));
      await tester.pumpAndSettle();

      expect(find.text('Ya existe un turno de caja abierto para esta sede'), findsOneWidget);
    });
  });

  group('3. Open Session Rendering & Operational Metrics (SCR-16)', () {
    testWidgets('4: Renders open session with metrics and chronological movements', (tester) async {
      final session = SaasCashSession(
        id: 'sess-active-01',
        tenantId: 'tenant-01',
        establishmentId: 'est-01',
        openedByUserId: 10,
        openedByUserName: 'Carlos Owner',
        status: 'OPEN',
        openedAt: DateTime.now().subtract(const Duration(hours: 3)),
        openingBalance: 200.0,
        cashSalesTotal: 150.0,
        cashInTotal: 50.0,
        cashOutTotal: 20.0,
        expectedCash: 380.0,
        movements: [
          SaasCashMovement(
            id: 'mov-1',
            sessionId: 'sess-active-01',
            movementType: 'OPENING',
            amount: 200.0,
            performedByUserName: 'Carlos Owner',
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          SaasCashMovement(
            id: 'mov-2',
            sessionId: 'sess-active-01',
            movementType: 'CASH_SALE',
            amount: 150.0,
            ticketNumber: 'TKT-101',
            performedByUserName: 'Carlos Owner',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
      );

      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: true, session: session, role: 'OWNER'),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('state_open_session')), findsOneWidget);
      expect(find.text('Turno de Caja Abierto'), findsOneWidget);
      expect(find.text('\$200.00'), findsWidgets); // Base inicial
      expect(find.text('\$150.00'), findsWidgets); // Ventas Efectivo
      expect(find.text('\$380.00'), findsWidgets); // Saldo Esperado
      expect(find.text('Folio: TKT-101'), findsOneWidget);
    });
  });

  group('4. Cash In Modal (SCR-16-M1)', () {
    testWidgets('5: Opens CashInModal, selects category, inputs amount and submits successfully', (tester) async {
      final session = SaasCashSession(
        id: 'sess-active-01',
        tenantId: 'tenant-01',
        establishmentId: 'est-01',
        openedByUserId: 10,
        openedByUserName: 'Carlos Owner',
        status: 'OPEN',
        openedAt: DateTime.now(),
        openingBalance: 100.0,
        expectedCash: 100.0,
        movements: [],
      );
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: true, session: session, role: 'OWNER'),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService)));
      await tester.pumpAndSettle();

      // Abrir modal de Ingreso
      await tester.tap(find.byKey(const Key('btn_open_cash_in_modal')));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Ingreso Manual'), findsOneWidget);

      // Seleccionar categoría CAMBIO_SENCILLO
      await tester.tap(find.byKey(const Key('chip_in_CAMBIO_SENCILLO')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('input_cash_in_amount')), '50.00');
      await tester.enterText(find.byKey(const Key('input_cash_in_reason')), 'Monedas de \$1000 y \$500 para cambio');
      await tester.tap(find.byKey(const Key('btn_submit_cash_in')));
      await tester.pumpAndSettle();

      expect(mockService.addCashInCalled, isTrue);
      expect(mockService.lastCashInCategory, equals('CAMBIO_SENCILLO'));
      expect(mockService.lastCashInAmount, equals(50.00));
      expect(mockService.lastCashInReason, equals('Monedas de \$1000 y \$500 para cambio'));
    });
  });

  group('5. Cash Out Modal (SCR-16-M2) & Insufficient Funds', () {
    testWidgets('6: Opens CashOutModal, selects category, inputs amount and submits successfully', (tester) async {
      final session = SaasCashSession(
        id: 'sess-active-01',
        tenantId: 'tenant-01',
        establishmentId: 'est-01',
        openedByUserId: 10,
        openedByUserName: 'Carlos Owner',
        status: 'OPEN',
        openedAt: DateTime.now(),
        openingBalance: 200.0,
        expectedCash: 200.0,
        movements: [],
      );
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: true, session: session, role: 'OWNER'),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService)));
      await tester.pumpAndSettle();

      // Abrir modal de Egreso
      await tester.tap(find.byKey(const Key('btn_open_cash_out_modal')));
      await tester.pumpAndSettle();

      expect(find.text('Registrar Egreso Manual'), findsOneWidget);

      // Seleccionar categoría GASTO_MENOR
      await tester.tap(find.byKey(const Key('chip_out_GASTO_MENOR')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('input_cash_out_amount')), '25.00');
      await tester.enterText(find.byKey(const Key('input_cash_out_reason')), 'Compra de café y agua para recepción');
      await tester.tap(find.byKey(const Key('btn_submit_cash_out')));
      await tester.pumpAndSettle();

      expect(mockService.addCashOutCalled, isTrue);
      expect(mockService.lastCashOutCategory, equals('GASTO_MENOR'));
      expect(mockService.lastCashOutAmount, equals(25.00));
      expect(mockService.lastCashOutReason, equals('Compra de café y agua para recepción'));
    });

    testWidgets('7: Insufficient funds (422 INSUFFICIENT_DRAWER_FUNDS) displays error banner', (tester) async {
      final session = SaasCashSession(
        id: 'sess-active-01',
        tenantId: 'tenant-01',
        establishmentId: 'est-01',
        openedByUserId: 10,
        openedByUserName: 'Carlos Owner',
        status: 'OPEN',
        openedAt: DateTime.now(),
        openingBalance: 50.0,
        expectedCash: 50.0,
        movements: [],
      );
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: true, session: session, role: 'OWNER'),
      );
      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_open_cash_out_modal')));
      await tester.pumpAndSettle();

      mockService.shouldFail = true;
      mockService.failureCode = 'INSUFFICIENT_DRAWER_FUNDS';
      mockService.failureMessage = 'Fondos insuficientes en caja para realizar el retiro solicitado';

      await tester.enterText(find.byKey(const Key('input_cash_out_amount')), '100.00');
      await tester.enterText(find.byKey(const Key('input_cash_out_reason')), 'Retiro mayor a saldo');
      await tester.tap(find.byKey(const Key('btn_submit_cash_out')));
      await tester.pumpAndSettle();

      expect(find.text('Fondos insuficientes en caja para realizar el retiro solicitado'), findsOneWidget);
    });
  });

  group('6. Blind Close & Expected Cash RBAC Rules', () {
    testWidgets('9: Blind Close for RECEPTIONIST: expected_cash is null/masked and not visible in close modal', (tester) async {
      final session = SaasCashSession(
        id: 'sess-rec-01',
        tenantId: 'tenant-01',
        establishmentId: 'est-01',
        openedByUserId: 20,
        openedByUserName: 'Recepcionista Turno',
        status: 'OPEN',
        openedAt: DateTime.now(),
        openingBalance: 100.0,
        cashSalesTotal: 100.0,
        cashInTotal: 0.0,
        cashOutTotal: 0.0,
        expectedCash: null, // Blind close por backend
        movements: [],
      );
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: true, session: session, role: 'RECEPTIONIST'),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService, initialRole: 'RECEPTIONIST')));
      await tester.pumpAndSettle();

      // Verifica que no se muestra el valor numérico en el card de métricas
      expect(find.text('--- (Cierre Ciego)'), findsOneWidget);

      // Abre diálogo de cierre
      await tester.tap(find.byKey(const Key('btn_open_close_session_modal')));
      await tester.pumpAndSettle();

      expect(find.text('Cierre de Turno de Caja'), findsOneWidget);
      // El modal solo pide efectivo contado físicamente
      expect(find.byKey(const Key('input_counted_cash')), findsOneWidget);
      // No existe ningún texto que revele el saldo esperado
      expect(find.textContaining('Esperado:'), findsNothing);
    });

    testWidgets('10: Live expected cash is visible for OWNER / MANAGER', (tester) async {
      final session = SaasCashSession(
        id: 'sess-mgr-01',
        tenantId: 'tenant-01',
        establishmentId: 'est-01',
        openedByUserId: 10,
        openedByUserName: 'Manager Test',
        status: 'OPEN',
        openedAt: DateTime.now(),
        openingBalance: 150.0,
        cashSalesTotal: 250.0,
        cashInTotal: 0.0,
        cashOutTotal: 50.0,
        expectedCash: 350.0,
        movements: [],
      );
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: true, session: session, role: 'MANAGER'),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService, initialRole: 'MANAGER')));
      await tester.pumpAndSettle();

      expect(find.text('\$350.00'), findsWidgets);
    });
  });

  group('7. Close Session & Reconciliation Summary Dialog (SCR-16-M3)', () {
    testWidgets('11: Close BALANCED session displays Caja Cuadrada reconciliation summary', (tester) async {
      final session = SaasCashSession(
        id: 'sess-close-01',
        tenantId: 'tenant-01',
        establishmentId: 'est-01',
        openedByUserId: 10,
        openedByUserName: 'Carlos Owner',
        status: 'OPEN',
        openedAt: DateTime.now(),
        openingBalance: 100.0,
        expectedCash: 200.0,
        movements: [],
      );
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: true, session: session, role: 'OWNER'),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_open_close_session_modal')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('input_counted_cash')), '200.00');
      await tester.tap(find.byKey(const Key('btn_submit_close_session')));
      await tester.pumpAndSettle();

      expect(mockService.closeSessionCalled, isTrue);
      expect(mockService.lastCountedCash, equals(200.00));

      // Modal de conciliación
      expect(find.text('Resumen de Cierre y Conciliación'), findsOneWidget);
      expect(find.text('Caja Cuadrada'), findsOneWidget);
      expect(find.text('El efectivo contado coincide exactamente con el saldo esperado.'), findsOneWidget);
    });

    testWidgets('12: Close SURPLUS session displays Sobrante de Caja reconciliation summary', (tester) async {
      final session = SaasCashSession(
        id: 'sess-close-02',
        tenantId: 'tenant-01',
        establishmentId: 'est-01',
        openedByUserId: 10,
        openedByUserName: 'Carlos Owner',
        status: 'OPEN',
        openedAt: DateTime.now(),
        openingBalance: 100.0,
        expectedCash: 200.0,
        movements: [],
      );
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: true, session: session, role: 'OWNER'),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_open_close_session_modal')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('input_counted_cash')), '215.00');
      await tester.tap(find.byKey(const Key('btn_submit_close_session')));
      await tester.pumpAndSettle();

      expect(find.text('Sobrante de Caja'), findsOneWidget);
      expect(find.text('+\$15.00'), findsOneWidget);
    });

    testWidgets('13: Close SHORTAGE session displays Faltante de Caja reconciliation summary', (tester) async {
      final session = SaasCashSession(
        id: 'sess-close-03',
        tenantId: 'tenant-01',
        establishmentId: 'est-01',
        openedByUserId: 10,
        openedByUserName: 'Carlos Owner',
        status: 'OPEN',
        openedAt: DateTime.now(),
        openingBalance: 100.0,
        expectedCash: 200.0,
        movements: [],
      );
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: true, session: session, role: 'OWNER'),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('btn_open_close_session_modal')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('input_counted_cash')), '185.00');
      await tester.tap(find.byKey(const Key('btn_submit_close_session')));
      await tester.pumpAndSettle();

      expect(find.text('Faltante de Caja'), findsOneWidget);
      expect(find.text('-\$15.00'), findsOneWidget);
    });
  });

  group('8. Cash Sale Movement Presentation', () {
    testWidgets('8: Displays CASH_SALE movement with folio and amount without manual sale action', (tester) async {
      final session = SaasCashSession(
        id: 'sess-sale-01',
        tenantId: 'tenant-01',
        establishmentId: 'est-01',
        openedByUserId: 10,
        openedByUserName: 'Carlos Owner',
        status: 'OPEN',
        openedAt: DateTime.now(),
        openingBalance: 100.0,
        cashSalesTotal: 75.0,
        expectedCash: 175.0,
        movements: [
          SaasCashMovement(
            id: 'mov-sale-99',
            sessionId: 'sess-sale-01',
            movementType: 'CASH_SALE',
            ticketNumber: 'TKT-888',
            amount: 75.0,
            performedByUserName: 'Carlos Owner',
            createdAt: DateTime.now(),
          ),
        ],
      );
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: true, session: session, role: 'OWNER'),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService)));
      await tester.pumpAndSettle();

      expect(find.text('Cobro de Venta (POS)'), findsOneWidget);
      expect(find.text('Folio: TKT-888'), findsOneWidget);
      expect(find.text('+\$75.00'), findsOneWidget);

      // Verificamos que los únicos botones de movimiento manual son Ingreso y Egreso
      expect(find.byKey(const Key('btn_open_cash_in_modal')), findsOneWidget);
      expect(find.byKey(const Key('btn_open_cash_out_modal')), findsOneWidget);
    });
  });

  group('9. History Tab & Session Detail (SCR-16-DETAIL)', () {
    testWidgets('14: History Tab is visible for OWNER/MANAGER and hidden for RECEPTIONIST', (tester) async {
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: false, session: null, role: 'RECEPTIONIST'),
      );

      // Como RECEPTIONIST
      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService, initialRole: 'RECEPTIONIST')));
      await tester.pumpAndSettle();

      // No debe existir el TabBar con Histórico
      expect(find.text('Histórico de Turnos'), findsNothing);

      // Como OWNER
      mockService.statusResponse = SaasCashStatusResponse(isOpen: false, session: null, role: 'OWNER');
      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService, initialRole: 'OWNER')));
      await tester.pumpAndSettle();

      expect(find.text('Histórico de Turnos'), findsOneWidget);
    });

    testWidgets('15: Tapping historical session opens SessionDetailDialog (SCR-16-DETAIL)', (tester) async {
      final historyItem = SaasCashSession(
        id: 'sess-hist-999',
        tenantId: 'tenant-01',
        establishmentId: 'est-01',
        openedByUserId: 10,
        openedByUserName: 'Carlos Owner',
        closedByUserName: 'Carlos Owner',
        status: 'CLOSED',
        openedAt: DateTime.now().subtract(const Duration(days: 1)),
        closedAt: DateTime.now().subtract(const Duration(days: 1, hours: -8)),
        openingBalance: 100.0,
        cashSalesTotal: 200.0,
        expectedCash: 300.0,
        countedCash: 300.0,
        difference: 0.0,
        reconciliationStatus: 'BALANCED',
      );

      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: false, session: null, role: 'OWNER'),
        historyResponse: SaasCashHistoryResponse(
          items: [historyItem],
          total: 1,
          page: 1,
          limit: 20,
          totalPages: 1,
        ),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService, initialRole: 'OWNER')));
      await tester.pumpAndSettle();

      // Cambiar al tab de histórico
      await tester.tap(find.text('Histórico de Turnos'));
      await tester.pumpAndSettle();

      expect(find.textContaining('sess-his'), findsOneWidget);

      // Tocar el item de histórico para abrir detalle
      await tester.tap(find.byKey(const Key('btn_ver_detalle_sess-hist-999')));
      await tester.pumpAndSettle();

      expect(find.text('Detalle de Turno de Caja'), findsOneWidget);
      expect(find.text('Movimientos del Turno'), findsOneWidget);
    });
  });

  group('10. RBAC Access Denial for PROFESSIONAL', () {
    testWidgets('16: Access is blocked for PROFESSIONAL role with 403 Forbidden card', (tester) async {
      final mockService = MockSaasCashService(
        statusResponse: SaasCashStatusResponse(isOpen: false, session: null, role: 'PROFESSIONAL'),
      );

      await tester.pumpWidget(createTestWidget(CashDrawerScreen(service: mockService, initialRole: 'PROFESSIONAL')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('state_cash_forbidden_role')), findsOneWidget);
      expect(find.text('Acceso Restringido a Caja'), findsOneWidget);
    });
  });

  group('11. Hub Integration & Navigation Orchestrator', () {
    testWidgets('HubSalonScreen renders btn_modulo_caja and triggers navigation', (tester) async {
      bool cashNavTriggered = false;

      await tester.pumpWidget(createTestWidget(
        HubSalonScreen(
          service: MockHubSalonService(),
          onNavigateToCashDrawer: () {
            cashNavTriggered = true;
          },
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('btn_modulo_caja')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('btn_modulo_caja')));
      await tester.tap(find.byKey(const Key('btn_modulo_caja')));
      await tester.pumpAndSettle();

      expect(cashNavTriggered, isTrue);
    });
  });

  group('12. POS Checkout Integration on CASH_DRAWER_NOT_OPEN', () {
    testWidgets('TicketPaymentModal handles CASH_DRAWER_NOT_OPEN with direct redirect button', (tester) async {
      final mockTicketsService = MockSaasTicketsServiceForCash();
      mockTicketsService.shouldThrowCashDrawerNotOpen = true;

      bool navigatedToCashDrawer = false;

      final ticket = SaasServiceTicket(
        id: 'tkt-pos-01',
        tenantId: 1,
        establishmentId: 'est-01',
        ticketNumber: 'TKT-999',
        status: 'OPEN',
        clientMode: 'GUEST',
        guestNameSnapshot: 'Cliente Mostrador',
        subtotalAmount: 100.0,
        totalAmount: 100.0,
        paidAmount: 0.0,
        balanceDue: 100.0,
        createdByMembershipId: 'mem-01',
        items: [],
        payments: [],
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await tester.pumpWidget(createTestWidget(
        TicketPaymentModal(
          ticket: ticket,
          service: mockTicketsService,
          onPaymentCompleted: (_) {},
          onNavigateToCashDrawer: () {
            navigatedToCashDrawer = true;
          },
        ),
      ));
      await tester.pumpAndSettle();

      // Submit CASH payment
      await tester.tap(find.byKey(const Key('btn_submit_payment')));
      await tester.pumpAndSettle();

      // Botón de redirección directo a caja
      expect(find.byKey(const Key('btn_ir_a_caja_desde_error')), findsOneWidget);
      expect(find.text('Ir a Gestión de Caja (SCR-16)'), findsOneWidget);

      await tester.tap(find.byKey(const Key('btn_ir_a_caja_desde_error')));
      await tester.pumpAndSettle();

      expect(navigatedToCashDrawer, isTrue);
    });
  });
}
