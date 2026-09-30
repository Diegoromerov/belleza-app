// frontend/test/glow_cycle_screens_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beauty_app/screens/glow_cycle/glow_cycle_journey_screen.dart';
import 'package:beauty_app/screens/glow_cycle/glow_cycle_adaptation_screen.dart';
import 'package:beauty_app/screens/glow_cycle/glow_cycle_graduation_screen.dart';
import 'package:beauty_app/screens/profile/my_glow_dashboard_screen.dart';

void main() {
  group('Glow Cycle Longitudinal Transformation Screens Tests', () {
    testWidgets('GlowCycleJourneyScreen renders correctly and handles check-in', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GlowCycleJourneyScreen(),
        ),
      );

      // Verify header and core elements
      expect(find.text('MI VIAJE GLOW CYCLE'), findsOneWidget);
      expect(find.text('GLOW CYCLE · FASE DE ADAPTACIÓN'), findsOneWidget);
      expect(find.text('Transformación Cutánea: Hidratación'), findsOneWidget);
      expect(find.text('+15 pts Delta'), findsOneWidget);
      expect(find.text('Progreso: Día 15 de 30'), findsOneWidget);
      expect(find.textContaining('América/Bogotá'), findsOneWidget);

      // Verify Routine Sections
      expect(find.text('RITUAL DIARIO (HÁBITOS)'), findsOneWidget);
      expect(find.text('Rutina Matutina (AM)'), findsOneWidget);
      expect(find.text('Rutina Nocturna (PM)'), findsOneWidget);

      // Tap on Check-in button
      final checkinButton = find.text('Registrar Check-in de Hoy');
      expect(checkinButton, findsOneWidget);
      await tester.ensureVisible(checkinButton);
      await tester.tap(checkinButton);
      await tester.pumpAndSettle();

      expect(find.text('¡Check-in Registrado Hoy en Bogotá!'), findsOneWidget);
    });

    testWidgets('GlowCycleAdaptationScreen renders delta comparisons and Atena RAG decision', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GlowCycleAdaptationScreen(),
        ),
      );

      // Verify screen title
      expect(find.text('ADAPTACIÓN DEL CICLO'), findsOneWidget);

      // Verify Provenance & Quality (Contract 03)
      expect(find.text('PROVENIENCIA & CALIDAD DE ESCANEO'), findsOneWidget);
      expect(find.text('Calidad 94% (Óptima)'), findsOneWidget);

      // Verify Semantic Delta Comparison (Contracts 01 & 02)
      expect(find.text('COMPARATIVA LÍNEA BASE VS RE-SCAN'), findsOneWidget);
      expect(find.text('Nivel de Hidratación Dérmica'), findsOneWidget);
      expect(find.text('+15 pts (+30%)'), findsOneWidget);
      expect(find.text('-11 pts (-26%)'), findsOneWidget);

      // Verify Atena Multidimensional Decision (Contracts 08, 09, 10 & 04)
      expect(find.text('DECISIÓN MULTIDIMENSIONAL ATENA'), findsOneWidget);
      expect(find.text('INTENSIFICAR'), findsOneWidget);
      expect(find.textContaining('20,412 fragmentos clínicos'), findsOneWidget);
    });

    testWidgets('GlowCycleGraduationScreen renders completion summary and Contract 12 transition', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: GlowCycleGraduationScreen(),
        ),
      );

      // Verify screen title and hero
      expect(find.text('GRADUACIÓN GLOW CYCLE'), findsOneWidget);
      expect(find.text('¡GRADUACIÓN COMPLETADA!'), findsOneWidget);
      expect(find.text('30 Días de Transformación Cutánea'), findsOneWidget);

      // Verify cumulative metrics
      expect(find.text('RESULTADOS FINALES DEL CICLO'), findsOneWidget);
      expect(find.text('+22 pts'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.textContaining('¡ALCANZADA Y SUPERADA'), findsOneWidget);

      // Verify Contract 12 Next Cycle Recommendation
      expect(find.text('RECOMENDACIÓN ATENA (CONTRACT 12)'), findsOneWidget);
      expect(find.text('Glow Cycle: Textura, Poros y Luminosidad (30 Días)'), findsOneWidget);
      expect(find.text('Iniciar Siguiente Glow Cycle: Textura & Luminosidad'), findsOneWidget);
    });

    testWidgets('MyGlowDashboardScreen navigates to Journey and Adaptation screens', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: MyGlowDashboardScreen(),
        ),
      );

      // Tap on Check-in AM/PM button to open Journey screen
      final checkinNavBtn = find.text('Check-in AM/PM');
      expect(checkinNavBtn, findsOneWidget);
      await tester.ensureVisible(checkinNavBtn);
      await tester.tap(checkinNavBtn);
      await tester.pumpAndSettle();

      expect(find.text('MI VIAJE GLOW CYCLE'), findsOneWidget);
    });
  });
}
