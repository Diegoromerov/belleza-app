// frontend/lib/screens/chat_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'booking_screen.dart';
import 'provider_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String partnerRole;
  final String? partnerAvatar;
  final String? initialMessage;
  final String? initialImagePath;

  const ChatScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    required this.partnerRole,
    this.partnerAvatar,
    this.initialMessage,
    this.initialImagePath,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];

  Map<String, String> _parseAiRecommendation(String text) {
    final Map<String, String> meta = {};
    final lines = text.split('\n');
    for (var line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('id prestador:') || lower.contains('id_prestador:')) {
        meta['providerId'] =
            line.split(':').last.trim().replaceAll(RegExp(r'[^\w\-]'), '');
      }
      if (lower.contains('profesional/establecimiento:') ||
          lower.contains('profesional:')) {
        meta['providerName'] =
            line.split(':').last.trim().replaceAll(RegExp(r'[\"*]'), '');
      }
      if (lower.contains('servicio id:') || lower.contains('servicio_id:')) {
        meta['serviceId'] = line
            .split(':')
            .skip(1)
            .join(':')
            .trim()
            .replaceAll(RegExp(r'[\"*]'), '');
      }
      if (lower.contains('tratamiento sugerido:') ||
          lower.contains('servicio:')) {
        meta['serviceName'] =
            line.split(':').last.trim().replaceAll(RegExp(r'[\"*]'), '');
      }
      if (lower.contains('precio de referencia:') ||
          lower.contains('precio:')) {
        meta['price'] =
            line.split(':').last.trim().replaceAll(RegExp(r'[^\d]'), '');
      }
    }
    // Heuristic fallbacks if not structured
    if (meta['serviceName'] == null || meta['serviceName']!.isEmpty) {
      final lowerText = text.toLowerCase();
      if (lowerText.contains('uñas') || lowerText.contains('manicura') || lowerText.contains('pedicura') || lowerText.contains('nails')) {
        meta['serviceName'] = 'Uñas';
      } else if (lowerText.contains('cabello') || lowerText.contains('pelo') || lowerText.contains('capilar') || lowerText.contains('corte') || lowerText.contains('keratina')) {
        meta['serviceName'] = 'Cabello';
      } else if (lowerText.contains('maquillaje') || lowerText.contains('cejas') || lowerText.contains('piel') || lowerText.contains('facial') || lowerText.contains('poros') || lowerText.contains('colorimetría')) {
        meta['serviceName'] = 'Maquillaje';
      }
    }
    return meta;
  }

  bool _isLoading = true;
  String? _error;
  String? _currentUserId;
  Timer? _pollingTimer;
  bool _isSending = false;

  WebSocketChannel? _webSocketChannel;
  bool _isWebSocketConnected = false;
  Timer? _reconnectTimer;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadMessages(showLoading: true);
    _markAsRead();

    // Connect to WebSocket with reconnect/fallback
    _connectWebSocket();

    if (widget.initialMessage != null || widget.initialImagePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendInitialMessage();
      });
    }
  }

  void _connectWebSocket() {
    _webSocketChannel?.sink.close();
    _reconnectTimer?.cancel();

    try {
      final wsBase = ApiService.baseUrl.replaceFirst('http', 'ws');
      final wsUrl = '$wsBase/chat';

      _webSocketChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _webSocketChannel!.stream.listen(
        (message) {
          if (mounted) {
            setState(() {
              _isWebSocketConnected = true;
            });
            // Stop polling timer if connected
            if (_pollingTimer != null) {
              _pollingTimer!.cancel();
              _pollingTimer = null;
            }
            // Parse message and trigger reload
            try {
              _loadMessages(showLoading: false);
              _markAsRead();
            } catch (_) {}
          }
        },
        onError: (error) {
          _handleWebSocketFailure();
        },
        onDone: () {
          _handleWebSocketFailure();
        },
      );

      _registerWebSocket();
    } catch (e) {
      _handleWebSocketFailure();
    }
  }

  void _registerWebSocket() {
    if (_webSocketChannel != null && _currentUserId != null) {
      _webSocketChannel!.sink.add(jsonEncode({
        'type': 'register',
        'userId': _currentUserId,
      }));
    }
  }

  void _handleWebSocketFailure() {
    if (!mounted) return;
    setState(() {
      _isWebSocketConnected = false;
    });

    // Fallback: Start 3-second auto-polling for messages if not running
    if (_pollingTimer == null) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _loadMessages(showLoading: false);
        _markAsRead();
      });
    }

    // Schedule reconnect attempt in 5 seconds
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_isWebSocketConnected) {
        _connectWebSocket();
      }
    });
  }

  Future<void> _sendInitialMessage() async {
    final text = widget.initialMessage ?? 'Hola, analicemos esta foto';
    setState(() => _isSending = true);
    try {
      await ApiService.sendChatMessage(
        widget.partnerId,
        text,
        imagePath: widget.initialImagePath,
      );
      await _loadMessages(showLoading: false);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al enviar mensaje inicial: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _reconnectTimer?.cancel();
    _webSocketChannel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final token = await AuthService.getToken();
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length >= 2) {
          final String payload =
              parts[1].replaceAll('-', '+').replaceAll('_', '/');
          final String decoded = String.fromCharCodes(base64Decode(
            payload.length % 4 == 0
                ? payload
                : payload.padRight(
                    payload.length + (4 - payload.length % 4), '='),
          ));
          final data = jsonDecode(decoded);
          if (mounted) {
            setState(() {
              _currentUserId = data['id']?.toString();
            });
            _registerWebSocket();
          }
        }
      } catch (_) {}
    }
  }

  List<int> base64Decode(String source) {
    const base64Chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final output = <int>[];
    var buffer = 0;
    var bits = 0;
    final cleanSource = source.replaceAll(RegExp(r'\s+|=+$'), '');
    for (var i = 0; i < cleanSource.length; i++) {
      final char = cleanSource[i];
      final val = base64Chars.indexOf(char);
      if (val == -1) continue;
      buffer = (buffer << 6) | val;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        output.add((buffer >> bits) & 0xFF);
      }
    }
    return output;
  }

  Future<void> _loadMessages({required bool showLoading}) async {
    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final messages = await ApiService.fetchChatMessages(widget.partnerId);
      final wasEmpty = _messages.isEmpty;
      final oldLength = _messages.length;

      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
          _error = null;
        });

        // Scroll to bottom if new messages were added
        if (wasEmpty || messages.length > oldLength) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      if (showLoading && mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead() async {
    try {
      await ApiService.markMessagesAsRead(widget.partnerId);
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ApiService.sendChatMessage(widget.partnerId, text);
      await _loadMessages(showLoading: false);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al enviar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = widget.partnerRole == 'provider';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: widget.partnerAvatar != null && widget.partnerAvatar!.contains('avatar_aura.png')
                    ? Border.all(color: const Color(0xFFD4AF37), width: 2.0)
                    : null,
              ),
              child: CircleAvatar(
                radius: widget.partnerAvatar != null && widget.partnerAvatar!.contains('avatar_aura.png') ? 21 : 18,
                backgroundColor: isProvider ? Colors.pink[100] : Colors.purple[100],
                backgroundImage: widget.partnerAvatar != null &&
                        widget.partnerAvatar!.isNotEmpty
                    ? (widget.partnerAvatar!.startsWith('assets/')
                        ? AssetImage(widget.partnerAvatar!) as ImageProvider
                        : NetworkImage(widget.partnerAvatar!) as ImageProvider)
                    : null,
                child: widget.partnerAvatar == null ||
                        widget.partnerAvatar!.isEmpty
                    ? Text(
                        widget.partnerName.isNotEmpty
                            ? widget.partnerName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              isProvider ? Colors.pink[800] : Colors.purple[800],
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partnerName,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isProvider ? 'PRESTADOR DE SERVICIOS' : 'CLIENTE',
                    style: TextStyle(
                      fontSize: 10,
                      color: isProvider ? Colors.pink[700] : Colors.purple[700],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Colors.pink))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text('Error: $_error', textAlign: TextAlign.center),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _loadMessages(showLoading: true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pink),
                              child: Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    size: 64, color: Colors.pink[200]),
                                SizedBox(height: 16),
                                Text(
                                  '¡Envía un mensaje a ${widget.partnerName}!',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 20),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final msg = _messages[index];
                              final isMe = msg['sender_id'] == _currentUserId;
                              final isAi = msg['sender_id'] == '0' ||
                                  msg['sender_id'] ==
                                      '00000000-0000-0000-0000-000000000000';
                              final time = _formatTime(msg['created_at']);

                              if (isAi) {
                                final text = msg['message'] ?? '';
                                final isRec =
                                    text.contains('Estilo Recomendado:') ||
                                        text.contains('[SIMULACIÓN IA]');
                                
                                String cleanText = text;
                                String? redirectToolId;
                                
                                // Case-insensitive regex supporting typos (e.g., 'rediceccioin'), spaces, dots/colons
                                final redirectReg = RegExp(
                                  r'(?:redirecci[oó]n|redicecci[oó]n|rediceccioin)\s+m[oó]dulo\s+ideas[:.\s\-]+([a-zA-Z0-9\-\s]+)',
                                  caseSensitive: false,
                                );
                                final redirectMatch = redirectReg.firstMatch(text);
                                if (redirectMatch != null) {
                                  final extracted = redirectMatch.group(1)?.toLowerCase().trim() ?? '';
                                  
                                  // Normalize tool ID mapping
                                  if (extracted.contains('nails') && (extracted.contains('clas') || extracted.contains('clás'))) {
                                    redirectToolId = 'nails-classic';
                                  } else if (extracted.contains('skin') && extracted.contains('tone')) {
                                    redirectToolId = 'skin-tone';
                                  } else if (extracted.contains('hair') || extracted.contains('capilar')) {
                                    redirectToolId = 'hair-diagnostic';
                                  } else if (extracted.contains('poros') || extracted.contains('texture') || extracted.contains('textura')) {
                                    redirectToolId = 'skin-texture';
                                  } else if (extracted.contains('cejas') || extracted.contains('eyebrow') || extracted.contains('visagism')) {
                                    redirectToolId = 'eyebrow-visagism';
                                  } else if (extracted.contains('nails') && extracted.contains('style')) {
                                    redirectToolId = 'nails-style';
                                  } else {
                                    redirectToolId = extracted.replaceAll(' ', '-');
                                  }
                                  
                                  // Hide the metadata string from the visible message
                                  cleanText = text.replaceRange(redirectMatch.start, redirectMatch.end, '').trim();
                                }

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(
                                            right: 8, top: 4),
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                                          image: const DecorationImage(
                                            image: AssetImage('assets/images/avatar_aura.png'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.7,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3ECE6),
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(18),
                                                topRight: Radius.circular(18),
                                                bottomLeft: Radius.circular(4),
                                                bottomRight: Radius.circular(18),
                                              ),
                                              border: Border.all(color: const Color(0xFFE5DDD5)),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (isRec) ...[
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    child: Image.network(
                                                      'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=500',
                                                      height: 110,
                                                      width: double.infinity,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    'Asesoría de Belleza IA',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color:
                                                            Color(0xFFC89D93)),
                                                  ),
                                                  SizedBox(height: 4),
                                                ],
                                                Text(
                                                  cleanText,
                                                  style: TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 14.5,
                                                    height: 1.35,
                                                  ),
                                                ),
                                                if (redirectToolId != null) ...[
                                                  SizedBox(height: 10),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: OutlinedButton.icon(
                                                      style: OutlinedButton.styleFrom(
                                                        side: BorderSide(color: Color(0xFFC89D93), width: 1.5),
                                                        foregroundColor: const Color(0xFFC89D93),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(20),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                                      ),
                                                      icon: Icon(Icons.auto_awesome, size: 14),
                                                      label: Text(
                                                        'Abrir herramienta en Ideas IA',
                                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                      ),
                                                      onPressed: () {
                                                        // Navigate to /ideas using arguments to pre-load a tool
                                                        Navigator.pushNamed(
                                                          context,
                                                          '/ideas',
                                                          arguments: {'toolId': redirectToolId},
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                                if (isRec) ...[
                                                  SizedBox(height: 12),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                0xFFC89D93),
                                                        foregroundColor:
                                                            Colors.white,
                                                        elevation: 0,
                                                        shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20)),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                vertical: 8),
                                                      ),
                                                      onPressed: () {
                                                        final meta =
                                                            _parseAiRecommendation(
                                                                text);
                                                        final providerId =
                                                            meta['providerId'];
                                                        final serviceId =
                                                            meta['serviceId'];

                                                        if (providerId !=
                                                                null &&
                                                            providerId
                                                                .isNotEmpty) {
                                                          if (serviceId !=
                                                                  null &&
                                                              serviceId
                                                                  .isNotEmpty) {
                                                            final serviceItem =
                                                                {
                                                              'id': serviceId,
                                                              'name': meta[
                                                                      'serviceName'] ??
                                                                  'Tratamiento Recomendado',
                                                              'price': double.tryParse(
                                                                      meta['price'] ??
                                                                          '') ??
                                                                  0.0,
                                                              'duration_minutes':
                                                                  60,
                                                            };
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    BookingScreen(
                                                                  providerId:
                                                                      providerId,
                                                                  providerName:
                                                                      meta['providerName'] ??
                                                                          'Prestador',
                                                                  services: [
                                                                    serviceItem
                                                                  ],
                                                                  initialNotes:
                                                                      'Recomendado por el Asesor de Belleza IA.',
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (_) =>
                                                                    ProviderDetailScreen(
                                                                        providerId:
                                                                            providerId),
                                                              ),
                                                            );
                                                          }
                                                        } else {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (context) =>
                                                                    AlertDialog(
                                                              shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              24)),
                                                              title: Text(
                                                                  '¡De una parce!',
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold)),
                                                              content: Text(
                                                                  'Te redirigiremos con los prestadores de Fontibón para agendar este estilo de inmediato, vecino.'),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () {
                                                                    Navigator.pop(
                                                                        context);
                                                                    Navigator.pop(
                                                                        context, {
                                                                      'category': meta['serviceName'] ?? 'all',
                                                                      'serviceName': meta['serviceName'] ?? 'Servicio'
                                                                    });
                                                                  },
                                                                  child: Text(
                                                                      'Listo',
                                                                      style: TextStyle(
                                                                          color: Color(
                                                                              0xFFC89D93),
                                                                          fontWeight:
                                                                              FontWeight.bold)),
                                                                )
                                                              ],
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      icon: Icon(
                                                          Icons.calendar_month,
                                                          size: 14),
                                                      label: Text(
                                                          'Agendar este estilo',
                                                          style: TextStyle(
                                                              fontSize: 11.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ),
                                                  ),
                                                ],
                                                SizedBox(height: 4),
                                                Align(
                                                  alignment:
                                                      Alignment.bottomRight,
                                                  child: Text(
                                                    time,
                                                    style: TextStyle(
                                                      color: Colors.grey[500],
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                            0.75,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFFC89D93)
                                        : const Color(0xFFF3ECE6),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: isMe
                                          ? const Radius.circular(18)
                                          : const Radius.circular(4),
                                      bottomRight: isMe
                                          ? const Radius.circular(4)
                                          : const Radius.circular(18),
                                    ),
                                    border: isMe
                                        ? null
                                        : Border.all(color: const Color(0xFFE5DDD5)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        msg['message'] ?? '',
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 15,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        time,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white70
                                              : Colors.grey[500],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.black12, width: 0.5),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.grey[100],
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFC89D93),
                      child: _isSending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
