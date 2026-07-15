// frontend/lib/services/biometric_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import 'api_service.dart';
import 'auth_service.dart';
import 'location_service.dart';
import '../models/biometric_result.dart';

class BiometricService {
  static Future<String> getBaseUrl() async {
    await ApiService.ensureBaseUrl();
    return ApiService.baseUrl;
  }

  static Future<void> saveConsent() async {
    final baseUrl = await getBaseUrl();
    final token = await AuthService.getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'test-user';

    final response = await http.post(
      Uri.parse('$baseUrl/api/consent'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'version': '1.0',
        'accepted': true,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Error al guardar consentimiento biométrico');
    }
  }

  static Future<bool> hasConsent() async {
    final baseUrl = await getBaseUrl();
    final token = await AuthService.getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    if (userId == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/consent/status/$userId'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['hasActiveConsent'] ?? false;
      }
    } catch (e) {
      // Retornar falso si hay error de red o no autenticado
      return false;
    }
    return false;
  }

  static Future<Map<String, dynamic>> analyze({
    required List<int> faceImageBytes,
    required List<int> handsImageBytes,
    double? lat,
    double? lng,
  }) async {
    final baseUrl = await getBaseUrl();
    final token = await AuthService.getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    final compressedFace = _compressImage(Uint8List.fromList(faceImageBytes));
    final compressedHands = _compressImage(Uint8List.fromList(handsImageBytes));

    final response = await http.post(
      Uri.parse('$baseUrl/api/biometric/analyze'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'faceImage': base64Encode(compressedFace),
        'handsImage': base64Encode(compressedHands),
        'lat': lat,
        'lng': lng,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al analizar datos biométricos');
    }

    return jsonDecode(response.body);
  }

  static Future<List<ColorPaletteItem>> getColorPalette(String hex, {int count = 5, String mode = 'analogic'}) async {
    final baseUrl = await getBaseUrl();
    final token = await AuthService.getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/color/palette?hex=$hex&count=$count&mode=$mode'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['palette'] != null) {
          return (data['palette'] as List)
              .map((item) => ColorPaletteItem.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error getting color palette: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getUV() async {
    final baseUrl = await getBaseUrl();
    final token = await AuthService.getToken();
    final position = await LocationService.getCurrentPosition();
    if (position == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/biometric/check-uv?lat=${position.latitude}&lng=${position.longitude}'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error getting UV: $e');
    }
    return null;
  }

  static Future<List<ProductDetail>> getRecommendedProducts() async {
    final baseUrl = await getBaseUrl();
    final token = await AuthService.getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'test-user';

    final response = await http.get(
      Uri.parse('$baseUrl/api/biometric/recommended/$userId'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['products'] != null) {
        return (data['products'] as List)
            .map((p) => ProductDetail.fromJson(p))
            .toList();
      }
    }
    return [];
  }

  static Future<ProductDetail?> checkProduct(String barcode) async {
    final baseUrl = await getBaseUrl();
    final token = await AuthService.getToken();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'test-user';

    final response = await http.post(
      Uri.parse('$baseUrl/api/biometric/check'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'barcode': barcode,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['product'] != null) {
        return ProductDetail.fromJson(data['product']);
      }
    }
    return null;
  }

  static Uint8List _compressImage(Uint8List bytes) {
    // Si la imagen ya pesa menos de 1MB (1,048,576 bytes), no hacemos nada
    if (bytes.length <= 1024 * 1024) {
      return bytes;
    }
    try {
      // Usar el image package importado para decodificar y recomprimir con menor calidad (80%)
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return bytes;
      return Uint8List.fromList(img.encodeJpg(decodedImage, quality: 80));
    } catch (e) {
      return bytes;
    }
  }
}

class ColorPaletteItem {
  final String hex;
  final String name;
  final String hsl;
  final String rgb;

  ColorPaletteItem({required this.hex, required this.name, required this.hsl, required this.rgb});

  factory ColorPaletteItem.fromJson(Map<String, dynamic> json) {
    return ColorPaletteItem(
      hex: json['hex'] ?? '',
      name: json['name'] ?? '',
      hsl: json['hsl'] ?? '',
      rgb: json['rgb'] ?? '',
    );
  }
}
