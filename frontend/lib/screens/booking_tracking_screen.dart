// frontend/lib/screens/booking_tracking_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'chat_screen.dart';

class BookingTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingTrackingScreen({
    super.key,
    required this.booking,
  });

  @override
  State<BookingTrackingScreen> createState() => _BookingTrackingScreenState();
}

class _BookingTrackingScreenState extends State<BookingTrackingScreen> {
  // Coordenadas fijas del cliente en Fontibón
  final LatLng _clientLoc = const LatLng(4.6735, -74.1422);
  
  // Coordenadas iniciales del prestador (se irán acercando)
  late LatLng _providerLoc;
  
  // Progreso de interpolación (0.0 a 1.0)
  double _progress = 0.0;
  Timer? _moveTimer;
  int _minutesRemaining = 8;

  @override
  void initState() {
    super.initState();
    // Inicia un poco al noreste del cliente
    _providerLoc = const LatLng(4.6795, -74.1310);
    _startTrackingSimulation();
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    super.dispose();
  }

  void _startTrackingSimulation() {
    _moveTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) return;
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.05; // Incrementa el progreso en cada tick
          if (_progress > 1.0) _progress = 1.0;
          
          // Interpolación lineal simple entre la posición inicial y el cliente
          final double lat = 4.6795 + (_clientLoc.latitude - 4.6795) * _progress;
          final double lon = -74.1310 + (_clientLoc.longitude - (-74.1310)) * _progress;
          _providerLoc = LatLng(lat, lon);
          
          // Disminuir tiempo estimado progresivamente
          _minutesRemaining = (8 * (1.0 - _progress)).round();
          if (_minutesRemaining < 1) _minutesRemaining = 1;
        } else {
          _moveTimer?.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final String providerName = widget.booking['provider_name'] ?? 'Profesional';
    final String providerBusiness = widget.booking['provider_business_name'] ?? 'Studio Profesional';
    final String providerAvatar = widget.booking['provider_avatar_url'] ?? '';
    final String pin = widget.booking['pin_verificacion'] ?? '----';
    final String providerId = widget.booking['provider_id']?.toString() ?? '2';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Seguimiento en Vivo',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. Capa del Mapa (OSM via flutter_map)
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng((_clientLoc.latitude + _providerLoc.latitude) / 2, (_clientLoc.longitude + _providerLoc.longitude) / 2),
              initialZoom: 14.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.beautyapp.map',
              ),
              // Línea de Ruta (Polyline)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_providerLoc, _clientLoc],
                    color: const Color(0xFFC89D93),
                    strokeWidth: 4.5,
                  ),
                ],
              ),
              // Marcadores en el mapa
              MarkerLayer(
                markers: [
                  // Marcador de Ubicación del Cliente (Destino)
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
                  // Marcador de Ubicación del Prestador (Origen Animado)
                  Marker(
                    width: 55,
                    height: 55,
                    point: _providerLoc,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Círculo de pulso animado simulado
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
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFFF5EBE6),
                            backgroundImage: providerAvatar.isNotEmpty ? NetworkImage(providerAvatar) : null,
                            child: providerAvatar.isEmpty
                                ? const Icon(Icons.face_retouching_natural, size: 18, color: Color(0xFFC89D93))
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Capa Superior: Sticky Escrow Card
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
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.vpn_key, color: Color(0xFFC89D93), size: 22),
                        SizedBox(width: 8),
                        Text(
                          'PIN DE SEGURIDAD ESCROW',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EBE6),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        '🔑  $pin',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF881337),
                          letterSpacing: 4.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Compártelo con tu profesional solo al finalizar el servicio para liberar el pago',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey, height: 1.35),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Capa Inferior: Bottom Status Sheet (Fijo)
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: const Color(0xFFE8D7D3),
                          backgroundImage: providerAvatar.isNotEmpty ? NetworkImage(providerAvatar) : null,
                          child: providerAvatar.isEmpty
                              ? Text(
                                  providerName.isNotEmpty ? providerName[0].toUpperCase() : 'P',
                                  style: const TextStyle(fontSize: 18, color: Color(0xFFC89D93), fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                providerBusiness.isNotEmpty ? providerBusiness : providerName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                providerName,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        // Contador de tiempo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Llega en',
                                style: TextStyle(fontSize: 10, color: Colors.red[800], fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '$_minutesRemaining min',
                                style: TextStyle(fontSize: 15, color: Colors.red[900], fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28, color: Color(0xFFF3EAE8)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Wompi Badge
                        Row(
                          children: [
                            const Icon(Icons.shield, color: Colors.green, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Pago Wompi Protegido',
                              style: TextStyle(color: Colors.green[800], fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        // Call & Chat Floating Buttons
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      partnerId: providerId,
                                      partnerName: providerBusiness,
                                      partnerRole: 'provider',
                                      partnerAvatar: providerAvatar,
                                    ),
                                  ),
                                );
                              },
                              child: const CircleAvatar(
                                radius: 20,
                                backgroundColor: Color(0xFFC89D93),
                                child: Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                          ],
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
