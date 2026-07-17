import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:glowapp_frontend/core/constants/api_constants.dart';

class WsService {
  WebSocketChannel? _channel;
  final _storage = const FlutterSecureStorage();
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;
    try {
      _channel = WebSocketChannel.connect(Uri.parse(ApiConstants.wsUrl));
      _channel!.stream.listen(
        (message) => _handleMessage(message),
        onDone: () => _isConnected = false,
        onError: (_) => _isConnected = false,
      );
      // Register token with backend
      _channel!.sink.add(jsonEncode({
        'type': 'register',
        'token': token,
      }));
      _isConnected = true;
    } catch (e) {
      print('Error conectando WebSocket: $e');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      // TODO: Forward to SocketNotifier via provider
    } catch (e) {
      print('Error parseando mensaje WS: $e');
    }
  }

  void disconnect() {
    if (_channel != null) {
      _channel!.sink.close(status.normalClosure);
      _isConnected = false;
    }
  }
}
