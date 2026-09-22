import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beauty_app/models/business_profile_model.dart';
import 'package:beauty_app/screens/provider/business/business_dashboard_screen.dart';
import 'package:beauty_app/screens/provider/business/business_task_detail_screen.dart';
import 'package:beauty_app/services/business_api_service.dart';

/// GATE 3 — ninguna pantalla del Business Center muestra datos de un negocio que
/// no venga del servidor.
///
/// Se inyecta un doble del servicio para forzar cada escenario de forma
/// determinista (el cliente HTTP real está deshabilitado dentro de
/// `flutter_test`, así que depender del entorno no probaría nada: la pantalla se
/// quedaba en el spinner).
///
/// Se comprueba, uno por uno, que NO aparece nada de lo que estas pantallas
/// inventaban antes:
///   dashboard: 'Mi Peluquería Studio', puntaje 0.65, etapa, 3 tareas, 1 hallazgo
///   detalle  : 'Concepto Sanitario', 'Ley 9 de 1979 / Decreto 1879',
///              'Certificado_Sanitario_2026.pdf', 'Aura sugiere: ...'

class _ApiCaida extends BusinessApiService {
  _ApiCaida() : super();

  @override
  Future<Map<String, dynamic>> fetchBusinessSummary() async {
    throw Exception('backend apagado');
  }
}

class _ApiSinExpediente extends BusinessApiService {
  _ApiSinExpediente() : super();

  @override
  Future<Map<String, dynamic>> fetchBusinessSummary() async {
    throw Exception('Failed to fetch business summary: 404');
  }
}

class _ApiConDatos extends BusinessApiService {
  _ApiConDatos() : super();

  @override
  Future<Map<String, dynamic>> fetchBusinessSummary() async => {
        'profile': {
          'id': 'perfil-real-1',
          'provider_id': 74,
          'name': 'Salón de Ana',
          'onboarding_mode': 'EXISTING_BUSINESS',
          'lifecycle_stage': 'OPERATION',
          'compliance_score': 72.5,
          'city': 'Cali',
          'country': 'Colombia',
        },
        'tasks': [
          {
            'id': 'task-1',
            'business_profile_id': 'perfil-real-1',
            'requirement_id': 'req-1',
            'title': 'Renovar matrícula mercantil',
            'description': 'Antes del 31 de marzo.',
            'stage': 'EXPLICAR',
            'status': 'EN PROCESO',
          },
        ],
        'findings': [
          {
            'id': 'f-1',
            'business_profile_id': 'perfil-real-1',
            'title': 'Falta concepto sanitario',
            'description': 'Vence el 2 de marzo.',
            'risk_level': 'HIGH',
            'status': 'OPEN',
          },
        ],
      };
}

void _noInventaNada() {
  expect(find.text('Mi Peluquería Studio'), findsNothing);
  expect(find.text('Salón Elegance Studio'), findsNothing);
  expect(find.text('0.65'), findsNothing);
  expect(find.textContaining('Concepto Sanitario'), findsNothing);
  expect(find.textContaining('Aura sugiere'), findsNothing);
  expect(find.textContaining('Certificado_Sanitario'), findsNothing);
}

void main() {
  group('Gate 3 — Business Center sin datos inventados', () {
    testWidgets('backend caído: informa el fallo y no pinta ningún negocio',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: BusinessDashboardScreen(api: _ApiCaida())));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('No se pudo cargar'), findsOneWidget);
      expect(find.text('Hacer el diagnóstico'), findsOneWidget);
      expect(find.text('Ruta de Trámites & Tareas Guiadas'), findsNothing);
      _noInventaNada();
    });

    testWidgets('sin expediente (404): lo dice y ofrece el diagnóstico',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: BusinessDashboardScreen(api: _ApiSinExpediente())));
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('Todavía no tienes un expediente'), findsOneWidget);
      expect(find.text('Hacer el diagnóstico'), findsOneWidget);
      _noInventaNada();
    });

    testWidgets('con datos del servidor: pinta LOS del servidor, no otros',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: BusinessDashboardScreen(api: _ApiConDatos())));
      await tester.pump();
      await tester.pump();

      // Lo que devolvió la API aparece tal cual.
      expect(find.text('Salón de Ana'), findsOneWidget);
      expect(find.text('Etapa: OPERATION'), findsOneWidget);
      expect(find.textContaining('73'), findsWidgets); // 72.5 -> 73, ya en escala 0-100
      expect(find.text('Renovar matrícula mercantil'), findsOneWidget);
      expect(find.text('Falta concepto sanitario'), findsOneWidget);
      expect(find.text('EN PROCESO'), findsOneWidget);

      // Y nada de lo inventado.
      _noInventaNada();
      expect(find.text('65%'), findsNothing);
      expect(find.text('Mis Tareas y Trámites'), findsNothing);
    });

    testWidgets('detalle de tarea sin tarea recibida: no inventa un trámite',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: BusinessTaskDetailScreen()));
      await tester.pump();
      await tester.pump();

      expect(find.text('No se recibió ninguna tarea que mostrar.'), findsOneWidget);
      _noInventaNada();
      expect(find.textContaining('Ley 9 de 1979'), findsNothing);
      expect(find.textContaining('Enviar para Verificación'), findsNothing);
    });

    testWidgets('detalle de tarea con tarea real: pinta SUS datos', (WidgetTester tester) async {
      const tarea = BusinessTaskModel(
        id: 'task-real-1',
        businessProfileId: 'perfil-real-1',
        requirementId: 'req-1',
        title: 'Inscribirse en Cámara de Comercio',
        description: 'Renovar la matrícula mercantil 2026.',
        stage: TaskStage.entender,
        status: TaskStatus.pending,
        dueDate: '2026-12-31',
      );

      await tester.pumpWidget(const MaterialApp(home: BusinessTaskDetailScreen(task: tarea)));
      await tester.pump();
      await tester.pump();

      expect(find.text('Inscribirse en Cámara de Comercio'), findsWidgets);
      expect(find.text('Renovar la matrícula mercantil 2026.'), findsOneWidget);
      expect(find.text('PENDIENTE'), findsOneWidget);
      expect(find.textContaining('task-real-1'), findsOneWidget);
      expect(find.text('Avanzar a la siguiente etapa'), findsOneWidget);
      _noInventaNada();
    });
  });
}
