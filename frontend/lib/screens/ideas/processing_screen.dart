import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../services/biometric_service.dart';
import '../../services/location_service.dart';
import '../../models/biometric_result.dart';
import 'results_screen.dart';

class ProcessingScreen extends StatefulWidget {
  final Uint8List faceImage;
  final Uint8List handsImage;

  const ProcessingScreen({
    super.key,
    required this.faceImage,
    required this.handsImage,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  double _progress = 0.0;
  String _status = 'Preparando imágenes...';
  bool _isComplete = false;
  bool _showRetry = false;
  BiometricResult? _result;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _startProcessing();
    // Fix 5: Timer de advertencia ajustado a 30s (antes 12s)
    _timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted && !_isComplete) {
        setState(() {
          _status = '⏳ Está tomando más tiempo de lo esperado...';
          _showRetry = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    try {
      // Etapa 1: Obtener ubicación (real)
      _updateProgress(10, 'Obteniendo ubicación...');
      final position = await LocationService.getCurrentPosition();

      // Etapa 2: Compresión y preparación de imágenes (real — se ejecuta en Isolate)
      _updateProgress(25, 'Comprimiendo imágenes...');

      // Etapa 3: Envío y análisis con IA (real — la llamada HTTP al backend)
      _updateProgress(40, 'Analizando rostro y manos con IA...');
      final resultData = await BiometricService.analyze(
        faceImageBytes: widget.faceImage,
        handsImageBytes: widget.handsImage,
        lat: position?.latitude,
        lng: position?.longitude,
      );

      // Etapa 4: Procesamiento de resultados
      _updateProgress(90, 'Procesando resultados...');

      setState(() {
        _result = BiometricResult.fromJson(resultData);
        _progress = 100;
        _status = '✅ ¡Completado!';
        _isComplete = true;
        _showRetry = false;
      });

      await Future.delayed(const Duration(seconds: 1));

      if (mounted && _result != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(result: _result!),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = '❌ Error al procesar: ${e.toString()}';
        _isComplete = true;
        _showRetry = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al analizar. Intenta de nuevo.')),
        );
      }
    }
  }

  void _updateProgress(double value, String status) {
    if (mounted) {
      setState(() {
        _progress = value;
        _status = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text(
                _status,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Barra de progreso
              Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _progress / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.pink],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_progress.toInt()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              if (_showRetry) ...[
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isComplete = false;
                      _showRetry = false;
                      _progress = 0.0;
                    });
                    _startProcessing();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
