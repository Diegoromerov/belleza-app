// frontend/lib/services/membership_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';

class MembershipService {
  static Future<String> getBaseUrl() async {
    await ApiService.ensureBaseUrl();
    return ApiService.baseUrl;
  }

  /// Obtiene el perfil transaccional de membresía, XP y Aura Coins del backend
  static Future<Map<String, dynamic>?> fetchUserTierProfile() async {
    try {
      final baseUrl = await getBaseUrl();
      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/api/membership-tier/profile'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          return body['data'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Otorga Puntos XP por actividades (citas, compras, diagnósticos, redes)
  static Future<Map<String, dynamic>?> awardXp({
    required String eventType,
    required int xpAmount,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final baseUrl = await getBaseUrl();
      final token = await AuthService.getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/api/membership-tier/award-xp'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'eventType': eventType,
          'xpAmount': xpAmount,
          'referenceId': referenceId,
          'metadata': metadata,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Canjea Aura Coins por cupones de descuento en COP
  static Future<Map<String, dynamic>?> redeemCoins(int coinsToRedeem) async {
    try {
      final baseUrl = await getBaseUrl();
      final token = await AuthService.getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/api/membership-tier/redeem-coins'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'coinsToRedeem': coinsToRedeem,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
