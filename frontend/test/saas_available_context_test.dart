// frontend/test/saas_available_context_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/models/saas/available_context_model.dart';
import 'package:beauty_app/screens/saas/available_context_selector_screen.dart';
import 'package:beauty_app/services/active_context_holder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String membership1 = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d';
  const String membership2 = 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e';

  final sampleOneContextResponse = AvailableContextResponse(
    resolutionStatus: 'ONE_CONTEXT',
    availableContextsCount: 1,
    availableContexts: [
      const AvailableContextItem(
        membershipId: membership1,
        organizationLegalName: 'Glow Hair S.A.S.',
        establishmentName: 'Sede Chicó Norte',
        establishmentSlug: 'sede-chico-norte',
        establishmentIsActive: true,
        role: 'PROFESIONAL',
        relationType: 'EMPLOYEE',
        tenantName: 'Glow Hair Salon Group',
      ),
    ],
  );

  final sampleMultipleContextsResponse = AvailableContextResponse(
    resolutionStatus: 'MULTIPLE_CONTEXTS',
    availableContextsCount: 2,
    availableContexts: [
      const AvailableContextItem(
        membershipId: membership1,
        organizationLegalName: 'Glow Hair S.A.S.',
        establishmentName: 'Sede Chicó Norte',
        establishmentSlug: 'sede-chico-norte',
        establishmentIsActive: true,
        role: 'PROFESIONAL',
        relationType: 'EMPLOYEE',
        tenantName: 'Glow Hair Salon Group',
      ),
      const AvailableContextItem(
        membershipId: membership2,
        organizationLegalName: 'Glow Hair S.A.S.',
        establishmentName: 'Sede Usaquén Plaza',
        establishmentSlug: 'sede-usaquen-plaza',
        establishmentIsActive: true,
        role: 'ADMIN',
        relationType: 'EMPLOYEE',
        tenantName: 'Glow Hair Salon Group',
      ),
    ],
  );

  final sampleNoContextResponse = const AvailableContextResponse(
    resolutionStatus: 'NO_CONTEXT',
    availableContextsCount: 0,
    availableContexts: [],
  );

  setUp(() {
    ActiveContextHolder().resetForTesting();
  });

  tearDown(() {
    ActiveContextHolder().resetForTesting();
  });

  group('NODO-07 FASE 3 — AvailableContextModel / DTO Tests', () {
    test('A. JSON parsing correcto del backend payload real', () {
      final jsonPayload = {
        'status': 'success',
        'data': {
          'resolution_status': 'MULTIPLE_CONTEXTS',
          'identity_id': 101,
          'tenant_id': 1,
          'available_contexts_count': 2,
          'available_contexts': [
            {
              'membership_id': membership1,
              'tenant_id': 1,
              'tenant_name': 'Glow Hair Salon Group',
              'organization_id': 'org-uuid-1',
              'organization_legal_name': 'Glow Hair S.A.S.',
              'establishment_id': 'est-uuid-1',
              'establishment_name': 'Sede Chicó Norte',
              'establishment_slug': 'sede-chico-norte',
              'establishment_is_active': true,
              'role': 'PROFESIONAL',
              'relation_type': 'EMPLOYEE',
              'membership_status': 'ACTIVE',
            },
            {
              'membership_id': membership2,
              'tenant_id': 1,
              'tenant_name': 'Glow Hair Salon Group',
              'organization_id': 'org-uuid-1',
              'organization_legal_name': 'Glow Hair S.A.S.',
              'establishment_id': 'est-uuid-2',
              'establishment_name': 'Sede Usaquén Plaza',
              'establishment_slug': 'sede-usaquen-plaza',
              'establishment_is_active': true,
              'role': 'ADMIN',
              'relation_type': 'EMPLOYEE',
              'membership_status': 'ACTIVE',
            }
          ]
        }
      };

      final response = AvailableContextResponse.fromJson(jsonPayload);
      expect(response.resolutionStatus, equals('MULTIPLE_CONTEXTS'));
      expect(response.availableContextsCount, equals(2));
      expect(response.availableContexts.length, equals(2));
      expect(response.isMultipleContexts, isTrue);
      expect(response.isOneContext, isFalse);
      expect(response.isNoContext, isFalse);

      final item1 = response.availableContexts.first;
      expect(item1.membershipId, equals(membership1));
      expect(item1.establishmentName, equals('Sede Chicó Norte'));
      expect(item1.role, equals('PROFESIONAL'));
      expect(item1.organizationLegalName, equals('Glow Hair S.A.S.'));
      expect(item1.establishmentIsActive, isTrue);
    });

    test('B. NO_CONTEXT flags mapping', () {
      expect(sampleNoContextResponse.isNoContext, isTrue);
      expect(sampleNoContextResponse.isOneContext, isFalse);
      expect(sampleNoContextResponse.isMultipleContexts, isFalse);
    });

    test('C. ONE_CONTEXT flags mapping', () {
      expect(sampleOneContextResponse.isOneContext, isTrue);
      expect(sampleOneContextResponse.isNoContext, isFalse);
      expect(sampleOneContextResponse.isMultipleContexts, isFalse);
    });

    test('D. MULTIPLE_CONTEXTS flags mapping', () {
      expect(sampleMultipleContextsResponse.isMultipleContexts, isTrue);
      expect(sampleMultipleContextsResponse.isOneContext, isFalse);
      expect(sampleMultipleContextsResponse.isNoContext, isFalse);
    });
  });

  group('NODO-07 FASE 3 — AvailableContextSelectorScreen Widget & State Tests', () {
    testWidgets('E & F. ONE_CONTEXT: DEC-N07-AC-001 — Carga NO auto-selecciona (ActiveContext permanece null)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AvailableContextSelectorScreen(
            contextLoader: () async => sampleOneContextResponse,
          ),
        ),
      );

      // Esperar resolución del Future
      await tester.pumpAndSettle();

      // Verificar que se renderiza la UI de sede única
      expect(find.text('Sede Asignada'), findsOneWidget);
      expect(find.text('Sede Chicó Norte'), findsOneWidget);
      expect(find.text('PROFESIONAL'), findsOneWidget);
      expect(find.byKey(const Key('btn_ingresar_sede_unica')), findsOneWidget);

      // 🛡️ REGLA DEC-N07-AC-001: ActiveContextHolder DEBE permanecer null
      expect(ActiveContextHolder().activeMembershipId, isNull);
      expect(ActiveContextHolder().hasActiveContext, isFalse);
    });

    testWidgets('H. ONE_CONTEXT: Acción explícita fija membership_id y notifica callback', (tester) async {
      AvailableContextItem? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: AvailableContextSelectorScreen(
            contextLoader: () async => sampleOneContextResponse,
            onContextSelected: (item) {
              selectedItem = item;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(ActiveContextHolder().activeMembershipId, isNull);

      // Usuario presiona explícitamente el botón "INGRESAR A ESTA SEDE"
      await tester.tap(find.byKey(const Key('btn_ingresar_sede_unica')));
      await tester.pumpAndSettle();

      // Verificar que tras la acción explícita SÍ se fija en memoria
      expect(ActiveContextHolder().activeMembershipId, equals(membership1));
      expect(ActiveContextHolder().hasActiveContext, isTrue);
      expect(selectedItem?.membershipId, equals(membership1));
    });

    testWidgets('G. MULTIPLE_CONTEXTS: Carga NO auto-selecciona', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AvailableContextSelectorScreen(
            contextLoader: () async => sampleMultipleContextsResponse,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Selecciona tu Sede Operativa'), findsOneWidget);
      expect(find.text('Sede Chicó Norte'), findsOneWidget);
      expect(find.text('Sede Usaquén Plaza'), findsOneWidget);

      // ActiveContextHolder DEBE permanecer null
      expect(ActiveContextHolder().activeMembershipId, isNull);
      expect(ActiveContextHolder().hasActiveContext, isFalse);
    });

    testWidgets('I. MULTIPLE_CONTEXTS: Tocar tarjeta fija explícitamente el membership_id seleccionado', (tester) async {
      AvailableContextItem? selectedItem;

      await tester.pumpWidget(
        MaterialApp(
          home: AvailableContextSelectorScreen(
            contextLoader: () async => sampleMultipleContextsResponse,
            onContextSelected: (item) {
              selectedItem = item;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(ActiveContextHolder().activeMembershipId, isNull);

      // Usuario selecciona explícitamente la segunda sede (Usaquén)
      await tester.tap(find.byKey(Key('card_membership_$membership2')));
      await tester.pumpAndSettle();

      expect(ActiveContextHolder().activeMembershipId, equals(membership2));
      expect(ActiveContextHolder().hasActiveContext, isTrue);
      expect(selectedItem?.membershipId, equals(membership2));
    });

    testWidgets('J. NO_CONTEXT: Renderiza vista informativa y nunca fija ActiveContextHolder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AvailableContextSelectorScreen(
            contextLoader: () async => sampleNoContextResponse,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sin Sedes Asignadas'), findsOneWidget);
      expect(find.text('Crear Salón Desde Cero (Fase 4)'), findsOneWidget);

      // ActiveContextHolder DEBE permanecer null
      expect(ActiveContextHolder().activeMembershipId, isNull);
      expect(ActiveContextHolder().hasActiveContext, isFalse);
    });

    testWidgets('K. ERROR: Renderiza vista de error y permite reintentar', (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: AvailableContextSelectorScreen(
            contextLoader: () async {
              callCount++;
              if (callCount == 1) {
                throw Exception('Fallo de red simulado');
              }
              return sampleOneContextResponse;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Error consultando sedes'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(ActiveContextHolder().activeMembershipId, isNull);

      // Pulsa reintentar
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('Sede Asignada'), findsOneWidget);
      expect(find.text('Sede Chicó Norte'), findsOneWidget);
      expect(callCount, equals(2));
    });
  });
}
