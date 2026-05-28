// frontend/lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'services/api_service.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/web_geolocation.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/verification_pending_screen.dart';
import 'screens/provider_detail_screen.dart';
import 'screens/provider_dashboard_screen.dart';
import 'screens/client_bookings_screen.dart';
import 'screens/provider_services_screen.dart';
import 'screens/provider_portfolio_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/client_profile_screen.dart';
import 'screens/provider_profile_screen.dart';
import 'screens/booking_tracking_screen.dart';
import 'screens/provider_route_screen.dart';
import 'models/provider_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AnalyticsService().init();
  runApp(const BeautyApp());
}

class BeautyApp extends StatelessWidget {
  const BeautyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beauty App',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [AnalyticsRouteObserver()],
      theme: ThemeData(
        primaryColor: const Color(0xFFC89D93),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC89D93),
          primary: const Color(0xFFC89D93),
          secondary: const Color(0xFFE8D7D3),
          surface: Colors.white,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shadowColor: const Color(0x0A000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFFF3EAE8), width: 1),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home': (_) => const ProvidersScreen(),
        '/provider': (_) => const ProviderDashboardScreen(),
        '/client-bookings': (_) => const ClientBookingsScreen(),
        '/provider/services': (_) => const ProviderServicesScreen(),
        '/provider/portfolio': (_) => const ProviderPortfolioScreen(),
        '/provider/profile': (_) => const ProviderProfileScreen(),
        '/chat': (_) => const ChatListScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/verification-pending': (_) => const VerificationPendingScreen(),
        '/profile': (_) => const ClientProfileScreen(),
        '/booking-tracking': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return BookingTrackingScreen(booking: args);
        },
        '/provider-route': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ProviderRouteScreen(booking: args);
        },
      },
    );
  }
}

class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({super.key});

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  late final MapController _mapController;
  List<ProviderModel> _allProviders = [];
  List<ProviderModel> _filteredProviders = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;
  String? _errorMessage;

  String? _userRole;
  final TextEditingController _searchController = TextEditingController();
  final LatLng _fontibonCenter = const LatLng(4.6735, -74.1422);
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadProviders();
    _loadUserRole();
    _determineUserLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _determineUserLocation() async {
    try {
      final pos = await getWebGeolocation();
      final lat = pos['lat']!;
      final lon = pos['lon']!;
      if (mounted) {
        setState(() {
          _userLocation = LatLng(lat, lon);
        });
        _mapController.move(_userLocation!, 13.5);
        _loadProviders();
      }
    } catch (_) {}
  }

  Future<void> _loadProviders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final providers = await ApiService.fetchProvidersSecured(
        latitude: _userLocation?.latitude,
        longitude: _userLocation?.longitude,
      );
      if (!mounted) return;
      setState(() {
        _allProviders = providers;
        _filterProviders();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterProviders() {
    setState(() {
      _filteredProviders = _allProviders.where((p) => _providerMatchesCategory(p, _selectedCategory)).toList();
    });
  }

  bool _providerMatchesCategory(ProviderModel provider, String category) {
    if (category == 'all') return true;
    final desc = provider.description.toLowerCase();
    final biz = provider.businessName.toLowerCase();
    final name = provider.fullName.toLowerCase();
    
    if (category == 'hair') {
      return desc.contains('hair') || desc.contains('corte') || desc.contains('balayage') || biz.contains('hair') || biz.contains('corte') || name.contains('mari');
    }
    if (category == 'nails') {
      return desc.contains('nails') || desc.contains('manicur') || desc.contains('uña') || biz.contains('nails') || biz.contains('manicur') || name.contains('carlos');
    }
    if (category == 'makeup') {
      return desc.contains('makeup') || desc.contains('maquillaj') || biz.contains('makeup') || biz.contains('maquillaj');
    }
    return true;
  }

  Future<void> _loadUserRole() async {
    final token = await AuthService.getToken();
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length >= 2) {
          String payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
          while (payload.length % 4 != 0) {
            payload += '=';
          }
          final decoded = utf8.decode(base64.decode(payload));
          final data = json.decode(decoded);
          if (mounted) setState(() => _userRole = data['role']);
        }
      } catch (_) {}
    }
  }

  void _navigateToAIChat(String message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          partnerId: '00000000-0000-0000-0000-000000000000',
          partnerName: 'EstiloFonty IA',
          partnerRole: 'admin',
          partnerAvatar: '',
          initialMessage: message.trim().isNotEmpty ? message.trim() : null,
        ),
      ),
    );
  }

  void _showSOSConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
              SizedBox(width: 8),
              Text(
                '🚨 ALERTA SOS',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás en peligro o necesitas asistencia inmediata?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              ),
              SizedBox(height: 12),
              Text(
                'Al confirmar, se enviará una alerta silenciosa con tu ubicación actual a la central de seguridad de la plataforma y te daremos la opción de llamar directamente al número de emergencias (123).',
                style: TextStyle(fontSize: 13.5, height: 1.4, color: Colors.black54),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                Navigator.pop(context); // Cerrar diálogo primero
                await _triggerSOSAlert();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, size: 18),
                  SizedBox(width: 6),
                  Text('SÍ, ENVIAR SOS', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _triggerSOSAlert() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? activeBookingId;
      try {
        final clientBookings = await ApiService.fetchClientBookings();
        final inProgressBooking = clientBookings.firstWhere(
          (b) => (b['status'] as String? ?? '').toUpperCase() == 'EN_PROGRESO',
        );
        activeBookingId = inProgressBooking['id']?.toString();
      } catch (_) {
        // Ignorar si no hay citas en progreso o si falla la búsqueda
      }

      // Registrar evento de telemetría de botón SOS presionado
      final double lat = _userLocation?.latitude ?? _fontibonCenter.latitude;
      final double lon = _userLocation?.longitude ?? _fontibonCenter.longitude;

      AnalyticsService().logEvent(
        eventType: 'SOS_TRIGGERED',
        screenName: '/home',
        elementId: 'sos_client_fab',
        metadata: {
          'booking_id': activeBookingId,
          'latitude': lat,
          'longitude': lon,
        },
      );

      final res = await ApiService.triggerSOS(
        bookingId: activeBookingId,
        latitude: lat,
        longitude: lon,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      _showSOSTriggeredSheet(res['message'] ?? 'Alerta enviada correctamente.');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al enviar alerta SOS: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showSOSTriggeredSheet(String message) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Alerta SOS Registrada',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  elevation: 2,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📞 Marcando al 123 (Emergencias)...'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                },
                icon: const Icon(Icons.phone_in_talk_rounded),
                label: const Text(
                  'LLAMAR A EMERGENCIAS (123)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Color(0xFFE8D7D3), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Entendido / Cerrar',
                  style: TextStyle(color: Color(0xFFC89D93), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  void _showQuickViewSheet(ProviderModel provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE8D7D3),
                    backgroundImage: provider.avatarUrl.isNotEmpty ? NetworkImage(provider.avatarUrl) : null,
                    child: provider.avatarUrl.isEmpty
                        ? Text(
                            provider.fullName.isNotEmpty ? provider.fullName[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 20, color: Color(0xFFC89D93), fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.businessName.isNotEmpty ? provider.businessName : provider.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87, letterSpacing: -0.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (provider.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Color(0xFFC89D93), size: 18),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          provider.fullName,
                          style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EBE6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFC89D93), size: 15),
                        const SizedBox(width: 4),
                        Text(
                          provider.ratingAvg.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFC89D93)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                provider.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFC89D93), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'A ${(provider.distanceMeters / 1000).toStringAsFixed(1)} km en Fontibón',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Galería del Profesional',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              FutureBuilder<Map<String, dynamic>>(
                future: ApiService.fetchProviderDetails(provider.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 100,
                      child: Row(
                        children: List.generate(2, (index) => Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EBE6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC89D93)),
                              ),
                            ),
                          ),
                        )),
                      ),
                    );
                  }
                  final portfolio = (snapshot.data?['portfolio'] as List<dynamic>?) ?? [];
                  if (portfolio.isEmpty) {
                    return Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EBE6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'No hay fotos cargadas en el portafolio',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 110,
                    child: Row(
                      children: List.generate(portfolio.length > 2 ? 2 : portfolio.length, (idx) {
                        final item = portfolio[idx];
                        final imgUrl = item['image_url'] as String? ?? '';
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: idx == 0 ? 8 : 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                imgUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFF5EBE6),
                                  child: const Icon(Icons.broken_image, color: Color(0xFFC89D93)),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFC89D93), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              partnerId: provider.id,
                              partnerName: provider.businessName.isNotEmpty ? provider.businessName : provider.fullName,
                              partnerRole: 'provider',
                              partnerAvatar: provider.avatarUrl,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFC89D93), size: 18),
                      label: const Text(
                        'Chat Directo',
                        style: TextStyle(color: Color(0xFFC89D93), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC89D93),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProviderDetailScreen(providerId: provider.id),
                          ),
                        );
                      },
                      child: const Text(
                        'Ver Perfil Completo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'name': '💇‍♂️ Cabello', 'value': 'hair'},
      {'name': '💅 Uñas', 'value': 'nails'},
      {'name': '💄 Maquillaje', 'value': 'makeup'},
      {'name': '✨ Más', 'value': 'all'},
    ];
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final val = cat['value'] as String;
          final isSelected = _selectedCategory == val;
          return Container(
            margin: const EdgeInsets.only(right: 10),
            child: FilterChip(
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = val;
                  _filterProviders();
                });
                AnalyticsService().logEvent(
                  eventType: 'CATEGORY_FILTER_SELECTED',
                  screenName: '/home',
                  elementId: 'category_chip_$val',
                  metadata: {'category': val},
                );
              },
              label: Text(cat['name'] as String),
              selectedColor: const Color(0xFFC89D93),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE8D7D3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Capa 0: Mapa a pantalla completa centrado en Fontibón
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _fontibonCenter,
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.beautyapp.map',
              ),
              // Marcadores de prestadores en el mapa + marcador de ubicación del usuario
              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      width: 50,
                      height: 50,
                      point: _userLocation!,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1E88E5).withOpacity(0.2),
                          border: Border.all(color: const Color(0xFF1E88E5), width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.my_location, color: Color(0xFF1E88E5), size: 24),
                        ),
                      ),
                    ),
                  ..._filteredProviders.map((p) {
                    return Marker(
                    width: 60,
                    height: 60,
                    point: LatLng(p.latitude, p.longitude),
                    child: GestureDetector(
                      onTap: () => _showQuickViewSheet(p),
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
                              border: Border.all(color: const Color(0xFFC89D93), width: 3),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F000000),
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFF5EBE6),
                              backgroundImage: p.avatarUrl.isNotEmpty ? NetworkImage(p.avatarUrl) : null,
                              child: p.avatarUrl.isEmpty
                                  ? Text(
                                      p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 14, color: Color(0xFFC89D93), fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
            ],
          ),

          // Capa 1: Floating AI Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFE8D7D3), width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFFC89D93)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            hintText: '¿Qué look buscas hoy? EstiloFonty IA te asesora...',
                            hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey, overflow: TextOverflow.ellipsis),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              _navigateToAIChat(val);
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome, color: Color(0xFFC89D93)),
                        onPressed: () {
                          _navigateToAIChat(_searchController.text);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Capa 2: Filtros de Categorías M3
                _buildCategorySelector(),
              ],
            ),
          ),

          // Capa 3: Glassmorphic Floating Navigation Dock
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFE8D7D3).withOpacity(0.6), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Color(0xFFC89D93)),
                    onPressed: () => _navigateToAIChat(''),
                    tooltip: 'Asistente IA',
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFC89D93)),
                    onPressed: () => Navigator.pushNamed(context, '/chat'),
                    tooltip: 'Mensajes',
                  ),
                  if (_userRole == 'client') ...[
                    IconButton(
                      icon: const Icon(Icons.calendar_today_outlined, color: Color(0xFFC89D93)),
                      onPressed: () => Navigator.pushNamed(context, '/client-bookings'),
                      tooltip: 'Mis Citas',
                    ),
                  ]
                  else if (_userRole == 'provider') ...[
                    IconButton(
                      icon: const Icon(Icons.dashboard_outlined, color: Color(0xFFC89D93)),
                      onPressed: () => Navigator.pushNamed(context, '/provider'),
                      tooltip: 'Mi Panel',
                    ),
                    IconButton(
                      icon: const Icon(Icons.inventory_2_outlined, color: Color(0xFFC89D93)),
                      onPressed: () => Navigator.pushNamed(context, '/provider/services'),
                      tooltip: 'Mis Servicios',
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.person_outline_rounded, color: Color(0xFFC89D93)),
                    onPressed: () => Navigator.pushNamed(context, '/profile'),
                    tooltip: 'Mi Perfil',
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.grey),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await AuthService.logout();
                      navigator.pushReplacementNamed('/login');
                    },
                    tooltip: 'Cerrar Sesión',
                  ),
                ],
              ),
            ),
          ),

          // Capa: Botón Mi Ubicación
          Positioned(
            right: 20,
            bottom: 172,
            child: FloatingActionButton(
              heroTag: 'my_location_fab',
              onPressed: _determineUserLocation,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFC89D93),
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.my_location, size: 24),
            ),
          ),

          // Capa: Botón SOS para Cliente
          Positioned(
            right: 20,
            bottom: 104,
            child: FloatingActionButton(
              heroTag: 'sos_client_fab',
              onPressed: _showSOSConfirmationDialog,
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.emergency_outlined, size: 28),
            ),
          ),


          // Pantalla de carga superpuesta
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFC89D93)),
              ),
            ),

          // Alerta de Error
          if (_errorMessage != null)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.red[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No se pudo conectar: $_errorMessage',
                          style: TextStyle(color: Colors.red[800], fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        onPressed: _loadProviders,
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
