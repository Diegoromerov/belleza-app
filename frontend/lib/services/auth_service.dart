import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';

class AuthService {
  static Future<String> getBaseUrl() async {
    await ApiService.ensureBaseUrl();
    return ApiService.baseUrl;
  }

  static Future<bool> register(String fullName, String email, String password,
      String? phone, String role) async {
    final baseUrl = await getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'full_name': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      }),
    );
    return response.statusCode == 201;
  }

  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    final baseUrl = await getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      
      // 🛡️ PARCHE DE SEGURIDAD (GLOW-SEC-02): Guardar el token en almacenamiento cifrado
      await SecureStorageService().write('token', data['token']);
      
      await prefs.setString('userId', data['user']['id'].toString());
      await prefs.setString('userName', data['user']['full_name']);
      if (data['user']['role'] != null) {
        await prefs.setString('userRole', data['user']['role']);
      }
      return data;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> loginOAuth({
    required String email,
    required String nombre,
    required String fotoUrl,
    required String authProvider,
    required String providerId,
  }) async {
    final baseUrl = await getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/oauth'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'nombre': nombre,
        'foto_url': fotoUrl,
        'auth_provider': authProvider,
        'provider_id': providerId,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      
      // 🛡️ PARCHE DE SEGURIDAD (GLOW-SEC-02): Guardar el token en almacenamiento cifrado
      await SecureStorageService().write('token', data['token']);
      
      await prefs.setString('userId', data['user']['id'].toString());
      await prefs.setString('userName', data['user']['full_name']);
      if (data['user']['role'] != null) {
        await prefs.setString('userRole', data['user']['role']);
      }
      return data;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> completeOnboarding({
    required String role,
    String? documentoIdUrl,
    String? rutUrl,
    String? certificacionUrl,
    required bool aceptarHabeasData,
    required bool aceptarTerminos,
  }) async {
    final baseUrl = await getBaseUrl();
    final token = await getToken();
    if (token == null) return null;
    final response = await http.patch(
      Uri.parse('$baseUrl/api/auth/onboarding'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'rol': role,
        'documento_id_url': documentoIdUrl,
        'rut_url': rutUrl,
        'certificacion_url': certificacionUrl,
        'aceptar_habeas_data': aceptarHabeasData,
        'aceptar_terminos': aceptarTerminos,
      }),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      if (data['user'] != null && data['user']['role'] != null) {
        await prefs.setString('userRole', data['user']['role']);
      }
      return data;
    }
    return null;
  }

  static Future<String?> getToken() async {
    // 🛡️ PARCHE DE SEGURIDAD (GLOW-SEC-02): Leer token de almacenamiento cifrado
    return await SecureStorageService().read('token');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // 🛡️ PARCHE DE SEGURIDAD (GLOW-SEC-02): Limpiar almacenamiento cifrado
    await SecureStorageService().clearAll();
    ApiService.resetCachedBaseUrl();
  }

  static Future<Map<String, dynamic>?> loginWithGoogle(String idToken) async {
    final baseUrl = await getBaseUrl();
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'idToken': idToken}),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final prefs = await SharedPreferences.getInstance();
      
      // 🛡️ PARCHE DE SEGURIDAD (GLOW-SEC-02): Guardar el token en almacenamiento cifrado
      await SecureStorageService().write('token', data['token']);
      
      await prefs.setString('userId', data['user']['id'].toString());
      await prefs.setString('userName', data['user']['full_name']);
      if (data['user']['role'] != null) {
        await prefs.setString('userRole', data['user']['role']);
      }
      return data;
    }
    return null;
  }
}
