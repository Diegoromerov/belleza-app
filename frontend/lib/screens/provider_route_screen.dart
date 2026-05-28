// frontend/lib/screens/provider_route_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'chat_screen.dart';
import '../services/api_service.dart';

class ProviderRouteScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const ProviderRouteScreen({
    super.key,
    required this.booking,
  });

  @override
  State<ProviderRouteScreen> createState() => _ProviderRouteScreenState();
}

class _ProviderRouteScreenState extends State<ProviderRouteScreen> {
  // Coordenadas fijas del cliente en Fontibón
  final LatLng _clientLoc = const LatLng(4.6735, -74.1422);

  // Coordenadas iniciales del prestador
  late LatLng _providerLoc;

  double _progress = 0.0;
  Timer? _moveTimer;
  int _minutesRemaining = 8;
  bool _isArrived = false;
  bool _isStartingService = false;

  @override
  void initState() {
    super.initState();
    // Inicia un poco al noreste del cliente
    _providerLoc = const LatLng(4.6795, -74.1310);
    _startRouteSimulation();
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    super.dispose();
  }

  void _startRouteSimulation() {
    _moveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.1; // Incrementa 10% cada 2 segundos (20 segundos total)
          if (_progress > 1.0) _progress = 1.0;

          final double lat = 4.6795 + (_clientLoc.latitude - 4.6795) * _progress;
          final double lon = -74.1310 + (_clientLoc.longitude - (-74.1310)) * _progress;
          _providerLoc = LatLng(lat, lon);

          _minutesRemaining = (8 * (1.0 - _progress)).round();
          if (_minutesRemaining < 1) _minutesRemaining = 1;

          if (_progress >= 1.0) {
            _isArrived = true;
            HapticFeedback.lightImpact();
            _moveTimer?.cancel();
          }
        }
      });
    });
  }

  Future<void> _handleStartService() async {
    setState(() => _isStartingService = true);
    try {
      await ApiService.startBooking(widget.booking['id'].toString());
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.play_circle_fill, color: Colors.white),
                SizedBox(width: 8),
                Text('🚀 Servicio iniciado. ¡A dar el mejor look, vecino!'),
              ],
            ),
            backgroundColor: const Color(0xFFC89D93),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        );
        Navigator.pop(context, true); // Retorna true para refrescar el dashboard
      }
    } catch (e) {
      setState(() => _isStartingService = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al iniciar servicio: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String clientName = widget.booking['client_name'] ?? 'Cliente';
    final String serviceName = widget.booking['service_name'] ?? 'Servicio';
    final String clientId = widget.booking['client_id']?.toString() ?? '';
    final String serviceAddress = widget.booking['service_address']?.toString() ?? '';
    final String status = (widget.booking['status'] as String? ?? '').toUpperCase();
    final bool isInProgress = status == 'EN_PROGRESO';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Trayecto a Domicilio',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Stack(
        children: [
          // 1. Capa de Mapa (OSM via flutter_map)
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng((_clientLoc.latitude + _providerLoc.latitude) / 2, (_clientLoc.longitude + _providerLoc.longitude) / 2),
              initialZoom: 14.2,
            ),
            children: [
              TileLayer(
                urlTemplate: MapSettings.isDark
                    ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.beautyapp.map',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_providerLoc, _clientLoc],
                    color: const Color(0xFFC89D93),
                    strokeWidth: 4.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Marcador Cliente (Destino)
                  Marker(
                    width: 50,
                    height: 50,
                    point: _clientLoc,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.home_work, color: Colors.blueAccent, size: 28),
                    ),
                  ),
                  // Marcador Prestador (Origen móvil)
                  Marker(
                    width: 55,
                    height: 55,
                    point: _providerLoc,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFC89D93).withOpacity(0.3),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFC89D93), width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0, 3)),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFFF5EBE6),
                            child: Icon(Icons.content_cut, size: 18, color: Color(0xFFC89D93)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Capa Superior: Dirección y Cita Card
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.white,
              elevation: 4,
              shadowColor: const Color(0x12000000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: const BorderSide(color: Color(0xFFF3EAE8), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFC89D93), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            serviceAddress.isNotEmpty
                                ? serviceAddress
                                : 'Dirección pendiente por confirmar',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800], fontSize: 13.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF3EAE8)),
                    const SizedBox(height: 10),
                    Text(
                      'Servicio: $serviceName',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cliente: $clientName',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón Tema de Mapa (Claro/Oscuro Limpio)
          Positioned(
            right: 20,
            bottom: 220,
            child: FloatingActionButton(
              heroTag: 'map_theme_route_fab',
              onPressed: () {
                setState(() {
                  MapSettings.isDark = !MapSettings.isDark;
                });
              },
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFC89D93),
              elevation: 4,
              shape: const CircleBorder(),
              child: Icon(
                MapSettings.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 22,
              ),
            ),
          ),

          // 3. Capa Inferior: Drawer de Estado y Botón de Inicio
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              color: Colors.white,
              elevation: 6,
              shadowColor: const Color(0x1F000000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: Color(0xFFF3EAE8), width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFE8D7D3),
                          child: Text(
                            clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                            style: const TextStyle(fontSize: 16, color: Color(0xFFC89D93), fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isInProgress
                                    ? '⚡ Servicio en Progreso'
                                    : (_isArrived ? '🟢 Has llegado al destino' : '🚙 En camino al domicilio'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isInProgress
                                      ? Colors.purple[700]
                                      : (_isArrived ? Colors.green[700] : Colors.grey),
                                  fontWeight: isInProgress ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isArrived)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_minutesRemaining min',
                              style: TextStyle(fontSize: 14, color: Colors.red[900], fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const Divider(height: 24, color: Color(0xFFF3EAE8)),
                    Row(
                      children: [
                        // Botones rápidos de contacto

                        GestureDetector(
                          onTap: () {
                            if (clientId.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    partnerId: clientId,
                                    partnerName: clientName,
                                    partnerRole: 'client',
                                    partnerAvatar: '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: const CircleAvatar(
                            radius: 22,
                            backgroundColor: Color(0xFFC89D93),
                            child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Botón Iniciar Servicio
                        Expanded(
                          child: isInProgress
                              ? ElevatedButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFC89D93),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'Volver al Panel',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                )
                              : _isStartingService
                                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFC89D93)))
                                  : ElevatedButton(
                                      onPressed: _handleStartService,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFC89D93),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Iniciar Servicio',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),
                        ),
                      ],
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
}
