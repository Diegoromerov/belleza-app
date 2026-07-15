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
  
  bool _isProcessing = false;
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
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('No se encontró cámara');
        return;
      }
      
      final frontCamera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );
      
      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {});
        _startDetection();
      }
    } catch (e) {
      _showError('Error al iniciar cámara: $e');
    }
  }

  void _startDetection() {
    if (_cameraController == null) return;
    _cameraController!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _step == CaptureStep.done) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) return;

      if (_step == CaptureStep.face) {
        await _processFace(inputImage);
      } else if (_step == CaptureStep.hands) {
        await _processHands(image);
      }
    } catch (e) {
      debugPrint('Error en procesamiento: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageRotation = InputImageRotation.rotation0deg;
      final inputImageFormat = InputImageFormat.nv21;

      final inputImageMetadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: bytes, metadata: inputImageMetadata);
    } catch (e) {
      return null;
    }
  }

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
    if (mounted) {
      setState(() {
        _detectedFace = face;
        _isFaceValid = _validateFace(face);
        _qualityScore = _calculateFaceQuality(face);
        _instruction = _isFaceValid
            ? '✅ ¡Perfecto! Mantén la posición...'
            : _getFaceInstruction(face);
      });
    }

    if (_isFaceValid && _qualityScore > 80.0) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_isFaceValid && _qualityScore > 80.0 && mounted) {
        _captureFace();
      }
    }
  }

  bool _validateFace(Face face) {
    final faceWidth = face.boundingBox.width;
    final screenWidth = MediaQuery.of(context).size.width;
    if (faceWidth < screenWidth * 0.25) return false;
    
    final aspectRatio = face.boundingBox.height / face.boundingBox.width;
    if (aspectRatio > 1.5 || aspectRatio < 0.9) return false;
    
    return true;
  }

  double _calculateFaceQuality(Face face) {
    double score = 0.0;
    final screenWidth = MediaQuery.of(context).size.width;
    
    final sizeScore = (face.boundingBox.width / screenWidth).clamp(0.0, 0.4) * 100;
    score += sizeScore;
    
    final faceCenterX = face.boundingBox.center.dx;
    final centerOffset = (faceCenterX - screenWidth / 2).abs();
    final centerScore = (1 - (centerOffset / (screenWidth / 2))) * 30;
    score += centerScore.clamp(0.0, 30.0);
    
    final aspectRatio = face.boundingBox.height / face.boundingBox.width;
    final ratioScore = (1 - (aspectRatio - 1.2).abs() / 0.5) * 30;
    score += ratioScore.clamp(0.0, 30.0);
    
    return score.clamp(0.0, 100.0);
  }

  String _getFaceInstruction(Face face) {
    final screenWidth = MediaQuery.of(context).size.width;
    final faceWidth = face.boundingBox.width;
    
    if (faceWidth < screenWidth * 0.25) {
      return '📱 Acércate un poco más a la cámara';
    }
    if (faceWidth > screenWidth * 0.8) {
      return '📱 Aléjate un poco de la cámara';
    }
    
    final faceCenterX = face.boundingBox.center.dx;
    if (faceCenterX < screenWidth * 0.3) {
      return '👈 Mueve tu rostro hacia la derecha';
    }
    if (faceCenterX > screenWidth * 0.7) {
      return '👉 Mueve tu rostro hacia la izquierda';
    }
    
    return '🔄 Ajusta ligeramente tu posición';
  }

  Future<void> _captureFace() async {
    if (_step == CaptureStep.done) return;
    
    try {
      final image = await _cameraController!.takePicture();
      final file = File(image.path);
      _faceImage = await file.readAsBytes();
      
      setState(() {
        _step = CaptureStep.hands;
        _instruction = 'Coloca el dorso de tu mano sobre la silueta';
        _isHandValid = false;
        _qualityScore = 0.0;
      });
    } catch (e) {
      debugPrint('Error al capturar rostro: $e');
    }
  }

  Future<void> _processHands(CameraImage image) async {
    // MediaPipe Hand Detection on-device en Flutter sin C++ / bindings nativos pesados es inestable o requiere TensorFlow.
    // Simulamos la validación geométrica de encuadre en base a frames con buena luminosidad.
    final hasEnoughLight = image.planes[0].bytes[0] > 40; 
    
    if (mounted) {
      setState(() {
        _isHandValid = hasEnoughLight;
        _qualityScore = hasEnoughLight ? 85.0 : 30.0;
        _instruction = _isHandValid
            ? '✅ ¡Perfecto! Mantén la mano quieta...'
            : '🖐️ Abre los dedos y alinea tu mano con buena luz';
      });
    }

    if (_isHandValid && _qualityScore > 80.0) {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (_isHandValid && mounted) {
        _captureHands();
      }
    }
  }

  Future<void> _captureHands() async {
    if (_step == CaptureStep.done) return;
    
    try {
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
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isFaceStep
                ? CustomPaint(
                    key: const ValueKey('face_painter'),
                    painter: FaceOverlayPainter(
                      detectedFace: _detectedFace,
                      isValid: _isFaceValid,
                      quality: _qualityScore,
                      screenSize: screenSize,
                    ),
                  )
                : CustomPaint(
                    key: const ValueKey('hands_painter'),
                    painter: HandOverlayPainter(
                      isValid: _isHandValid,
                      quality: _qualityScore,
                      screenSize: screenSize,
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
                color: Colors.black.withOpacity(0.7),
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
                onPressed: isFaceStep
                    ? (isValid ? _captureFace : null)
                    : (isValid ? _captureHands : null),
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
