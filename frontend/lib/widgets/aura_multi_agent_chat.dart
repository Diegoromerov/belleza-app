// frontend/lib/widgets/aura_multi_agent_chat.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AuraMultiAgentChatWidget extends StatefulWidget {
  final String userId;
  final String userToken;
  final String backendWsUrl; // e.g. "ws://localhost:3000"

  const AuraMultiAgentChatWidget({
    Key? key,
    required this.userId,
    required this.userToken,
    this.backendWsUrl = 'ws://10.0.2.2:3000',
  }) : super(key: key);

  @override
  _AuraMultiAgentChatWidgetState createState() => _AuraMultiAgentChatWidgetState();
}

class _AuraMultiAgentChatWidgetState extends State<AuraMultiAgentChatWidget> {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  WebSocketChannel? _channel;
  String _agentStatusMessage = '';
  bool _isAgentExecuting = false;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    try {
      _channel = IOWebSocketChannel.connect(Uri.parse(widget.backendWsUrl));
      
      // Registrar autenticación JWT en el handshake del socket
      _channel?.sink.add(jsonEncode({
        'type': 'register',
        'token': widget.userToken,
        'userId': widget.userId,
      }));

      _channel?.stream.listen(
        (message) {
          final data = jsonDecode(message);
          
          // Manejar eventos de estado de AURA (Tool Execution en tiempo real)
          if (data['type'] == 'aura_status') {
            final status = data['data'];
            setState(() {
              if (status['state'] == 'executing_tool') {
                _isAgentExecuting = true;
                _agentStatusMessage = _getAgentStatusText(status['tool']);
              } else if (status['state'] == 'thinking') {
                _isAgentExecuting = true;
                _agentStatusMessage = 'AURA está analizando tu mensaje...';
              } else {
                _isAgentExecuting = false;
                _agentStatusMessage = '';
              }
            });
          }

          // Manejar mensajes entrantes de AURA
          if (data['type'] == 'chat_message') {
            setState(() {
              _isAgentExecuting = false;
              _agentStatusMessage = '';
              _messages.add(data['data']);
            });
          }
        },
        onError: (error) {
          print('❌ WebSocket error: $error');
        },
        onDone: () {
          print('🔌 Conexión WebSocket cerrada');
        },
      );
    } catch (e) {
      print('❌ Error conectando WebSocket: $e');
    }
  }

  String _getAgentStatusText(String? toolName) {
    switch (toolName) {
      case 'query_user_biometric_profile':
        return '🌸 ATENA analizando tu subtono y perfil biométrico...';
      case 'search_nearby_services':
        return '📍 HERMES calculando distancias PostGIS en Bogotá...';
      case 'check_provider_availability':
        return '📅 HERMES verificando la agenda del prestador...';
      case 'evaluate_user_rebooking':
        return '⏰ CHRONOS evaluando la cadencia de tu tratamiento...';
      case 'recommend_glowstore_products':
        return '🛍️ HESTIA buscando productos compatibles en GlowStore...';
      case 'get_provider_b2b_insights':
        return '📈 VALKYRIE evaluando ofertas y promociones dinámicas...';
      case 'search_beauty_knowledge_rag':
        return '📖 Consultando la guía técnica de belleza...';
      default:
        return '✨ AURA procesando con agentes especialistas...';
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Agregar mensaje local del usuario
    setState(() {
      _messages.add({
        'sender_id': widget.userId,
        'receiver_id': '0',
        'message': text,
        'created_at': DateTime.now().toIso8601String(),
      });
      _isAgentExecuting = true;
      _agentStatusMessage = 'AURA está pensando...';
    });

    _textController.clear();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Indicador de Estado en Vivo (WebSocket aura_status)
        if (_isAgentExecuting)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.pink.shade50,
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.pinkAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _agentStatusMessage,
                    style: TextStyle(fontSize: 12, color: Colors.pink.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

        // Lista de Mensajes del Chat
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg['sender_id'].toString() == widget.userId;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.pink.shade400 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg['message'] ?? '',
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      // Renderizado especial si AURA incluye etiqueta de redirección
                      if (!isUser && (msg['message']?.contains('Redirección Módulo Ideas:') ?? false))
                        _buildRedirectionButton(context, msg['message']),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Input Bar
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Pregúntale algo a AURA...',
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.pinkAccent),
                onPressed: _sendMessage,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRedirectionButton(BuildContext context, String message) {
    String moduleKey = 'nails-classic';
    if (message.contains('skin-tone')) moduleKey = 'skin-tone';
    if (message.contains('hair-diagnostic')) moduleKey = 'hair-diagnostic';
    if (message.contains('eyebrow-visagism')) moduleKey = 'eyebrow-visagism';

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple.shade600,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.auto_awesome, size: 16),
        label: Text('Abrir $moduleKey en Módulo de Ideas'),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navegando al Módulo de Ideas: $moduleKey')),
          );
        },
      ),
    );
  }
}
