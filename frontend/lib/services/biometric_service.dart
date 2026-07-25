// frontend/lib/services/biometric_service.dart
import 'dart:convert';
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
    final userId = prefs.getString('userId') ?? '7';

    final compressionResults = await Future.wait([
      compute(_compressImageIsolate, Uint8List.fromList(faceImageBytes)),
      compute(_compressImageIsolate, Uint8List.fromList(handsImageBytes)),
    ]);
    final compressedFace = compressionResults[0];
    final compressedHands = compressionResults[1];

    final response = await http
        .post(
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
        )
        .timeout(const Duration(seconds: 90));

    if (response.statusCode != 200) {
      String serverMessage;
      try {
        final errorBody = jsonDecode(response.body);
        serverMessage = errorBody is Map<String, dynamic>
            ? (errorBody['error'] ?? errorBody['message'] ?? response.body)
                .toString()
            : response.body;
      } catch (_) {
        serverMessage = response.body;
      }

      final detail = serverMessage.trim().isEmpty
          ? 'El servidor no devolvió detalles.'
          : serverMessage.trim();
      throw Exception('HTTP ${response.statusCode}: $detail');
    }

    return jsonDecode(response.body);
  }

  static Future<List<ColorPaletteItem>> getColorPalette(String hex,
      {int count = 5, String mode = 'analogic'}) async {
    final baseUrl = await getBaseUrl();
    final token = await AuthService.getToken();
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/api/color/palette?hex=$hex&count=$count&mode=$mode'),
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
        Uri.parse(
            '$baseUrl/api/biometric/check-uv?lat=${position.latitude}&lng=${position.longitude}'),
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

  /// Compresión de imagen ejecutada en un Isolate separado para no bloquear el main thread.
  /// Se usa como top-level function compatible con `compute()`.
  static Uint8List _compressImageIsolate(Uint8List bytes) {
    if (bytes.isEmpty) return bytes;
    try {
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return bytes;

      img.Image resized;
      if (decodedImage.width > 1024 || decodedImage.height > 1024) {
        if (decodedImage.width > decodedImage.height) {
          resized = img.copyResize(decodedImage, width: 1024);
        } else {
          resized = img.copyResize(decodedImage, height: 1024);
        }
      } else {
        resized = decodedImage;
      }
      return Uint8List.fromList(img.encodeJpg(resized, quality: 75));
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

  ColorPaletteItem(
      {required this.hex,
      required this.name,
      required this.hsl,
      required this.rgb});

  factory ColorPaletteItem.fromJson(Map<String, dynamic> json) {
    return ColorPaletteItem(
      hex: json['hex'] ?? '',
      name: json['name'] ?? '',
      hsl: json['hsl'] ?? '',
      rgb: json['rgb'] ?? '',
    );
  }
}
