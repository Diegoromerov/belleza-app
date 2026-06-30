// frontend/lib/screens/academy/course_detail_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'quiz_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _courseData;
  String? _error;
  
  // Lección activa seleccionada para reproducción/lectura
  Map<String, dynamic>? _activeLesson;

  @override
  void initState() {
    super.initState();
    _loadCourseDetail();
  }

  Future<void> _loadCourseDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final data = await ApiService.get('/api/academy/courses/${widget.courseId}');
      setState(() {
        _courseData = data;
        _isLoading = false;
        
        // Seleccionar por defecto la primera lección no completada si existe
        if (_activeLesson == null) {
          _selectFirstIncompleteLesson(data);
        } else {
          // Refrescar el estado de la lección activa
          _refreshActiveLessonState(data);
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar detalle del curso: $e';
        _isLoading = false;
      });
    }
  }

  void _selectFirstIncompleteLesson(Map<String, dynamic> data) {
    final List<dynamic> modules = data['modules'] ?? [];
    for (var m in modules) {
      final List<dynamic> lessons = m['lessons'] ?? [];
      for (var l in lessons) {
        if (l['lesson_completed'] != true) {
          _activeLesson = l;
          return;
        }
      }
    }
    // Si están todas completas, mostrar la primera lección
    if (modules.isNotEmpty && (modules[0]['lessons'] as List).isNotEmpty) {
      _activeLesson = modules[0]['lessons'][0];
    }
  }

  void _refreshActiveLessonState(Map<String, dynamic> data) {
    if (_activeLesson == null) return;
    final List<dynamic> modules = data['modules'] ?? [];
    for (var m in modules) {
      final List<dynamic> lessons = m['lessons'] ?? [];
      for (var l in lessons) {
        if (l['lesson_id'] == _activeLesson!['lesson_id']) {
          _activeLesson = l;
          return;
        }
      }
    }
  }

  Future<void> _completeLesson(String lessonId) async {
    try {
      await ApiService.post('/api/academy/lessons/$lessonId/complete', {});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 ¡Lección completada con éxito!'),
          backgroundColor: Colors.green,
        ),
      );
      // Recargar datos para actualizar la UI y porcentajes
      await _loadCourseDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al completar lección: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  bool _areAllLessonsCompleted() {
    if (_courseData == null) return false;
    final List<dynamic> modules = _courseData!['modules'] ?? [];
    for (var m in modules) {
      final List<dynamic> lessons = m['lessons'] ?? [];
      for (var l in lessons) {
        if (l['lesson_completed'] != true) return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFC89D93);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cargando Curso...', style: TextStyle(color: Colors.white))),
        body: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFC89D93)))),
      );
    }

    if (_error != null || _courseData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error', style: TextStyle(color: Colors.white))),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Ocurrió un error inesperado'),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadCourseDetail, child: const Text('Reintentar'))
            ],
          ),
        ),
      );
    }

    final course = _courseData!['course'];
    final List<dynamic> modules = _courseData!['modules'] ?? [];
    final bool hasCertificate = _courseData!['hasCertificate'] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text(course['title'] ?? 'Detalle del Curso', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeColor, const Color(0xFFE2C4BC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // 📽️ Sección del reproductor de video / lectura de lección activa
          if (_activeLesson != null)
            Container(
              color: Colors.black,
              width: double.infinity,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Placeholder estético del video con botón de reproducción
                  Positioned.fill(
                    child: Image.network(
                      'https://images.unsplash.com/photo-1562322140-8baeececf3df?q=80&w=800',
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.4),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                        onPressed: () {
                          // Simulación de reproducción
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reproduciendo video: ${_activeLesson!['lesson_title']}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _activeLesson!['lesson_title'],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Simulación de Video streaming disponible',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 📖 Contenido de texto y botones de acción rápida
          if (_activeLesson != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _activeLesson!['lesson_title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _activeLesson!['content_text'] ?? '',
                    style: TextStyle(fontSize: 14, color: Colors.grey[800], height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_activeLesson!['lesson_completed'] == true)
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 6),
                            Text('Completada', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _completeLesson(_activeLesson!['lesson_id']),
                          icon: const Icon(Icons.check, color: Colors.white),
                          label: const Text('Marcar como Completada', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      if (_areAllLessonsCompleted() && !hasCertificate)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final success = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizScreen(courseId: widget.courseId),
                              ),
                            );
                            if (success == true) {
                              _loadCourseDetail();
                            }
                          },
                          icon: const Icon(Icons.quiz, color: Colors.white),
                          label: const Text('Tomar Examen', style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                    ],
                  ),
                  if (hasCertificate) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '¡Felicidades! Completaste este curso y desbloqueaste la insignia: ${course['badge_name']}.',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          const Divider(height: 1),

          // 🗂️ Lista de Módulos y Lecciones
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: modules.length,
              itemBuilder: (context, mIndex) {
                final module = modules[mIndex];
                final List<dynamic> lessons = module['lessons'] ?? [];

                return ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(
                    module['title'] ?? 'Módulo',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  children: lessons.map<Widget>((lesson) {
                    final bool isCurrent = _activeLesson != null && _activeLesson!['lesson_id'] == lesson['lesson_id'];
                    final bool isCompleted = lesson['lesson_completed'] == true;

                    return ListTile(
                      selected: isCurrent,
                      selectedTileColor: themeColor.withValues(alpha: 0.08),
                      leading: Icon(
                        isCompleted ? Icons.check_circle : Icons.play_arrow_outlined,
                        color: isCompleted ? Colors.green : (isCurrent ? themeColor : Colors.grey),
                      ),
                      title: Text(
                        lesson['lesson_title'] ?? 'Lección',
                        style: TextStyle(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? themeColor : Colors.black87,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 12),
                      onTap: () {
                        setState(() {
                          _activeLesson = lesson;
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
