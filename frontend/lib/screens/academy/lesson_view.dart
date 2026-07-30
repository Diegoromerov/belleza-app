// lib/screens/academy/lesson_view.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../design/components/luxe_components.dart';
import '../../design/components/academy_luxe_components.dart';

class LessonViewScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final List<dynamic> lessons;

  const LessonViewScreen({
    super.key,
    required this.course,
    this.lessons = const [],
  });

  @override
  State<LessonViewScreen> createState() => _LessonViewScreenState();
}

class _LessonViewScreenState extends State<LessonViewScreen> {
  int _currentLessonIndex = 0;
  final Set<int> _completedLessonIndices = {0};

  void _toggleLessonCompleted(int index) {
    setState(() {
      if (_completedLessonIndices.contains(index)) {
        _completedLessonIndices.remove(index);
      } else {
        _completedLessonIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String courseTitle = widget.course['titulo'] ?? widget.course['title'] ?? 'Formación Clínica';
    final List defaultLessons = widget.lessons.isNotEmpty
        ? widget.lessons
        : [
            {'titulo': '1. Fundamentos de Visagismo y Análisis Morfológico', 'duracion': '15:30 min', 'completada': true},
            {'titulo': '2. Diagnóstico Cutáneo con Espectrometría', 'duracion': '22:10 min', 'completada': false},
            {'titulo': '3. Formulación de Protocolos Personalizados', 'duracion': '18:45 min', 'completada': false},
            {'titulo': '4. Evaluación de Resultados e Historial Clínico', 'duracion': '12:00 min', 'completada': false},
          ];

    final currentLesson = defaultLessons[_currentLessonIndex];
    final String lessonTitle = currentLesson['titulo'] ?? 'Lección Actual';
    final bool isCompleted = _completedLessonIndices.contains(_currentLessonIndex);

    return Scaffold(
      backgroundColor: LuxeColors.nude50,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: LuxeColors.nude900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          courseTitle.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Didot',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
            letterSpacing: 0.8,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // REPRODUCTOR MULTIMEDIA ENMARCADO EN LUXECARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LuxeCard(
                padding: EdgeInsets.zero,
                backgroundColor: LuxeColors.nude900,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        color: LuxeColors.nude900,
                        child: const Icon(Icons.play_circle_fill, size: 64, color: LuxeColors.gold871),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            currentLesson['duracion'] ?? '15:00',
                            style: LuxeTypography.monoSm.copyWith(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: LuxeSpacing.lg),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO DIDOT Y BOTÓN DE ESTADO DE COMPLETADO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          lessonTitle,
                          style: LuxeTypography.displaySm,
                        ),
                      ),
                      LuxeButton(
                        label: isCompleted ? 'Completado' : 'Marcar visto',
                        icon: isCompleted ? Icons.check_circle : Icons.check_circle_outline,
                        variant: isCompleted ? LuxeButtonVariant.goldShimmer : LuxeButtonVariant.tonal,
                        onPressed: () => _toggleLessonCompleted(_currentLessonIndex),
                      ),
                    ],
                  ),

                  const SizedBox(height: LuxeSpacing.xxl),

                  // CONTENIDO EDITORIAL DE LA LECCIÓN (Garamond Golden Ratio height 1.618)
                  const Text(
                    'RESUMEN EJECUTIVO Y PROTOCOLO',
                    style: TextStyle(
                      fontFamily: 'Didot',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: LuxeColors.nude900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'En esta sesión abordaremos la metodología clínica para la identificación de patrones morfológicos faciales. Comprenderás la correlación entre la estructura ósea, los puntos de anclaje muscular y la distribución dérmica para diseñar protocolos estéticos con precisión microscópica.',
                    style: LuxeTypography.bodyMd,
                  ),

                  const SizedBox(height: LuxeSpacing.xxl),

                  // ESTRUCTURA DE MÓDULOS DEL CURSO
                  const Text(
                    'MÓDULOS DEL CURSO',
                    style: TextStyle(
                      fontFamily: 'Didot',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: LuxeColors.nude900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: defaultLessons.length,
                    itemBuilder: (context, index) {
                      final item = defaultLessons[index];
                      final bool isItemCompleted = _completedLessonIndices.contains(index);
                      final bool isCurrent = index == _currentLessonIndex;

                      return LuxeListTile(
                        title: item['titulo'] ?? 'Módulo ${index + 1}',
                        subtitle: item['duracion'] ?? '10:00 min',
                        isCompleted: isItemCompleted,
                        onTap: () {
                          setState(() {
                            _currentLessonIndex = index;
                          });
                        },
                        trailing: isCurrent
                            ? const LuxeBadge(
                                label: 'EN REPRODUCCIÓN',
                                backgroundColor: LuxeColors.gold871,
                                textColor: LuxeColors.nude900,
                              )
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
