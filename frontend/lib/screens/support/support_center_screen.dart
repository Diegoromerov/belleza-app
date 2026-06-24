// frontend/lib/screens/support/support_center_screen.dart
import 'package:flutter/material.dart';
import '../../services/support_service.dart';
import '../../shared/theme.dart';
import 'create_ticket_screen.dart';
import 'ticket_chat_screen.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _tickets = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await SupportService.getMyTickets();
      if (res != null) {
        setState(() {
          _tickets = res;
        });
      } else {
        setState(() {
          _error = 'No se pudieron cargar los tickets.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ABIERTO':
        return Colors.blue.shade700;
      case 'EN_PROCESO':
        return AppTheme.warning;
      case 'ESPERANDO_RESPUESTA_USUARIO':
        return Colors.purple.shade700;
      case 'RESUELTO':
        return AppTheme.success;
      case 'CERRADO':
        return Colors.grey.shade600;
      default:
        return Colors.black87;
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toUpperCase()) {
      case 'ABIERTO':
        return Colors.blue.shade50;
      case 'EN_PROCESO':
        return AppTheme.warningBg;
      case 'ESPERANDO_RESPUESTA_USUARIO':
        return Colors.purple.shade50;
      case 'RESUELTO':
        return AppTheme.successBg;
      case 'CERRADO':
        return Colors.grey.shade100;
      default:
        return Colors.grey.shade50;
    }
  }

  String _formatStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'ABIERTO':
        return 'Abierto';
      case 'EN_PROCESO':
        return 'En Proceso';
      case 'ESPERANDO_RESPUESTA_USUARIO':
        return 'Esperando tu Respuesta';
      case 'RESUELTO':
        return 'Resuelto';
      case 'CERRADO':
        return 'Cerrado';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Centro de Soporte y PQRSF',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        color: AppTheme.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadTickets,
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                            child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                    ),
                  )
                : _tickets.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        itemCount: _tickets.length,
                        itemBuilder: (context, index) {
                          final ticket = _tickets[index];
                          final id = ticket['id'].toString();
                          final asunto = ticket['asunto']?.toString() ?? 'Sin Asunto';
                          final tipo = ticket['tipo']?.toString() ?? 'PETICION';
                          final estado = ticket['estado']?.toString() ?? 'ABIERTO';
                          final prioridad = ticket['prioridad']?.toString() ?? 'MEDIA';
                          final desc = ticket['descripcion']?.toString() ?? '';
                          final fechaStr = ticket['fecha_creacion']?.toString() ?? '';
                          final fecha = DateTime.tryParse(fechaStr)?.toLocal();
                          final formattedDate = fecha != null
                              ? '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}'
                              : '';

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TicketChatScreen(
                                    ticketId: id,
                                    ticketSubject: asunto,
                                    ticketStatus: estado,
                                  ),
                                ),
                              ).then((_) => _loadTickets());
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFF3EAE8)),
                                boxShadow: AppTheme.softShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _getStatusBgColor(estado),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          _formatStatusText(estado),
                                          style: TextStyle(
                                            color: _getStatusColor(estado),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    asunto,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, color: Color(0xFFF3EAE8)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Tipo: $tipo',
                                        style: const TextStyle(fontSize: 11, color: Colors.black54, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Prioridad: $prioridad',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: prioridad == 'EMERGENCIA' || prioridad == 'ALTA'
                                              ? Colors.red.shade700
                                              : Colors.black54,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
          ).then((_) => _loadTickets());
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Crear PQRSF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headset_mic_outlined, size: 64, color: AppTheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              '¿Tienes dudas, quejas o reclamos?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Registra una solicitud y un agente de soporte de Belleza App te ayudará en pocas horas.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CreateTicketScreen()),
                ).then((_) => _loadTickets());
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Crear Nueva Solicitud', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
