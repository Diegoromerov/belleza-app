import 'package:flutter/material.dart';
import 'biometric_model.dart';

enum NiaScanStatus {
  idle,
  consented,
  scanning,
  processing,
  completed,
  error,
}

/// Provider de estado reactivo para el flujo Nia Beauty de GlowApp.
class NiaProvider extends ChangeNotifier {
  NiaScanStatus _status = NiaScanStatus.idle;
  double _progress = 0.0;
  String _currentStepMessage = 'Inicializando escaneo...';
  BiometricModel _results = BiometricModel.initial();
  bool _hasConsented = false;

  // Getters
  NiaScanStatus get status => _status;
  double get progress => _progress;
  String get currentStepMessage => _currentStepMessage;
  BiometricModel get results => _results;
  bool get hasConsented => _hasConsented;

  void grantConsent() {
    _hasConsented = true;
    _status = NiaScanStatus.consented;
    notifyListeners();
  }

  void startScan() {
    _status = NiaScanStatus.scanning;
    _progress = 0.0;
    _currentStepMessage = 'Alineando rostro...';
    notifyListeners();
  }

  void updateProgress(double progressValue, String stepMessage) {
    _progress = progressValue.clamp(0.0, 1.0);
    _currentStepMessage = stepMessage;
    if (_progress > 0.3 && _status == NiaScanStatus.scanning) {
      _status = NiaScanStatus.processing;
    }
    notifyListeners();
  }

  void saveResults(BiometricModel newResults) {
    _results = newResults;
    _status = NiaScanStatus.completed;
    _progress = 1.0;
    notifyListeners();
  }

  void triggerError() {
    _status = NiaScanStatus.error;
    notifyListeners();
  }

  void reset() {
    _status = NiaScanStatus.idle;
    _progress = 0.0;
    _currentStepMessage = 'Inicializando escaneo...';
    notifyListeners();
  }
}
