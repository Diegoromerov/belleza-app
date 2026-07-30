// lib/screens/academy/course_list.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../design/components/luxe_components.dart';
import '../../design/components/academy_luxe_components.dart';
import '../../widgets/academy/progress_card.dart';
import 'lesson_view.dart';

class CourseListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> courses;
  final Map<String, dynamic>? activeProgress;

  const CourseListScreen({
    super.key,
    required this.courses,
    this.activeProgress,
  });

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  String _selectedLevel = 'Todos';

  List<String> get _levels => ['Todos', 'Introductorio', 'Intermedio', 'Avanzado Master'];

  @override
  Widget build(BuildContext context) {
    final filtered = widget.courses.where((c) {
      if (_selectedLevel == 'Todos') return true;
      final level = (c['nivel'] ?? c['level'] ?? '').toString();
      return level.toLowerCase().contains(_selectedLevel.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: LuxeColors.nude50,
      appBar: AppBar(
        backgroundColor: LuxeColors.nude50,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ACADEMIA GLOW',
          style: TextStyle(
            fontFamily: 'Didot',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TARJETA DE PROGRESO DE USUARIO
              if (widget.activeProgress != null) ...[
                ProgressCard(
                  title: widget.activeProgress!['curso_activo'] ?? 'Master en Dermo-Estética',
                  completedLessons: widget.activeProgress!['lecciones_completadas'] ?? 4,
                  totalLessons: widget.activeProgress!['total_lecciones'] ?? 10,
                  xpPoints: widget.activeProgress!['xp'] ?? 350,
                ),
                const SizedBox(height: LuxeSpacing.xxl),
              ],

              // TÍTULO EDITORIAL SECCIÓN
              const Text(
                'CATÁLOGO DE FORMACIÓN ESPECIALIZADA',
                style: TextStyle(
                  fontFamily: 'Didot',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              // FILTRO DE NIVELES EN CHIPS LUXE
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _levels.map((lvl) {
                    final isSelected = _selectedLevel == lvl;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(lvl),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedLevel = lvl;
                          });
                        },
                        selectedColor: LuxeColors.gold871,
                        backgroundColor: LuxeColors.nude100,
                        labelStyle: TextStyle(
                          color: isSelected ? LuxeColors.nude900 : LuxeColors.nude700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected ? LuxeColors.gold871 : LuxeColors.nude200,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: LuxeSpacing.lg),

              // LISTA DE CURSOS CON GAP LUXE (LuxeSpacing.lg = 10.5px)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: LuxeSpacing.lg),
                itemBuilder: (context, index) {
                  final course = filtered[index];
                  final String title = course['titulo'] ?? course['title'] ?? 'Curso Especializado';
                  final String duration = course['duracion'] ?? '4.5 hrs';
                  final String level = course['nivel'] ?? 'Avanzado';
                  final String? imageUrl = course['imagen_url'] ?? course['image'];
                  final int lessonsCount = course['total_lecciones'] ?? 8;

                  return LuxeCard(
                    padding: const EdgeInsets.all(LuxeSpacing.xl),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LessonViewScreen(
                            course: course,
                            lessons: course['lessons'] ?? [],
                          ),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // IMAGEN SUPERIOR CON BORDER RADIUS MD (6.5px)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(LuxeSpacing.md),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: imageUrl != null && imageUrl.isNotEmpty
                                ? Image.network(imageUrl, fit: BoxFit.cover)
                                : Container(
                                    color: LuxeColors.nude200,
                                    child: const Icon(Icons.school_outlined, color: LuxeColors.gold871, size: 48),
                                  ),
                          ),
                        ),
                        const SizedBox(height: LuxeSpacing.md),

                        // BADGES DE NIVEL Y METADATOS MONO
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            LuxeBadge(label: level),
                            Text(
                              '$duration • $lessonsCount Módulos',
                              style: LuxeTypography.monoSm,
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // TÍTULO DIDOT
                        Text(
                          title,
                          style: LuxeTypography.displaySm,
                        ),

                        const SizedBox(height: 12),

                        // BOTÓN VER CONTENIDO
                        const Align(
                          alignment: Alignment.centerRight,
                          child: LuxeButton(
                            label: 'Explorar Módulos',
                            icon: Icons.play_arrow_outlined,
                            variant: LuxeButtonVariant.tonal,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
