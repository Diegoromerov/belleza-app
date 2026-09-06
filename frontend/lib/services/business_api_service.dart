import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/business_profile_model.dart';

/// GLOWAPP BUSINESS API SERVICE
/// Connects Flutter Business Engine UI with Express Backend (/api/v1/business).

class BusinessApiService {
  final String baseUrl;
  final String? authToken;

  BusinessApiService({
    this.baseUrl = 'http://localhost:5000/api/v1/business',
    this.authToken,
  });

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',
      };

  /// GET /api/v1/business/summary
  Future<Map<String, dynamic>> fetchBusinessSummary() async {
    final uri = Uri.parse('$baseUrl/summary');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      return jsonBody['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch business summary: ${response.statusCode}');
    }
  }

  /// POST /api/v1/business/diagnostic
  Future<BusinessProfileModel> runDiagnostic({
    required String mode,
    required String verticalCode,
    required String name,
    required String city,
  }) async {
    final uri = Uri.parse('$baseUrl/diagnostic');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'onboarding_mode': mode,
        'vertical_code': verticalCode,
        'name': name,
        'city': city,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      return BusinessProfileModel.fromJson(jsonBody['data']['profile'] as Map<String, dynamic>);
    } else {
      throw Exception('Failed to execute diagnostic: ${response.statusCode}');
    }
  }

  /// GET /api/v1/business/tasks
  Future<List<BusinessTaskModel>> fetchTasks() async {
    final uri = Uri.parse('$baseUrl/tasks');
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      final list = jsonBody['data'] as List? ?? [];
      return list.map((item) => BusinessTaskModel.fromJson(item as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Failed to fetch tasks: ${response.statusCode}');
    }
  }

  /// POST /api/v1/business/documents/generate
  Future<Map<String, dynamic>> generateDocument({
    required String templateCode,
    required Map<String, String> variables,
    String? businessProfileId,
  }) async {
    final uri = Uri.parse('$baseUrl/documents/generate');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'template_code': templateCode,
        'variables': variables,
        if (businessProfileId != null) 'business_profile_id': businessProfileId,
      }),
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      return jsonBody['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to generate document: ${response.statusCode}');
    }
  }

  /// POST /api/v1/business/documents/:id/request-signature
  Future<Map<String, dynamic>> requestSignature(String documentId) async {
    final uri = Uri.parse('$baseUrl/documents/$documentId/request-signature');
    final response = await http.post(uri, headers: _headers);

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      return jsonBody['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to request signature: ${response.statusCode}');
    }
  }

  /// POST /api/v1/business/documents/:id/sign
  Future<Map<String, dynamic>> signDocument(String documentId, {required String signerName}) async {
    final uri = Uri.parse('$baseUrl/documents/$documentId/sign');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'signer_name': signerName}),
    );

    if (response.statusCode == 200) {
      final jsonBody = jsonDecode(response.body);
      return jsonBody['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to sign document: ${response.statusCode}');
    }
  }
}
