// frontend/lib/screens/academy/quiz_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final String courseId;
  const QuizScreen({super.key, required this.courseId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _isLoading = true;
  List<dynamic> _questions = [];
  String? _error;

  // Respuestas del usuario: { questionId: selectedIndex }
  final Map<String, int> _userAnswers = {};

  // Estado del resultado
  bool _isSubmitting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _result = null;
        _userAnswers.clear();
      });
      final data = await ApiService.get('/api/academy/courses/${widget.courseId}/quiz');
      setState(() {
        _questions = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar cuestionario: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitQuiz() async {
    if (_userAnswers.length < _questions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor responde todas las preguntas del examen.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      // Mapear respuestas en el formato requerido por la API
      final answersMap = {};
      _userAnswers.forEach((qId, index) {
        answersMap[qId] = index;
      });

      final res = await ApiService.post(
        '/api/academy/courses/${widget.courseId}/submit-quiz',
        {'answers': answersMap},
      );

      setState(() {
        _result = res;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar examen: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFC89D93);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Examen de Certificación')),
        body: const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFC89D93)))),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadQuiz, child: const Text('Reintentar'))
            ],
          ),
        ),
      );
    }

    // Pantalla de resultados si el examen fue enviado
    if (_result != null) {
      final bool approved = _result!['approved'] == true;
      final int score = _result!['score'] ?? 0;
      final int total = _result!['total'] ?? 0;
      final String badgeName = _result!['badgeName'] ?? '';

      return Scaffold(
        appBar: AppBar(
          title: const Text('Resultados del Examen'),
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeColor, const Color(0xFFE2C4BC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  approved ? Icons.emoji_events : Icons.sentiment_very_dissatisfied,
                  size: 100,
                  color: approved ? Colors.amber : Colors.redAccent,
                ),
                const SizedBox(height: 24),
                Text(
                  approved ? '¡Felicidades, Aprobaste!' : 'No has aprobado esta vez',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'Obtuviste una puntuación de $score / $total correctas.',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                if (approved) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.military_tech, color: Colors.amber, size: 48),
                        const SizedBox(height: 8),
                        const Text(
                          'INSIGNIA DESBLOQUEADA',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          badgeName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, true); // Devolver true para indicar aprobación y recargar
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Volver al Curso', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'Para obtener la certificación debes contestar correctamente el 100% de las preguntas.',
                      style: TextStyle(color: Colors.grey, height: 1.4),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _loadQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Volver a Intentar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Salir', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Examen de Certificación', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFC89D93))))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _questions.length,
                    itemBuilder: (context, qIndex) {
                      final quiz = _questions[qIndex];
                      final List<dynamic> options = quiz['options'] ?? [];
                      final String quizId = quiz['id'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 20.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pregunta ${qIndex + 1} de ${_questions.length}',
                                style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                quiz['question'] ?? '',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                              ),
                              const SizedBox(height: 16),
                              Column(
                                children: List.generate(options.length, (oIndex) {
                                  final optionText = options[oIndex].toString();
                                  final isSelected = _userAnswers[quizId] == oIndex;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    decoration: BoxDecoration(
                                      color: isSelected ? themeColor.withValues(alpha: 0.08) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? themeColor : Colors.grey[300]!,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: RadioListTile<int>(
                                      title: Text(optionText, style: const TextStyle(fontSize: 14)),
                                      value: oIndex,
                                      groupValue: _userAnswers[quizId],
                                      activeColor: themeColor,
                                      onChanged: (val) {
                                        setState(() {
                                          _userAnswers[quizId] = val!;
                                        });
                                      },
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text(
                      'Enviar Respuestas',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
