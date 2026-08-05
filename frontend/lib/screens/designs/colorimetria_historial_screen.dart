// frontend/lib/screens/designs/colorimetria_historial_screen.dart
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../shared/theme.dart';

class ColorimetriaHistorialScreen extends StatefulWidget {
  const ColorimetriaHistorialScreen({super.key});

  @override
  State<ColorimetriaHistorialScreen> createState() => _ColorimetriaHistorialScreenState();
}

class _ColorimetriaHistorialScreenState extends State<ColorimetriaHistorialScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _historial = [];

  @override
  void initState() {
    super.initState();
    _loadHistorial();
  }

  Future<void> _loadHistorial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.fetchColorimetriaHistorial();
      setState(() {
        _historial = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F7),
      appBar: AppBar(
        title: const Text('Historial de Colorimetría', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar el historial:\n$_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadHistorial,
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                          child: const Text('Reintentar'),
                        )
                      ],
                    ),
                  ),
                )
              : _historial.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.palette_outlined, color: Colors.grey, size: 56),
                            const SizedBox(height: 16),
                            const Text(
                              'Aún no tienes análisis de colorimetría.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Hazte un análisis en el buscador de belleza para ver tu paleta aquí.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('Ir al Analizador', style: TextStyle(fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _historial.length,
                      itemBuilder: (context, index) {
                        final item = _historial[index];
                        final result = item['result'] ?? {};
                        final String dateStr = item['created_at'] != null
                            ? DateTime.parse(item['created_at']).toLocal().toString().substring(0, 16)
                            : '';
                        final String undertone = result['undertone'] ?? result['skin_undertone'] ?? 'Desconocido';
                        final String type = item['type'] == 'skin-tone' ? 'Colorimetría Facial' : 'Colorimetría Capilar';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFF3EAE8), width: 1.2),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFCF9F7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item['type'] == 'skin-tone' ? Icons.palette_rounded : Icons.face_rounded,
                                color: AppTheme.primary,
                              ),
                            ),
                            title: Text(
                              type,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text, fontSize: 14),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Subtono: $undertone',
                                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateStr,
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                '/palette-card',
                                arguments: result,
                              );
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}
