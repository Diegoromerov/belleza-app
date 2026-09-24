// frontend/test/saas_navigation_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/screens/saas/saas_navigation_orchestrator.dart';
import 'package:beauty_app/screens/saas/hub_salon_screen.dart';
import 'package:beauty_app/screens/saas/available_context_selector_screen.dart';
import 'package:beauty_app/models/saas/available_context_model.dart';
import 'package:beauty_app/services/hub_salon_service.dart';
import 'package:beauty_app/services/active_context_holder.dart';
import 'package:beauty_app/screens/provider_dashboard_screen.dart';
import 'package:beauty_app/screens/auth/login_screen.dart';
import 'package:beauty_app/screens/auth/register_screen.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const String sampleMembership = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d';

  final sampleSummaryPayload = {
    'ok': true,
    'summary': {
      'establishment': {
        'id': 'est-1',
        'name': 'Salón Demo',
        'slug': 'salon-demo',
        'is_active': true,
      },
      'organization': {
        'id': 'org-1',
        'legal_name': 'Org Demo',
      },
      'active_user_context': {
        'membership_id': sampleMembership,
        'role': 'OWNER',
        'relation_type': 'PRIMARY',
        'status': 'ACTIVE',
      },
      'staff_summary': {
        'active_members_count': 1,
        'has_schedule_configured': true,
      },
      'services_summary': {
        'active_services_count': 2,
      },
    },
  };

  final sampleStaffPayload = {
    'ok': true,
    'staff': [
      {
        'membership_id': sampleMembership,
        'user_id': 'user-1',
        'first_name': 'Admin',
        'last_name': 'Glow',
        'role': 'OWNER',
        'relation_type': 'PRIMARY',
        'status': 'ACTIVE',
        'is_active': true,
      }
    ],
  };

  setUp(() {
    ActiveContextHolder().resetForTesting();
  });

  tearDown(() {
    ActiveContextHolder().resetForTesting();
  });

  group('NODO-07 FASE 5 — SaaS Navigation & Route Integration Tests', () {
    test('A. Verificación estática: main.dart registra la ruta /saas/hub y su import canónico', () {
      final mainFile = File('lib/main.dart');
      expect(mainFile.existsSync(), isTrue, reason: 'main.dart debe existir');
      
      final content = mainFile.readAsStringSync();

      // 1. Verificar import
      expect(
        content.contains("import 'screens/saas/saas_navigation_orchestrator.dart';"),
        isTrue,
        reason: 'main.dart debe importar SaasNavigationOrchestrator',
      );

      // 2. Verificar registro de ruta
      expect(
        content.contains("'/saas/hub': (_) => const SaasNavigationOrchestrator(),"),
        isTrue,
        reason: "main.dart debe registrar la ruta '/saas/hub' con SaasNavigationOrchestrator",
      );

      // 3. Verificar que initialRoute permanece en /home
      expect(
        content.contains("initialRoute: '/home'"),
        isTrue,
        reason: "initialRoute debe permanecer inalterada en '/home'",
      );

      // 4. Verificar que /saas/context/available NO está registrada como ruta nombrada (No Route Without Consumer)
      expect(
        content.contains("'/saas/context/available'"),
        isFalse,
        reason: "Regla No Route Without Consumer: /saas/context/available NO debe registrarse en main.dart",
      );
    });

    testWidgets('B. La ruta /saas/hub resuelve y monta SaasNavigationOrchestrator / HubSalonScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/home',
          routes: {
            '/home': (_) => const Scaffold(body: Text('Home Screen')),
            '/saas/hub': (_) => const SaasNavigationOrchestrator(),
          },
        ),
      );

      final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
      navigatorState.pushNamed('/saas/hub');
      await tester.pumpAndSettle();

      expect(find.byType(SaasNavigationOrchestrator), findsOneWidget);
      expect(find.byType(HubSalonScreen), findsOneWidget);
    });

    testWidgets('C & D. La ruta /saas/hub no muta, no crea ni persiste ActiveContextHolder al instanciarse', (tester) async {
      // Estado inicial: null
      expect(ActiveContextHolder().activeMembershipId, isNull);
      expect(ActiveContextHolder().hasActiveContext, isFalse);

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/saas/hub',
          routes: {
            '/saas/hub': (_) => const HubSalonScreen(),
          },
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que ActiveContextHolder sigue en null
      expect(ActiveContextHolder().activeMembershipId, isNull);
      expect(ActiveContextHolder().hasActiveContext, isFalse);

      // Verificar que HubSalonScreen presenta su estado active_context_missing
      expect(find.text('Contexto de Salón No Seleccionado'), findsOneWidget);
      expect(find.byKey(const Key('btn_seleccionar_contexto_missing')), findsOneWidget);
    });

    testWidgets('E. Regla No Route Without Consumer: /saas/context/available no está registrada', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/saas/hub',
          routes: {
            '/saas/hub': (_) => const HubSalonScreen(),
          },
        ),
      );

      final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));

      expect(
        () => navigatorState.pushNamed('/saas/context/available'),
        throwsFlutterError,
      );
    });

    testWidgets('F. Rutas B2C existentes permanecen funcionales e instanciables', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/home',
          routes: {
            '/home': (_) => const Scaffold(body: Text('Providers Screen')),
            '/provider': (_) => const ProviderDashboardScreen(),
            '/saas/hub': (_) => const HubSalonScreen(),
          },
        ),
      );

      final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
      expect(find.text('Providers Screen'), findsOneWidget);

      navigatorState.pushNamed('/provider');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ProviderDashboardScreen), findsOneWidget);
    });

    testWidgets('G. Rutas Auth existentes permanecen funcionales e instanciables', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/login',
          routes: {
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/saas/hub': (_) => const HubSalonScreen(),
          },
        ),
      );

      final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
      expect(find.byType(LoginScreen), findsOneWidget);

      navigatorState.pushNamed('/register');
      await tester.pumpAndSettle();
      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('H. Flujo Completo: AvailableContextSelector navega a /saas/hub tras selección explícita', (tester) async {
      const sampleResponse = AvailableContextResponse(
        resolutionStatus: 'ONE_CONTEXT',
        availableContextsCount: 1,
        availableContexts: [
          AvailableContextItem(
            membershipId: sampleMembership,
            organizationLegalName: 'Beauty Corp S.A.S.',
            establishmentName: 'Sede Principal',
            establishmentSlug: 'sede-principal',
            establishmentIsActive: true,
            role: 'PROFESSIONAL',
            relationType: 'EMPLOYEE',
            tenantName: 'Beauty Group',
          ),
        ],
      );

      final mockHubService = HubSalonService(
        apiGet: (path) async {
          if (path == '/api/v1/saas/hub/summary') return sampleSummaryPayload;
          if (path == '/api/v1/saas/hub/staff') return sampleStaffPayload;
          throw Exception('Ruta desconocida');
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: '/selector',
          routes: {
            '/selector': (_) => AvailableContextSelectorScreen(
                  contextLoader: () async => sampleResponse,
                ),
            '/saas/hub': (_) => HubSalonScreen(service: mockHubService),
          },
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que estamos en el selector
      expect(find.text('Sede Asignada'), findsOneWidget);
      expect(find.byKey(const Key('btn_ingresar_sede_unica')), findsOneWidget);
      expect(ActiveContextHolder().activeMembershipId, isNull);

      // Acción explícita de usuario
      await tester.tap(find.byKey(const Key('btn_ingresar_sede_unica')));
      await tester.pumpAndSettle();

      // Verificar que el contexto activo se fijó en RAM
      expect(ActiveContextHolder().activeMembershipId, equals(sampleMembership));

      // Verificar que pushReplacementNamed navegó exitosamente al HubSalonScreen
      expect(find.byType(HubSalonScreen), findsOneWidget);
      expect(find.text('Salón Demo'), findsOneWidget);
    });
  });
}
