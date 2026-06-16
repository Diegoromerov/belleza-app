// frontend/lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/provider_model.dart';
import '../models/service_model.dart';

class ApiService {
  // --- CONFIGURACIÓN DE ENTORNO DE DESARROLLO / PRODUCCIÓN ---
  static const bool useStaging = true;
  static const String stagingUrl =
      'https://belleza-app-production.up.railway.app';

  static String? _cachedBaseUrl;
  static final List<String> _ports = ['8082', '3000', '3001'];

  static void resetCachedBaseUrl() {
    _cachedBaseUrl = null;
  }

  static String get _host => kIsWeb ? 'localhost' : '10.0.2.2';

  static String get baseUrl {
    if (useStaging) return stagingUrl;
    return _cachedBaseUrl ?? 'http://$_host:8082';
  }

  static String get _baseUrl => baseUrl;
  static String get _apiPath => '/api';

  static Future<void> ensureBaseUrl() async {
    if (useStaging) {
      _cachedBaseUrl = stagingUrl;
      return;
    }
    if (_cachedBaseUrl != null) return;
    for (final port in _ports) {
      final url = 'http://$_host:$port';
      try {
        final response = await http
            .get(Uri.parse('$url/api/health'))
            .timeout(const Duration(milliseconds: 1500));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' ||
              data['message']?.toString().contains('funcionando') == true) {
            _cachedBaseUrl = url;
            if (kDebugMode) {
              print(
                  '🔌 ApiService: BaseUrl detectado y fijado en $_cachedBaseUrl');
            }
            return;
          }
        }
      } catch (_) {
        // Continuar al siguiente puerto
      }
    }
    // Fallback default
    _cachedBaseUrl = 'http://$_host:3000';
  }

  static String normalizeUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';

    final activeBase = Uri.parse(_baseUrl);

    if (rawUrl.startsWith('/')) {
      return '${activeBase.toString()}$rawUrl';
    }

    final parsed = Uri.tryParse(rawUrl);
    if (parsed == null || !parsed.hasScheme) return rawUrl;

    final isLocalHost =
        parsed.host == 'localhost' || parsed.host == '127.0.0.1';
    if (!isLocalHost) return rawUrl;

    return Uri(
      scheme: activeBase.scheme,
      host: activeBase.host,
      port: activeBase.port,
      path: parsed.path,
      query: parsed.query.isEmpty ? null : parsed.query,
    ).toString();
  }

  static dynamic _normalizeDynamicUrls(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value.map((key, entryValue) {
        final shouldNormalize = entryValue is String &&
            const {
              'avatar_url',
              'image_url',
              'preview_url',
              'original_image_url',
              'url',
            }.contains(key);

        return MapEntry(
          key,
          shouldNormalize
              ? normalizeUrl(entryValue)
              : _normalizeDynamicUrls(entryValue),
        );
      });
    }

    if (value is List) {
      return value.map(_normalizeDynamicUrls).toList();
    }

    return value;
  }

  // 🔹 MÉTODO CENTRALIZADO PARA OBTENER HEADERS CON TOKEN
  static Future<Map<String, String>> _getAuthHeaders() async {
    await ensureBaseUrl();
    final headers = {'Content-Type': 'application/json'};
    final token = await _getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      // Debug opcional: imprimir en consola de Flutter Web (Dart-safe)
      if (kDebugMode) {
        final preview = token.length > 30 ? token.substring(0, 30) : token;
        print('🔐 Token enviado: $preview...');
      }
    } else {
      if (kDebugMode) {
        print('⚠️  No hay token disponible para Authorization');
      }
    }
    return headers;
  }

  // Exponer headers públicos para analíticas u otros servicios externos
  static Future<Map<String, String>> getAuthHeaders() => _getAuthHeaders();

  static Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token');
    } catch (_) {
      return null;
    }
  }

  // ─── Métodos genéricos HTTP (para nuevas funcionalidades) ───────
  static Future<dynamic> get(String path) async {
    await ensureBaseUrl();
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$_baseUrl$path');
    final response = await http.get(uri, headers: headers);
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw Exception(data['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    await ensureBaseUrl();
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$_baseUrl$path');
    final response =
        await http.post(uri, headers: headers, body: jsonEncode(body));
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw Exception(data['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    await ensureBaseUrl();
    final headers = await _getAuthHeaders();
    final uri = Uri.parse('$_baseUrl$path');
    final response =
        await http.put(uri, headers: headers, body: jsonEncode(body));
    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) return data;
    throw Exception(data['error'] ?? 'Error ${response.statusCode}');
  }

  // ─────────────────────────────────────────────────────────────
  // PROVEEDORES (Públicos - sin token requerido)
  // ─────────────────────────────────────────────────────────────

  static Future<List<ProviderModel>> fetchProvidersSecured(
      {double? latitude, double? longitude}) async {
    await ensureBaseUrl();
    String url = '$_baseUrl$_apiPath/providers';
    if (latitude != null && longitude != null) {
      url += '?lat=$latitude&lon=$longitude';
    }
    final response =
        await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = _normalizeDynamicUrls(json.decode(response.body));
      return (data['data'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((j) => ProviderModel.fromJson(j))
          .toList();
    }
    throw Exception('Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> fetchProviderDetails(
      String providerId) async {
    await ensureBaseUrl();
    final response = await http
        .get(Uri.parse('$_baseUrl$_apiPath/providers/$providerId'))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = _normalizeDynamicUrls(json.decode(response.body));
      return Map<String, dynamic>.from(data['data']);
    }
    throw Exception('Error ${response.statusCode}');
  }

  // ─────────────────────────────────────────────────────────────
  // RESERVAS (Cliente) - REQUIEREN TOKEN
  // ─────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> createBooking({
    required String providerId,
    required String serviceId,
    required String scheduledAt,
    required String serviceAddress,
    String? notes,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .post(
          Uri.parse('$_baseUrl$_apiPath/bookings'),
          headers: headers,
          body: json.encode({
            'provider_id': providerId,
            'service_id': serviceId,
            'scheduled_at': scheduledAt,
            'service_address': serviceAddress,
            'notes': notes,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200 || response.statusCode == 201)
      return json.decode(response.body);
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> fetchClientBookings() async {
    final headers = await _getAuthHeaders();
    final response = await http
        .get(
          Uri.parse('$_baseUrl$_apiPath/bookings/client'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .patch(
          Uri.parse('$_baseUrl$_apiPath/bookings/$bookingId/cancel'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> submitReview(
      String bookingId, int rating, String comment) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .post(
          Uri.parse('$_baseUrl$_apiPath/bookings/$bookingId/review'),
          headers: headers,
          body: json.encode({
            'rating': rating,
            'comment': comment.isNotEmpty ? comment : null
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200 || response.statusCode == 201)
      return json.decode(response.body);
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> payBooking(
      String bookingId, String paymentMethod) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .post(
          Uri.parse('$_baseUrl$_apiPath/bookings/$bookingId/pay'),
          headers: headers,
          body: json.encode({'payment_method': paymentMethod}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  // ─────────────────────────────────────────────────────────────
  // 🔹 NUEVOS: Gestión de Servicios del Proveedor - REQUIEREN TOKEN
  // ─────────────────────────────────────────────────────────────

  static Future<List<ServiceModel>> fetchProviderServices() async {
    final headers = await _getAuthHeaders();
    final response = await http
        .get(
          Uri.parse('$_baseUrl$_apiPath/services/provider'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'] as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((j) => ServiceModel.fromJson(j))
          .toList();
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<ServiceModel> createService({
    required String name,
    required double price,
    required int durationMinutes,
    String? description,
    String? category,
    bool isActive = true,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .post(
          Uri.parse('$_baseUrl$_apiPath/services'),
          headers: headers,
          body: json.encode({
            'name': name,
            'price': price,
            'duration_minutes': durationMinutes,
            'description': description,
            'category': category,
            'is_active': isActive,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return ServiceModel.fromJson(data['service']);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<ServiceModel> updateService({
    required String id,
    required String name,
    required double price,
    required int durationMinutes,
    String? description,
    String? category,
    bool? isActive,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .put(
          Uri.parse('$_baseUrl$_apiPath/services/$id'),
          headers: headers,
          body: json.encode({
            'name': name,
            'price': price,
            'duration_minutes': durationMinutes,
            'description': description,
            'category': category,
            'is_active': isActive,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return ServiceModel.fromJson(data['service']);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> deleteService(String id) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .delete(
          Uri.parse('$_baseUrl$_apiPath/services/$id'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  // ─────────────────────────────────────────────────────────────
  // 🔹 NUEVOS: Subida de Imágenes y Portafolio
  // ─────────────────────────────────────────────────────────────

  static Future<String> uploadImage(
      Uint8List imageBytes, String filename) async {
    await ensureBaseUrl();
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl$_apiPath/upload');
    final request = http.MultipartRequest('POST', uri);
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes('image', imageBytes, filename: filename),
    );
    final streamedResponse =
        await request.send().timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['url'] as String;
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> updateAvatar(String imageUrl) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .patch(
          Uri.parse('$_baseUrl$_apiPath/users/avatar'),
          headers: headers,
          body: json.encode({'avatar_url': imageUrl}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> fetchProviderPortfolio() async {
    final headers = await _getAuthHeaders();
    final response = await http
        .get(
          Uri.parse('$_baseUrl$_apiPath/portfolio/provider'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = _normalizeDynamicUrls(json.decode(response.body));
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> addPortfolioItem({
    required String imageUrl,
    String? title,
    String? category,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .post(
          Uri.parse('$_baseUrl$_apiPath/portfolio'),
          headers: headers,
          body: json.encode({
            'image_url': imageUrl,
            'title': title,
            'category': category,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200 || response.statusCode == 201)
      return json.decode(response.body);
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> deletePortfolioItem(String id) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .delete(
          Uri.parse('$_baseUrl$_apiPath/portfolio/$id'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> updatePortfolioItem({
    required String id,
    String? title,
    String? category,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .put(
          Uri.parse('$_baseUrl$_apiPath/portfolio/$id'),
          headers: headers,
          body: json.encode({
            'title': title,
            'category': category,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> fetchUserProfile() async {
    final headers = await _getAuthHeaders();
    final response = await http
        .get(
          Uri.parse('$_baseUrl$_apiPath/users/profile'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = _normalizeDynamicUrls(json.decode(response.body));
      return data['user'] as Map<String, dynamic>;
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required String fullName,
    required String phone,
    String? description,
    int? activeStartHour,
    int? activeEndHour,
    Map<String, dynamic>? weeklySchedule,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .patch(
          Uri.parse('$_baseUrl$_apiPath/users/profile'),
          headers: headers,
          body: json.encode({
            'full_name': fullName,
            'phone': phone,
            if (description != null) 'description': description,
            if (activeStartHour != null) 'active_start_hour': activeStartHour,
            if (activeEndHour != null) 'active_end_hour': activeEndHour,
            if (weeklySchedule != null) 'weekly_schedule': weeklySchedule,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> fetchAvailableSlots({
    required String providerId,
    required String date,
    required String serviceId,
  }) async {
    await ensureBaseUrl();
    final response = await http
        .get(
          Uri.parse(
              '$_baseUrl$_apiPath/providers/$providerId/slots?date=$date&service_id=$serviceId'),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['slots']);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  // ─────────────────────────────────────────────────────────────
  // 🔹 NUEVOS: Sistema de Chat y Mensajería - REQUIEREN TOKEN
  // ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> fetchChatConversations() async {
    final headers = await _getAuthHeaders();
    final response = await http
        .get(
          Uri.parse('$_baseUrl$_apiPath/chat/conversations'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> fetchChatMessages(
      String partnerId) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .get(
          Uri.parse('$_baseUrl$_apiPath/chat/messages/$partnerId'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> sendChatMessage(
      String receiverId, String message,
      {String? imagePath}) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .post(
          Uri.parse('$_baseUrl$_apiPath/chat/messages'),
          headers: headers,
          body: json.encode({
            'receiver_id': receiverId,
            'message': message,
            if (imagePath != null) 'image_path': imagePath,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> markMessagesAsRead(
      String partnerId) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .patch(
          Uri.parse('$_baseUrl$_apiPath/chat/messages/$partnerId/read'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<bool> updateProviderStatus(bool isActive,
      {double? latitude, double? longitude}) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .patch(
          Uri.parse('$_baseUrl$_apiPath/providers/status'),
          headers: headers,
          body: json.encode({
            'is_active': isActive,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['is_active'] as bool;
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> startBooking(String bookingId) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .patch(
          Uri.parse('$_baseUrl$_apiPath/bookings/$bookingId/start'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> completeBooking(
    String bookingId,
    String pin, {
    double? providerLat,
    double? providerLon,
    double? clientLat,
    double? clientLon,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .post(
          Uri.parse('$_baseUrl$_apiPath/bookings/$bookingId/complete'),
          headers: headers,
          body: json.encode({
            'pin_verificacion': pin,
            if (providerLat != null) 'provider_lat': providerLat,
            if (providerLon != null) 'provider_lon': providerLon,
            if (clientLat != null) 'client_lat': clientLat,
            if (clientLon != null) 'client_lon': clientLon,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> fetchProviderBookings() async {
    final headers = await _getAuthHeaders();
    final response = await http
        .get(
          Uri.parse('$_baseUrl$_apiPath/bookings/provider'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> updateBookingStatus(
      String bookingId, String newStatus) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .patch(
          Uri.parse('$_baseUrl$_apiPath/bookings/$bookingId/status'),
          headers: headers,
          body: json.encode({'status': newStatus}),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  // 🔹 NUEVO: Enviar señal de pánico SOS
  static Future<Map<String, dynamic>> triggerSOS({
    String? bookingId,
    double? latitude,
    double? longitude,
  }) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .post(
          Uri.parse('$_baseUrl$_apiPath/sos'),
          headers: headers,
          body: json.encode({
            if (bookingId != null) 'booking_id': bookingId,
            if (latitude != null) 'latitude': latitude,
            if (longitude != null) 'longitude': longitude,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  // 🔹 NUEVO: Buscar ideas de diseños de manicura (Pinterest / Google CSE)
  static Future<List<Map<String, dynamic>>> fetchDesignIdeas(String query) async {
    final headers = await _getAuthHeaders();
    final response = await http
        .get(
          Uri.parse('$_baseUrl$_apiPath/designs/search?q=${Uri.encodeComponent(query)}'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['data']);
    }
    throw Exception(
        json.decode(response.body)['error'] ?? 'Error ${response.statusCode}');
  }

  // 🔹 NUEVO: Analizar forma del rostro por IA
  static Future<Map<String, dynamic>> analyzeFaceShape(Uint8List imageBytes, String filename) async {
    await ensureBaseUrl();
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl$_apiPath/designs/face-analysis');
    final request = http.MultipartRequest('POST', uri);
    
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
      ),
    );
    
    final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamedResponse);
    
    final data = json.decode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }
    final errorMsg = data['details'] != null ? "${data['error']}: ${data['details']}" : (data['error'] ?? 'Error ${response.statusCode}');
    throw Exception(errorMsg);
  }

  // 🔹 NUEVO: Analizar diseño por IA (Colorimetría, Capilar, Textura, Cejas, Uñas)
  static Future<Map<String, dynamic>> analyzeDesignWithAI(Uint8List imageBytes, String filename, String type) async {
    await ensureBaseUrl();
    final token = await _getToken();
    final uri = Uri.parse('$_baseUrl$_apiPath/designs/analyze');
    final request = http.MultipartRequest('POST', uri);
    
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.fields['type'] = type;
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename,
      ),
    );
    
    final streamedResponse = await request.send().timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamedResponse);
    
    final data = json.decode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }
    final errorMsg = data['details'] != null ? "${data['error']}: ${data['details']}" : (data['error'] ?? 'Error ${response.statusCode}');
    throw Exception(errorMsg);
  }
}

class MapSettings {
  static bool isDark = false;
}
