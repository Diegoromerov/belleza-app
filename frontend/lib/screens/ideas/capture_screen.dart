// frontend/lib/screens/ideas/capture_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'processing_screen.dart';
import 'widgets/face_overlay_painter.dart';
import 'widgets/hand_overlay_painter.dart';
import 'widgets/quality_indicator.dart';

enum CaptureStep { face, hands, done }

class CaptureScreen extends StatefulWidget {
  const CaptureScreen({super.key});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  // Estado de detección
  CaptureStep _step = CaptureStep.face;
  Face? _detectedFace;

  // Imágenes capturadas
  Uint8List? _faceImage;
  Uint8List? _handsImage;

  // Estado de validación
  String _instruction = 'Coloca tu rostro dentro del óvalo';
  bool _isFaceValid = false;
  bool _isHandValid = false;
  double _qualityScore = 0.0;
  String? _errorMessage;

  bool _isProcessing = false;
  bool _isCapturing = false;
  bool _isCameraReady = false; // nuevo estado para saber si la cámara está lista
  DateTime? _handsStepStartTime;
  late final FaceDetector _faceDetector;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
        enableLandmarks: true,
        minFaceSize: 0.2,
      ),
    );
    _initializeCamera();
  }

  @override
  void dispose() {
    _disposeCamera();
    _faceDetector.close();
    super.dispose();
  }

  void _disposeCamera() {
    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        _cameraController!.stopImageStream();
      }
      _cameraController!.dispose();
      _cameraController = null;
    }
    _isCameraReady = false;
  }

  Future<void> _initializeCamera() async {
    try {
      // 1. Verificar y solicitar permisos (usando el manejo nativo del paquete camera)
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _showError('No se encontró ninguna cámara en el dispositivo.');
        return;
      }
      _cameras = cameras;

      final frontCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      // Inicializar con manejo de excepciones de permisos
      try {
        await _cameraController!.initialize();
      } on CameraException catch (e) {
        if (e.code == 'cameraPermission' || e.code == 'CameraAccessDenied') {
          _showError('Permiso de cámara denegado. Por favor, otorga el permiso en los ajustes del dispositivo.');
          return;
        } else {
          rethrow;
        }
      }

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
        _startDetection();
      }
    } catch (e) {
      _showError('Error al iniciar la cámara: $e');
    }
  }

  void _startDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    _cameraController!.startImageStream(_processCameraImage);
    // Delay de estabilización: dar tiempo al hardware para auto-enfoque y exposición
    Future.delayed(const Duration(milliseconds: 200), () {
      // No hacemos nada especial, solo aseguramos que el stream esté activo
      if (mounted && _cameraController != null && _cameraController!.value.isStreamingImages) {
        // Todo ok
      }
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _step == CaptureStep.done || !_isCameraReady) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) {
        debugPrint('Error: No se pudo convertir la imagen de la cámara a InputImage');
        return;
      }

      if (_step == CaptureStep.face) {
        await _processFace(inputImage);
      } else if (_step == CaptureStep.hands) {
        await _processHands(image);
      }
    } catch (e, stack) {
      debugPrint('Error en procesamiento de imagen: $e\n$stack');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e. Reinicia la app.';
          _instruction = _errorMessage!;
        });
      }
    } finally {
      _isProcessing = false;
    }
  }

  // --- Conversión robusta de CameraImage a InputImage (soporte YUV_420_888) ---
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      // Determinar formato y construir los bytes adecuadamente
      final format = image.format.group;
      Uint8List bytes;
      int width = image.width;
      int height = image.height;
      int bytesPerRow = image.planes[0].bytesPerRow;

      if (format == ImageFormatGroup.nv21 || format == ImageFormatGroup.yuv420) {
        // En NV21 o YUV420, el plano 0 es el canal Y (luminancia)
        // y el plano 1 contiene U y V intercalados.
        // Para ML Kit, necesitamos un solo buffer con el formato nativo.
        final yPlane = image.planes[0];
        final uvPlane = image.planes[1];
        final yBytes = yPlane.bytes;
        final uvBytes = uvPlane.bytes;

        // NV21 = YYYY... + VUVU... (para Android)
        // La mayoría de los dispositivos Android entregan NV21.
        // Si es YUV420, el orden puede ser Y, U, V en planos separados.
        // Para simplificar, asumimos NV21 y concatenamos Y + UV.
        bytes = Uint8List(yBytes.length + uvBytes.length);
        bytes.setAll(0, yBytes);
        bytes.setAll(yBytes.length, uvBytes);
      } else if (format == ImageFormatGroup.bgra8888) {
        // iOS o cuando se fuerza BGRA
        final plane = image.planes[0];
        bytes = plane.bytes;
        bytesPerRow = plane.bytesPerRow;
      } else {
        // Fallback: concatenar todos los planos (no ideal pero evita crash)
        debugPrint('Formato de cámara no reconocido: $format. Intentando concatenar planos.');
        final allBytes = WriteBuffer();
        for (final plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        bytes = allBytes.done().buffer.asUint8List();
      }

      // Determinar rotación según el sensor
      final sensorOrientation = _cameraController?.description.sensorOrientation ?? 270;
      InputImageRotation imageRotation = InputImageRotation.rotation270deg;
      if (sensorOrientation == 90) {
        imageRotation = InputImageRotation.rotation90deg;
      } else if (sensorOrientation == 180) {
        imageRotation = InputImageRotation.rotation180deg;
      } else if (sensorOrientation == 0) {
        imageRotation = InputImageRotation.rotation0deg;
      }

      InputImageFormat inputImageFormat;
      if (format == ImageFormatGroup.bgra8888 || Platform.isIOS) {
        inputImageFormat = InputImageFormat.bgra8888;
      } else {
        inputImageFormat = InputImageFormat.nv21; // Android por defecto
      }

      final inputImageMetadata = InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
    } catch (e) {
      debugPrint('Error al convertir CameraImage a InputImage: $e');
      return null;
    }
  }

  // --- Procesamiento de rostro ---
  Future<void> _processFace(InputImage inputImage) async {
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) {
      if (mounted) {
        setState(() {
          _detectedFace = null;
          _isFaceValid = false;
          _instruction = 'No detectamos tu rostro. Acércate a la cámara.';
          _qualityScore = 0.0;
        });
      }
      return;
    }

    final face = faces.first;
    final imageSize = inputImage.metadata?.size ?? const Size(480, 640);

    if (mounted) {
      setState(() {
        _detectedFace = face;
        _isFaceValid = _validateFace(face, imageSize);
        _qualityScore = _calculateFaceQuality(face, imageSize);
        _instruction = _isFaceValid
            ? '✅ ¡Perfecto! Mantén la posición...'
            : _getFaceInstruction(face, imageSize);
      });
    }

    if (_isFaceValid && _qualityScore > 80.0) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isFaceValid && _qualityScore > 80.0 && mounted) {
        _captureFace();
      }
    }
  }

  bool _validateFace(Face face, Size imageSize) {
    final faceWidth = face.boundingBox.width;
    final imageWidth = imageSize.width;

    // Relajar los umbrales de validación (tamaño de cara entre 15% y 85% del ancho de imagen)
    if (faceWidth < imageWidth * 0.15 || faceWidth > imageWidth * 0.85) return false;
    
    // Relajar la relación de aspecto a 0.7 - 1.8
    final aspectRatio = face.boundingBox.height / face.boundingBox.width;
    if (aspectRatio > 1.8 || aspectRatio < 0.7) return false;
    return true;
  }

  double _calculateFaceQuality(Face face, Size imageSize) {
    double score = 0.0;
    final imageWidth = imageSize.width;

    // Puntuación por tamaño (óptimo alrededor del 50% del ancho de la imagen, con rango relajado de tolerancia 0.35)
    final sizeRatio = face.boundingBox.width / imageWidth;
    final sizeScore = (1 - (sizeRatio - 0.50).abs() / 0.35) * 40;
    score += sizeScore.clamp(0.0, 40.0);

    final faceCenterX = face.boundingBox.center.dx;
    final centerOffset = (faceCenterX - imageWidth / 2).abs();
    final centerScore = (1 - (centerOffset / (imageWidth / 2))) * 30;
    score += centerScore.clamp(0.0, 30.0);

    final aspectRatio = face.boundingBox.height / face.boundingBox.width;
    final ratioScore = (1 - (aspectRatio - 1.25).abs() / 0.55) * 30;
    score += ratioScore.clamp(0.0, 30.0);

    return score.clamp(0.0, 100.0);
  }

  String _getFaceInstruction(Face face, Size imageSize) {
    final imageWidth = imageSize.width;
    final faceWidth = face.boundingBox.width;

    if (faceWidth < imageWidth * 0.15) {
      return '📱 Acércate un poco más a la cámara';
    }
    if (faceWidth > imageWidth * 0.85) {
      return '📱 Aléjate un poco de la cámara';
    }

    final faceCenterX = face.boundingBox.center.dx;
    if (faceCenterX < imageWidth * 0.35) {
      return '👈 Mueve tu rostro hacia el centro';
    }
    if (faceCenterX > imageWidth * 0.65) {
      return '👉 Mueve tu rostro hacia el centro';
    }
    return '🔄 Ajusta ligeramente tu posición';
  }

  // --- Captura de rostro ---
  Future<void> _captureFace() async {
    if (_step == CaptureStep.done || _cameraController == null || _isCapturing) return;
    if (!_cameraController!.value.isInitialized) {
      _showError('La cámara no está lista');
      return;
    }
    _isCapturing = true;

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      final image = await _cameraController!.takePicture();
      final file = File(image.path);
      _faceImage = await file.readAsBytes();

      setState(() {
        _step = CaptureStep.hands;
        _handsStepStartTime = DateTime.now();
        _instruction = '🖐️ Coloca el dorso de tu mano sobre la silueta...';
        _isHandValid = false;
        _qualityScore = 0.0;
        _errorMessage = null;
      });
      _startDetection();
    } catch (e) {
      debugPrint('Error al capturar rostro: $e');
      _showError('Error al capturar rostro. Intenta de nuevo.');
      if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
        _startDetection();
      }
    } finally {
      _isCapturing = false;
    }
  }

  // --- Procesamiento de manos con luminancia robusta y pausa de preparación ---
  Future<void> _processHands(CameraImage image) async {
    // Calcular tiempo transcurrido desde el cambio al paso de manos
    _handsStepStartTime ??= DateTime.now();
    final elapsedMs = DateTime.now().difference(_handsStepStartTime!).inMilliseconds;
    const cooldownMs = 3000; // 3 segundos de pausa de preparación

    // Calcular luminancia promediando una rejilla de 9 píxeles en el canal Y (plano 0)
    final yPlane = image.planes[0];
    final yBytes = yPlane.bytes;
    final width = image.width;
    final height = image.height;

    double sum = 0;
    int count = 0;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        final x = (width * (i + 1) ~/ 4);
        final y = (height * (j + 1) ~/ 4);
        final index = y * yPlane.bytesPerRow + x;
        if (index < yBytes.length) {
          sum += yBytes[index];
          count++;
        }
      }
    }
    final averageLuminosity = count > 0 ? sum / count : 0;
    final hasEnoughLight = averageLuminosity > 40;

    if (elapsedMs < cooldownMs) {
      // Durante los 3s de pausa inicial, mostrar cuenta regresiva para que el usuario coloque su mano
      final remainingSec = ((cooldownMs - elapsedMs) / 1000).ceil();
      if (mounted) {
        setState(() {
          _isHandValid = hasEnoughLight;
          _qualityScore = hasEnoughLight ? 60.0 : 20.0;
          _instruction = '🖐️ Coloca tu mano sobre la silueta (Iniciando escaneo en ${remainingSec}s...)';
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isHandValid = hasEnoughLight;
        _qualityScore = hasEnoughLight ? 90.0 : 30.0;
        _instruction = _isHandValid
            ? '✅ ¡Perfecto! Mantén la mano quieta...'
            : '🖐️ Abre los dedos y alinea tu mano con buena luz';
      });
    }

    if (_isHandValid && _qualityScore > 80.0 && !_isCapturing) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (_isHandValid && mounted && !_isCapturing) {
        _captureHands();
      }
    }
  }

  // --- Captura de manos ---
  Future<void> _captureHands() async {
    if (_step == CaptureStep.done || _cameraController == null || _isCapturing) return;
    if (!_cameraController!.value.isInitialized) {
      _showError('La cámara no está lista');
      return;
    }
    _isCapturing = true;

    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      final image = await _cameraController!.takePicture();
      final file = File(image.path);
      _handsImage = await file.readAsBytes();

      setState(() {
        _step = CaptureStep.done;
      });

      if (mounted && _faceImage != null && _handsImage != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProcessingScreen(
              faceImage: _faceImage!,
              handsImage: _handsImage!,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al capturar manos: $e');
      _showError('Error al capturar manos. Intenta de nuevo.');
      if (_cameraController != null && !_cameraController!.value.isStreamingImages) {
        _startDetection();
      }
    } finally {
      _isCapturing = false;
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _instruction = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
      );
    }
  }

  // --- Build ---
  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized || !_isCameraReady) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Inicializando cámara...',
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.black,
      );
    }

    final screenSize = MediaQuery.of(context).size;
    final isFaceStep = _step == CaptureStep.face;
    final isValid = isFaceStep ? _isFaceValid : _isHandValid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isFaceStep ? 'Escanear rostro' : 'Escanear manos',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          // Envolver los painters con RepaintBoundary para optimizar el renderizado
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isFaceStep
                  ? RepaintBoundary(
                      key: const ValueKey('face_painter_boundary'),
                      child: SizedBox.expand(
                        child: CustomPaint(
                          key: const ValueKey('face_painter'),
                          painter: FaceOverlayPainter(
                            detectedFace: _detectedFace,
                            isValid: _isFaceValid,
                            quality: _qualityScore,
                            screenSize: screenSize,
                          ),
                        ),
                      ),
                    )
                  : RepaintBoundary(
                      key: const ValueKey('hands_painter_boundary'),
                      child: SizedBox.expand(
                        child: CustomPaint(
                          key: const ValueKey('hands_painter'),
                          painter: HandOverlayPainter(
                            isValid: _isHandValid,
                            quality: _qualityScore,
                            screenSize: screenSize,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  QualityIndicator(quality: _qualityScore),
                  const SizedBox(height: 8),
                  Text(
                    _instruction,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: (isFaceStep && _isFaceValid) || (!isFaceStep && _isHandValid)
                    ? (isFaceStep ? _captureFace : _captureHands)
                    : null,
                backgroundColor: isValid ? Colors.purple : Colors.grey,
                child: const Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
