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
    final idempotencyKey = 'consent_${DateTime.now().millisecondsSinceEpoch}_$userId';

    final response = await http.post(
      Uri.parse('$baseUrl/api/consent'),
      headers: {
        'Content-Type': 'application/json',
        'Idempotency-Key': idempotencyKey,
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
    final idempotencyKey = 'scan_${DateTime.now().millisecondsSinceEpoch}_$userId';

    final compressionResults = await Future.wait([
      compute(_compressImageIsolate, Uint8List.fromList(faceImageBytes)),
      compute(_compressImageIsolate, Uint8List.fromList(handsImageBytes)),
    ]);
    final compressedFace = compressionResults[0];
    final compressedHands = compressionResults[1];

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/biometric/analyze'),
            headers: {
              'Content-Type': 'application/json',
              'Idempotency-Key': idempotencyKey,
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
          .timeout(const Duration(seconds: 40));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('⚠️ [BiometricService] Servidor respondió con ${response.statusCode}. Activando Mock Fallback.');
        return getMockBiometricJson();
      }
    } catch (e) {
      debugPrint('⚠️ [BiometricService] Error de red o sin saldo en modelos IA: $e. Activando Mock Fallback.');
      return getMockBiometricJson();
    }
  }

  /// Retorna un resultado simulado de alta fidelidad para navegar el flujo completo sin saldo de IA
  static BiometricResult getMockBiometricResult() {
    return BiometricResult.fromJson(getMockBiometricJson());
  }

  /// Mock JSON completo integrando Evimetra (0-100), Bioderma (4 familias) y Media.io (VTO tones)
  static Map<String, dynamic> getMockBiometricJson() {
    return {
      'profileId': 'glow_mock_profile_2026',
      'glowScore': 84,
      'face': {
        'hydration': 78,
        'wrinkles': 18,
        'spots': 16,
        'pores': 22,
        'subtono': 'Cálido',
        'bioAge': 26,
      },
      'hands': {
        'manchasSolares': 'mínima',
        'sequedad': 'óptima',
        'cuticulas': 'sanas',
        'unas': 'fuertes',
        'edadAparente': 25,
      },
      'dermoFamilies': {
        'sebumPores': {
          'score': 26,
          'level': 'Equilibrado',
          'suggestedTreatment': 'Limpieza facial profunda ultrasónica y exfoliación enzimática',
          'suggestedActive': 'Niacinamida 5% + Ácido Salicílico',
        },
        'pigmentationClarity': {
          'score': 20,
          'level': 'Tono Uniforme Radiante',
          'suggestedTreatment': 'Velo iluminador antioxidante con Vitamina C pura',
          'suggestedActive': 'Vitamina C pura 15% + Ácido Ferúlico',
        },
        'firmnessLines': {
          'score': 22,
          'level': 'Firmeza y Elasticidad Óptima',
          'suggestedTreatment': 'Radiofrecuencia facial reactivadora y masaje Kobido',
          'suggestedActive': 'Péptidos de Cobre + Ácido Hialurónico',
        },
        'barrierHydration': {
          'score': 84,
          'level': 'Barrera Cutánea Fortalecida',
          'suggestedTreatment': 'Velo de colágeno marino con hidratación profunda',
          'suggestedActive': 'Ácido Hialurónico Multimolecular + Ceramidas NP',
        },
      },
      'recommendation': 'Tu piel presenta una armonía luminosa con balance hídrico superior y subtono cálido dorado. Para potenciar tu GlowScore al 95+, combina activos antioxidantes por la mañana con masajes faciales semanales. En maquillaje, la paleta terracota, champagne y melocotón elevará exponencialmente tu visagismo.',
      'vtoTones': {
        'lipsticks': [
          {'name': 'Terracota Sunset', 'hex': '#B84A39', 'finish': 'Mate'},
          {'name': 'Warm Nude Satin', 'hex': '#C88A68', 'finish': 'Satinado'},
          {'name': 'Peach Glow Dew', 'hex': '#E05A47', 'finish': 'Brillante'},
          {'name': 'Berry Chic', 'hex': '#9E2A2B', 'finish': 'Mate'},
        ],
        'nails': [
          {'name': 'Terracota Chic', 'hex': '#B84A39', 'style': 'Almond'},
          {'name': 'Champagne Shimmer', 'hex': '#D4AF37', 'style': 'Square'},
          {'name': 'Velvet Nude', 'hex': '#C88A68', 'style': 'Oval'},
          {'name': 'Deep Burgundy', 'hex': '#4A0E17', 'style': 'Coffin'},
        ],
      },
      'products': [
        {
          'name': 'Serum Cera-Hyaluronic Booster',
          'brand': 'GlowLab Clinical',
          'image': '',
          'price': '\$78.000 COP',
          'compatible': true,
        },
        {
          'name': 'Protector Solar Fluid SPF 50+ Invisible',
          'brand': 'Bioderma Photoderm',
          'image': '',
          'price': '\$95.000 COP',
          'compatible': true,
        },
        {
          'name': 'Aceite Labial Con Péptidos Honey Peach',
          'brand': 'Aura Luxe Atelier',
          'image': '',
          'price': '\$45.000 COP',
          'compatible': true,
        },
      ],
    };
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
    try {
      final baseUrl = await getBaseUrl();
      final token = await AuthService.getToken();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'test-user';

      final response = await http.get(
        Uri.parse('$baseUrl/api/biometric/recommended/$userId'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['products'] != null && (data['products'] as List).isNotEmpty) {
          return (data['products'] as List)
              .map((p) => ProductDetail.fromJson(p))
              .toList();
        }
      }
    } catch (_) {}

    return [
      ProductDetail(
        barcode: '770123456789',
        name: 'Serum Cera-Hyaluronic Booster 30ml',
        brand: 'GlowLab Clinical',
        price: '\$78.000 COP',
        categories: 'Cuidado Facial, Hidratación',
        compatible: true,
        compatibilityReason: 'Formulado con Ácido Hialurónico al 2% para restaurar la barrera cutánea identificada en tu GlowScore.',
      ),
      ProductDetail(
        barcode: '340134883441',
        name: 'Photoderm Nude Touch SPF 50+ Muy Claro',
        brand: 'Bioderma',
        price: '\$95.000 COP',
        categories: 'Protección Solar con Color',
        compatible: true,
        compatibilityReason: 'Acabado mate aterciopelado perfecto para el control de sebo y poros sugerido por la IA.',
      ),
      ProductDetail(
        barcode: '770987654321',
        name: 'Aceite Reparador de Cutículas & Uñas',
        brand: 'Aura Luxe Atelier',
        price: '\$45.000 COP',
        categories: 'Manicura Profesional',
        compatible: true,
        compatibilityReason: 'Nutrición con óleo de jojoba y vitamina E para preparar tus manos previo al esmaltado VTO.',
      ),
    ];
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
