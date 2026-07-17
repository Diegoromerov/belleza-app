import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:glowapp_frontend/core/constants/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiService {
  final Dio client;

  ApiService() : client = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)) {
    // Interceptor to attach JWT token to every request
    client.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'jwt_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      options.headers['Content-Type'] = 'application/json';
      return handler.next(options);
    }));
  }

  /// Login – devuelve el mapa completo recibido del backend.
  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final response = await client.post('/auth/login', data: {'email': email, 'password': password});
    final data = response.data as Map<String, dynamic>;
    // Guardar token para futuras peticiones
    final token = data['token'] as String?;
    if (token != null) {
      await const FlutterSecureStorage().write(key: 'jwt_token', value: token);
    }
    return data;
  }

  /// Envía los resultados del entrenamiento al backend.
  Future<void> submitTrainingResult({
    required String userId,
    required int difficultyLevel,
    required int totalAttempts,
    required int correctAnswers,
    required int accuracy,
  }) async {
    await client.post('/training/result', data: {
      'userId': userId,
      'difficultyLevel': difficultyLevel,
      'totalAttempts': totalAttempts,
      'correctAnswers': correctAnswers,
      'accuracy': accuracy,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
