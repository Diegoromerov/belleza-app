// frontend/lib/screens/academy/academy_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'course_detail_screen.dart';

class AcademyScreen extends StatefulWidget {
  const AcademyScreen({super.key});

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  bool _isLoading = true;
  List<dynamic> _courses = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      // Asumimos que agregamos fetchAcademyCourses en ApiService
      final data = await ApiService.get('/api/academy/courses');
      setState(() {
        _courses = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar los cursos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFC89D93);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academia Glow', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFC89D93))))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(_error!, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCourses,
                          style: ElevatedButton.styleFrom(backgroundColor: themeColor),
                          child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                )
              : _courses.isEmpty
                  ? const Center(
                      child: Text('No hay cursos de capacitación disponibles en este momento.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCourses,
                      color: themeColor,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _courses.length,
                        itemBuilder: (context, index) {
                          final course = _courses[index];
                          final totalLessons = int.tryParse(course['total_lessons'].toString()) ?? 0;
                          final completedLessons = int.tryParse(course['completed_lessons'].toString()) ?? 0;
                          final progress = totalLessons > 0 ? (completedLessons / totalLessons) : 0.0;
                          final hasCertificate = course['has_certificate'] == true;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                            elevation: 3,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16.0),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CourseDetailScreen(courseId: course['id']),
                                  ),
                                );
                                _loadCourses(); // Recargar al volver por si cambió el progreso
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: themeColor.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            course['category'].toString().toUpperCase(),
                                            style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 10),
                                          ),
                                        ),
                                        if (hasCertificate)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Row(
                                              children: [
                                                Icon(Icons.verified, color: Colors.green, size: 12),
                                                SizedBox(width: 4),
                                                Text(
                                                  'COMPLETADO',
                                                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      course['title'] ?? 'Curso',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      course['description'] ?? '',
                                      style: TextStyle(color: Colors.grey[600], fontSize: 13.0),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Progreso: $completedLessons / $totalLessons lecciones',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          '${(progress * 100).toInt()}%',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: themeColor),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation(themeColor),
                                        minHeight: 8,
                                      ),
                                    ),
                                    if (hasCertificate) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.military_tech, color: Colors.amber, size: 20),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Insignia obtenida: ${course['badge_name']}',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
