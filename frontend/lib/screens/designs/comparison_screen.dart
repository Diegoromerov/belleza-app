import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../shared/theme.dart';

class ComparisonScreen extends StatefulWidget {
  final String? diagnosticId;

  const ComparisonScreen({super.key, this.diagnosticId});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> with SingleTickerProviderStateMixin {
  Uint8List? _imageBeforeBytes;
  String? _imageBeforeName;
  Uint8List? _imageAfterBytes;
  String? _imageAfterName;

  bool _isAnalyzing = false;
  String? _errorMessage;
  Map<String, dynamic>? _comparisonResult;

  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isBefore) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      setState(() {
        if (isBefore) {
          _imageBeforeBytes = bytes;
          _imageBeforeName = image.name;
        } else {
          _imageAfterBytes = bytes;
          _imageAfterName = image.name;
        }
        _comparisonResult = null; // Reset results when images change
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al seleccionar imagen: $e';
      });
    }
  }

  Future<void> _runComparison() async {
    if (_imageBeforeBytes == null || _imageAfterBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Por favor selecciona ambas imágenes (Antes y Después).'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _comparisonResult = null;
    });

    try {
      final res = await ApiService.compareDiagnostics(
        imageBefore: _imageBeforeBytes!,
        filenameBefore: _imageBeforeName ?? 'before.jpg',
        imageAfter: _imageAfterBytes!,
        filenameAfter: _imageAfterName ?? 'after.jpg',
        diagnosticId: widget.diagnosticId,
      );

      setState(() {
        _comparisonResult = res['comparison'];
        _isAnalyzing = false;
      });
      _animationController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al comparar imágenes: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F5),
      appBar: AppBar(
        title: const Text(
          'Comparador de Evolución',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.text,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFFEADBC8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Análisis Comparativo',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sube una foto del "Antes" y una del "Después" para medir el progreso exacto de tu piel.',
                          style: TextStyle(color: Colors.white.withOpacity(0.87), fontSize: 11.5, height: 1.3),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Image slots
            Row(
              children: [
                Expanded(
                  child: _buildImageSlot(
                    title: 'FOTO ANTES',
                    bytes: _imageBeforeBytes,
                    onTap: () => _pickImage(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildImageSlot(
                    title: 'FOTO DESPUÉS',
                    bytes: _imageAfterBytes,
                    onTap: () => _pickImage(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),

            // Action button
            if (!_isAnalyzing && _comparisonResult == null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 2,
                ),
                onPressed: _runComparison,
                icon: const Icon(Icons.rocket_launch),
                label: const Text('Iniciar Comparación con IA', style: TextStyle(fontWeight: FontWeight.bold)),
              ),

            if (_isAnalyzing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 12),
                    Text('Analizando diferencias de poros y humectación...', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),

            // Results Section
            if (_comparisonResult != null) ...[
              _buildResultsWidget(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlot({required String title, required Uint8List? bytes, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: bytes != null ? AppTheme.primary.withOpacity(0.5) : Colors.grey.shade300,
            width: bytes != null ? 2 : 1,
          ),
          image: bytes != null
              ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
              : null,
          boxShadow: AppTheme.cardShadow,
        ),
        child: bytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add_a_photo, color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.text),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Toca para subir',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildResultsWidget() {
    final deltaH = _comparisonResult!['delta_hidratacion'] ?? 0;
    final deltaI = _comparisonResult!['delta_impurezas'] ?? 0;
    final deltaL = _comparisonResult!['delta_luminosidad'] ?? 0;
    final resumen = _comparisonResult!['resumen'] ?? '';
    final recomendacion = _comparisonResult!['recomendacion'] ?? '';

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFF3EAE8), width: 1.5),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_rounded, color: AppTheme.primary, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Reporte de Progreso',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.text),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Métrica 1
                _buildDeltaRow('Hidratación', deltaH, Colors.blue, _progressAnimation.value),
                const SizedBox(height: 16),
                
                // Métrica 2
                _buildDeltaRow('Impurezas / Acné', deltaI, Colors.red, _progressAnimation.value, reverseColor: true),
                const SizedBox(height: 16),
                
                // Métrica 3
                _buildDeltaRow('Luminosidad', deltaL, Colors.amber, _progressAnimation.value),
                const SizedBox(height: 20),

                Text(
                  'Resumen Clínico:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text),
                ),
                const SizedBox(height: 6),
                Text(
                  resumen,
                  style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 16),

                Text(
                  'Recomendación del Asistente:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text),
                ),
                const SizedBox(height: 6),
                Text(
                  recomendacion,
                  style: const TextStyle(fontSize: 12.5, color: Colors.black87, height: 1.4),
                ),
                const SizedBox(height: 20),

                // Reset button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: BorderSide(color: AppTheme.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _comparisonResult = null;
                        _imageBeforeBytes = null;
                        _imageAfterBytes = null;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Nueva Comparación'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeltaRow(String label, int val, Color color, double animValue, {bool reverseColor = false}) {
    bool isPositiveOutcome = reverseColor ? val <= 0 : val >= 0;
    
    String sign = val > 0 ? '+' : '';
    Color statusColor = isPositiveOutcome ? Colors.green : Colors.red;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppTheme.text)),
            Text(
              '$sign$val%',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: statusColor),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            color: Colors.grey.shade100,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8 * (val.abs() / 100.0) * animValue,
                color: statusColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
