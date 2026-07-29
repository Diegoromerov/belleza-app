import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../state/biometric_model.dart';

class NiaApiService {
  // Usa tu IP local si pruebas en emulador (10.0.2.2) o tu dominio de Railway en producción
  static const String baseUrl = 'http://localhost:3000'; 

  Future<BiometricModel> submitScan(File imageFile) async {
    try {
      // 1. Convertir imagen a Base64
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 2. Preparar la petición
      final url = Uri.parse('$baseUrl/api/nia-beauty/scan');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image_base64': 'data:image/jpeg;base64,$base64Image',
          'user_id': 'guest_user', // Reemplazar con ID real si hay auth
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BiometricModel.fromJson(data['data']);
      } else {
        throw Exception('Error en el servidor: ${response.body}');
      }
    } catch (e) {
      throw Exception('Fallo de conexión: $e');
    }
  }
}
