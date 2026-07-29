import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../../../shared/glow_tokens.dart';
import '../widgets/holographic_overlay.dart';

/// Pantalla de Captura Guiada con Cámara y Detección Facial.
/// Muestra la vista previa de la cámara en vivo con el [HolographicOverlay]
/// superpuesto, el cual cambia a verde ([GlowTokens.emerald]) cuando el rostro
/// está centrado correctamente dentro del óvalo holográfico.
class CaptureGuidedScreen extends StatefulWidget {
  final List<CameraDescription>? availableCameras;
  final Function(InputImage image)? onFaceCaptured;
  final Function(File imageFile)? onCaptureSuccess;

  const CaptureGuidedScreen({
    super.key,
    this.availableCameras,
    this.onFaceCaptured,
    this.onCaptureSuccess,
  });

  @override
  State<CaptureGuidedScreen> createState() => _CaptureGuidedScreenState();
}

class _CaptureGuidedScreenState extends State<CaptureGuidedScreen> {
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  bool _isFaceAligned = false;
  bool _isProcessingFrame = false;
  bool _isAutoCapturing = false;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initFaceDetector();
    _initCamera();
  }

  void _initFaceDetector() {
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      enableLandmarks: false,
      enableClassification: false,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> _initCamera() async {
    try {
      final cameras = widget.availableCameras ?? await availableCameras();
      if (cameras.isEmpty) return;

      // Seleccionar cámara frontal si está disponible
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      _cameraController!.startImageStream((CameraImage image) {
        if (_isProcessingFrame) return;
        _isProcessingFrame = true;
        _processCameraImage(image);
      });
    } catch (e) {
      debugPrint('Error al inicializar la cámara: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      final sensorOrientation = _cameraController?.description.sensorOrientation ?? 0;
      final inputImage = _inputImageFromCameraImage(image, sensorOrientation);
      if (inputImage == null) {
        _isProcessingFrame = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);
      if (!mounted) return;

      if (faces.isNotEmpty) {
        final face = faces.first;
        final boundingBox = face.boundingBox;
        
        // Criterio de centrado de rostro dentro del visor de la cámara
        final imageWidth = image.width.toDouble();
        final imageHeight = image.height.toDouble();
        
        final faceCenterX = boundingBox.center.dx;
        final faceCenterY = boundingBox.center.dy;

        // Tolerancia de centrado (rango medio 35% - 65%)
        final isXCentered = faceCenterX > (imageWidth * 0.35) && faceCenterX < (imageWidth * 0.65);
        final isYCentered = faceCenterY > (imageHeight * 0.30) && faceCenterY < (imageHeight * 0.70);

        final aligned = isXCentered && isYCentered;

        if (aligned != _isFaceAligned) {
          setState(() {
            _isFaceAligned = aligned;
          });

          if (aligned && !_isAutoCapturing) {
            _isAutoCapturing = true;
            _triggerAutoCapture();
          }
        }
      } else {
        if (_isFaceAligned) {
          setState(() {
            _isFaceAligned = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error procesando frame de rostro: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  /// Dispara la auto-captura de la foto al confirmar la alineación del rostro
  Future<void> _triggerAutoCapture() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) return;

      // Pausar stream e capturar foto
      final XFile photoFile = await _cameraController!.takePicture();
      final File imageFile = File(photoFile.path);

      if (widget.onFaceCaptured != null) {
        final inputImage = InputImage.fromFilePath(photoFile.path);
        widget.onFaceCaptured!(inputImage);
      }

      // Notificar callback de navegación a pantalla de procesamiento
      if (mounted) {
        widget.onCaptureSuccess?.call(imageFile);
      }
    } catch (e) {
      debugPrint('Error durante auto-captura de foto: $e');
      _isAutoCapturing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image, int sensorOrientation) {
    if (_cameraController == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotationFromDegrees(sensorOrientation),
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  InputImageRotation _rotationFromDegrees(int degrees) {
    switch (degrees) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GlowTokens.nightAndean,
      body: Stack(
        children: [
          // Vista previa de la Cámara
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: GlowTokens.roseGold,
              ),
            ),

          // Superposición Holográfica con Semantics para Lectores de Pantalla
          Center(
            child: Semantics(
              label: _isFaceAligned
                  ? 'Visor de cámara: Rostro perfectamente alineado y centrado.'
                  : 'Visor de cámara: Rostro no detectado o fuera de centro. Por favor centra tu cara dentro del óvalo.',
              liveRegion: true,
              child: HolographicOverlay(
                isAligned: _isFaceAligned,
                width: 260,
                height: 360,
              ),
            ),
          ),

          // Instrucción dinámica de usuario accesible
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Semantics(
              label: _isFaceAligned
                  ? 'Estado: Rostro centrado correctamente.'
                  : 'Estado: Centra tu rostro dentro del óvalo holográfico.',
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: GlowTokens.nightAndean.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: _isFaceAligned ? GlowTokens.emerald : GlowTokens.roseGold,
                    width: 2.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isFaceAligned
                          ? Icons.check_circle_rounded
                          : Icons.center_focus_strong_rounded,
                      color: _isFaceAligned ? GlowTokens.emerald : GlowTokens.roseGold,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        _isFaceAligned
                            ? '¡Perfecto! Rostro centrado (Alineado)'
                            : 'Centra tu rostro dentro del óvalo',
                        style: TextStyle(
                          fontFamily: GlowTokens.fontInter,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isFaceAligned ? GlowTokens.emerald : GlowTokens.creamSilk,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
