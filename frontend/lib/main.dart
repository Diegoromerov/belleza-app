// frontend/lib/main.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/services.dart';

import 'services/api_service.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/web_geolocation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'services/secure_storage_service.dart';

import 'services/notification_service.dart';
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
import 'screens/designs/manicure_ideas_screen.dart';
import 'screens/support/support_center_screen.dart';
import 'screens/disputes/disputes_list_screen.dart';
import 'screens/academy/academy_screen.dart';
import 'models/provider_model.dart';
import 'shared/theme.dart';

import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  AnalyticsService().init();
  await AppTheme.loadThemePreference();
  runApp(const BeautyApp());
}

class BeautyApp extends StatelessWidget {
  const BeautyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isModernTheme,
      builder: (context, isModern, child) {
        return MaterialApp(
          title: 'GlowApp',
          navigatorKey: NotificationService.navigatorKey,
          debugShowCheckedModeBanner: false,
          navigatorObservers: [AnalyticsRouteObserver()],
          theme: ThemeData(
            primaryColor: AppTheme.primary,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppTheme.primary,
              primary: AppTheme.primary,
              secondary: AppTheme.accent,
              surface: AppTheme.surface,
              background: AppTheme.background,
            ),
            scaffoldBackgroundColor: AppTheme.background,
            useMaterial3: true,
            cardTheme: CardThemeData(
              color: AppTheme.surface,
              elevation: 0,
              shadowColor: const Color(0x0A8C6F65),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Color(0xFFF3EAE8), width: 1),
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.text,
              elevation: 0,
            ),
          ),
          initialRoute: '/home',
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
            '/ideas': (_) => const ManicureIdeasScreen(),
            '/booking-tracking': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return BookingTrackingScreen(booking: args);
            },
            '/provider-route': (context) {
              final args = ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
              return ProviderRouteScreen(booking: args);
            },
            '/support': (_) => const SupportCenterScreen(),
            '/disputes': (_) => const DisputesListScreen(),
            '/provider/academy': (_) => const AcademyScreen(),
          },
        );
      },
    );
  }
}

class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({super.key});

  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> with TickerProviderStateMixin {
  late final MapController _mapController;
  List<ProviderModel> _allProviders = [];
  List<ProviderModel> _filteredProviders = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;
  String? _errorMessage;

  bool _hasToken = false;
  String? _userRole;
  final TextEditingController _searchController = TextEditingController();
  final LatLng _bogotaCenter = const LatLng(4.6735, -74.1422);
  LatLng? _userLocation;

  bool _showTutorial = false;
  int _tutorialStep = 0;
  bool _isMapMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadProviders();
    _loadUserRole();
    _determineUserLocation();
    _checkTutorial();
  }

  Future<void> _checkTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seen_aura_tutorial') ?? false;
    if (!seen && mounted) {
      setState(() {
        _showTutorial = true;
        _tutorialStep = 0;
      });
    }
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_aura_tutorial', true);
    if (mounted) {
      setState(() {
        _showTutorial = false;
      });
      _searchController.clear();
      _animatedMapMove(_userLocation ?? _bogotaCenter, 13.5);
    }
  }

  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Animate map movement smoothly over 1000 milliseconds
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    final controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      if (mounted) {
        _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }



  void _handleTutorialStepChange(int newStep) {
    setState(() {
      _tutorialStep = newStep;
    });

    if (_tutorialStep == 1 && _filteredProviders.isNotEmpty) {
      final firstProv = _filteredProviders.first;
      _animatedMapMove(LatLng(firstProv.latitude, firstProv.longitude), 15.0);
    } else {
      _animatedMapMove(_userLocation ?? _bogotaCenter, 13.5);
    }
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
    } catch (_) {
      if (mounted) {
        _showManualLocationPicker();
      }
    }
  }

  void _showManualLocationPicker() {
    final addressController = TextEditingController(text: "Bogota, Colombia");
    bool resolving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Row(
                children: [
                  Icon(Icons.location_off, color: Color(0xFFC89D93), size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Ingresa tu Ubicación',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No pudimos acceder a tu GPS. Por favor escribe tu dirección, barrio o ciudad:',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección o Barrio',
                      hintText: 'Ej. Bogota, Colombia',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !resolving,
                  ),
                  if (resolving) ...[
                    SizedBox(height: 16),
                    Center(
                      child: CircularProgressIndicator(color: Color(0xFFC89D93)),
                    )
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: resolving ? null : () {
                    Navigator.pop(context);
                    setState(() {
                      _userLocation = _bogotaCenter;
                    });
                    _loadProviders();
                  },
                  child: Text('Usar Bogotá (Defecto)', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC89D93),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: resolving ? null : () async {
                    final address = addressController.text.trim();
                    if (address.isEmpty) return;

                    setStateModal(() {
                      resolving = true;
                    });

                    try {
                      // Obtener coordenadas a partir de texto
                      final locations = await geo.locationFromAddress(address);
                      if (locations.isNotEmpty) {
                        final firstLoc = locations.first;
                        Navigator.pop(context);
                        setState(() {
                          _userLocation = LatLng(firstLoc.latitude, firstLoc.longitude);
                        });
                        _mapController.move(_userLocation!, 13.5);
                        _loadProviders();
                      } else {
                        throw Exception('No locations found');
                      }
                    } catch (e) {
                      setStateModal(() {
                        resolving = false;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No pudimos localizar esa dirección. Intenta otra.')),
                      );
                    }
                  },
                  child: Text('Buscar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _loadProviders() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 1. Cargar datos cacheados localmente de SecureStorage para visualización inmediata
    try {
      final String? cachedJson = await SecureStorageService().read('cached_providers');
      if (cachedJson != null) {
        final List<dynamic> decoded = json.decode(cachedJson);
        final cachedProviders = decoded.map((jsonObj) => ProviderModel.fromJson(jsonObj)).toList();
        if (mounted) {
          setState(() {
            _allProviders = cachedProviders;
            _filterProviders();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error leyendo caché seguro local: $e');
    }

    // 2. Realizar la petición asíncrona de red para actualizar la información (con reintentos y retroceso exponencial)
    int retries = 0;
    const int maxRetries = 3;
    int delayMs = 1000;
    List<ProviderModel>? providers;
    
    while (retries < maxRetries) {
      try {
        providers = await ApiService.fetchProvidersSecured(
          latitude: _userLocation?.latitude,
          longitude: _userLocation?.longitude,
        );
        break;
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          if (!mounted) return;
          // Si ya cargó del caché no pisamos los datos con un error
          if (_allProviders.isEmpty) {
            setState(() {
              _errorMessage = 'Fallo de conexión tras varios intentos: ${e.toString()}';
              _isLoading = false;
            });
          } else {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sin conexión. Mostrando datos sin conexión.'),
                backgroundColor: Color(0xFFC89D93),
              ),
            );
          }
          return;
        }
        debugPrint('Fallo al cargar prestadores. Reintentando en ${delayMs}ms (Intento $retries de $maxRetries)...');
        await Future.delayed(Duration(milliseconds: delayMs));
        delayMs *= 2; // Retroceso exponencial
      }
    }

    if (providers != null) {
      if (!mounted) return;
      setState(() {
        _allProviders = providers!;
        _filterProviders();
        _isLoading = false;
      });

      // 3. Guardar en caché el nuevo listado usando SecureStorage
      try {
        final rawList = providers.map((p) => p.toJson()).toList();
        await SecureStorageService().write('cached_providers', json.encode(rawList));
      } catch (cacheErr) {
        debugPrint('Error guardando en caché segura: $cacheErr');
      }
    }
  }

  void _filterProviders() {
    setState(() {
      final query = _searchController.text.toLowerCase().trim();
      _filteredProviders = _allProviders.where((p) {
        final matchesCat = _providerMatchesCategory(p, _selectedCategory);
        if (query.isEmpty) return matchesCat;
        final matchesQuery = p.fullName.toLowerCase().contains(query) ||
            p.businessName.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query);
        return matchesCat && matchesQuery;
      }).toList();
    });
  }

  bool _providerMatchesCategory(ProviderModel provider, String category) {
    if (category == 'all') return true;
    final desc = provider.description.toLowerCase();
    final biz = provider.businessName.toLowerCase();
    final name = provider.fullName.toLowerCase();

    if (category == 'hair') {
      return desc.contains('hair') ||
          desc.contains('corte') ||
          desc.contains('balayage') ||
          biz.contains('hair') ||
          biz.contains('corte') ||
          name.contains('mari');
    }
    if (category == 'nails') {
      return desc.contains('nails') ||
          desc.contains('manicur') ||
          desc.contains('uña') ||
          biz.contains('nails') ||
          biz.contains('manicur') ||
          name.contains('carlos');
    }
    if (category == 'makeup') {
      return desc.contains('makeup') ||
          desc.contains('maquillaj') ||
          biz.contains('makeup') ||
          biz.contains('maquillaj');
    }
    return true;
  }

  Future<void> _loadUserRole() async {
    final token = await AuthService.getToken();
    if (mounted) {
      setState(() {
        _hasToken = token != null;
      });
    }
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
          if (mounted) {
            setState(() => _userRole = data['role']);
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _checkAuthAndNavigate(String routeName) async {
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) {
        Navigator.pushNamed(context, '/login');
      }
    } else {
      if (mounted) {
        final result = await Navigator.pushNamed(context, routeName);
        if (result != null && result is Map<String, dynamic>) {
          if (result['action'] == 'filter_map') {
            final category = result['category'] ?? 'all';
            setState(() {
              _selectedCategory = category;
              _filterProviders();
            });
            // Auto scroll or zoom to filtered providers if needed
            if (_filteredProviders.isNotEmpty) {
              _mapController.move(
                LatLng(_filteredProviders.first.latitude, _filteredProviders.first.longitude),
                14.5
              );
            }
          }
        }
      }
    }
  }



  void _navigateToAIChat(String message) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          partnerId: '00000000-0000-0000-0000-000000000000',
          partnerName: 'Asistente de Belleza & Tips IA',
          partnerRole: 'admin',
          partnerAvatar: '',
          initialMessage: message.trim().isNotEmpty ? message.trim() : null,
        ),
      ),
    );
  }

  /*
  void _showSOSConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626), size: 28),
              SizedBox(width: 8),
              Text(
                '🚨 ALERTA SOS',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Estás en peligro o necesitas asistencia inmediata?',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87),
              ),
              SizedBox(height: 12),
              Text(
                'Al confirmar, se enviará una alerta silenciosa con tu ubicación actual a la central de seguridad de la plataforma y te daremos la opción de llamar directamente al número de emergencias (123).',
                style: TextStyle(
                    fontSize: 13.5, height: 1.4, color: Colors.black54),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style:
                    TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                Navigator.pop(context); // Cerrar diálogo primero
                await _triggerSOSAlert();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, size: 18),
                  SizedBox(width: 6),
                  Text('SÍ, ENVIAR SOS',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
      final double lat = _userLocation?.latitude ?? _bogotaCenter.latitude;
      final double lon = _userLocation?.longitude ?? _bogotaCenter.longitude;

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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 52),
                SizedBox(height: 12),
                Text(
                  'Alerta SOS Registrada',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.black87),
                ),
                SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 14, height: 1.4),
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
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
                  icon: Icon(Icons.phone_in_talk_rounded),
                  label: Text(
                     'LLAMAR A EMERGENCIAS (123)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                SizedBox(height: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    side: BorderSide(color: Color(0xFFE8D7D3), width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Entendido / Cerrar',
                    style: TextStyle(
                        color: Color(0xFFC89D93), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  */

  void _showQuickViewSheet(ProviderModel provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
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
              SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE8D7D3),
                    backgroundImage: provider.avatarUrl.isNotEmpty
                        ? NetworkImage(provider.avatarUrl)
                        : null,
                    child: provider.avatarUrl.isEmpty
                        ? Text(
                            provider.fullName.isNotEmpty
                                ? provider.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                                fontSize: 20,
                                color: Color(0xFFC89D93),
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                provider.businessName.isNotEmpty
                                    ? provider.businessName
                                    : provider.fullName,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.black87,
                                    letterSpacing: -0.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (provider.isVerified) ...[
                              SizedBox(width: 4),
                              Icon(Icons.verified,
                                  color: Color(0xFFC89D93), size: 18),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          provider.fullName,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EBE6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.star,
                            color: Color(0xFFC89D93), size: 15),
                        SizedBox(width: 4),
                        Text(
                          provider.ratingAvg.toStringAsFixed(1),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFC89D93)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                provider.description,
                style: TextStyle(
                    color: Colors.grey[600], fontSize: 14, height: 1.4),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on,
                      color: Color(0xFFC89D93), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'A ${(provider.distanceMeters / 1000).toStringAsFixed(1)} km en Fontibón',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Galería del Profesional',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black87),
              ),
              SizedBox(height: 10),
              FutureBuilder<Map<String, dynamic>>(
                future: ApiService.fetchProviderDetails(provider.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SizedBox(
                      height: 100,
                      child: Row(
                        children: List.generate(
                            2,
                            (index) => Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5EBE6),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFC89D93)),
                                      ),
                                    ),
                                  ),
                                )),
                      ),
                    );
                  }
                  final portfolio =
                      (snapshot.data?['portfolio'] as List<dynamic>?) ?? [];
                  if (portfolio.isEmpty) {
                    return Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EBE6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
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
                      children: List.generate(
                          portfolio.length > 2 ? 2 : portfolio.length, (idx) {
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
                                  child: Icon(Icons.broken_image,
                                      color: Color(0xFFC89D93)),
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
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                            color: Color(0xFFC89D93), width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () async {
                        final token = await AuthService.getToken();
                        if (token == null) {
                          if (context.mounted) {
                            Navigator.pushNamed(context, '/login');
                          }
                          return;
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                partnerId: provider.id,
                                partnerName: provider.businessName.isNotEmpty
                                    ? provider.businessName
                                    : provider.fullName,
                                partnerRole: 'provider',
                                partnerAvatar: provider.avatarUrl,
                              ),
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.chat_bubble_outline_rounded,
                          color: Color(0xFFC89D93), size: 18),
                      label: Text(
                        'Chat Directo',
                        style: TextStyle(
                            color: Color(0xFFC89D93),
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC89D93),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProviderDetailScreen(providerId: provider.id),
                          ),
                        );
                      },
                      child: Text(
                        'Ver Perfil Completo',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
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
      {'name': 'Cabello', 'value': 'hair', 'icon': Icons.content_cut_outlined},
      {'name': 'Uñas', 'value': 'nails', 'icon': Icons.brush_outlined},
      {'name': 'Maquillaje', 'value': 'makeup', 'icon': Icons.face_retouching_natural_outlined},
      {'name': 'Todos', 'value': 'all', 'icon': Icons.auto_awesome_outlined},
    ];
    return SizedBox(
      height: 75,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final val = cat['value'] as String;
          final isSelected = _selectedCategory == val;
          final iconData = cat['icon'] as IconData;

          return GestureDetector(
            onTap: () {
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 20),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFFC89D93).withOpacity(0.15)
                          : Colors.grey.shade50,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFC89D93)
                            : Colors.grey.shade200,
                        width: 1.2,
                      ),
                    ),
                    child: Icon(
                      iconData,
                      size: 20,
                      color: isSelected
                          ? const Color(0xFFC89D93)
                          : Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFC89D93)
                          : Colors.grey.shade600,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavItem({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final resolvedColor = color ?? AppTheme.text;
    return Expanded(
      key: key,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: resolvedColor, size: 20),
              SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: resolvedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProminentCenterNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Transform.translate(
          offset: const Offset(0, -14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE8D7D3), // Golden soft rose
                      Color(0xFFC89D93), // Warm primary pink
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC89D93).withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 2.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB07D62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Capa 0: Mapa a pantalla completa centrado en Bogotá
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _bogotaCenter,
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: MapSettings.isDark
                    ? 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
                    : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                          color: AppTheme.primary.withOpacity(0.2),
                          border: Border.all(
                              color: AppTheme.primary, width: 2),
                        ),
                        child: Center(
                          child: Icon(Icons.my_location,
                              color: AppTheme.primary, size: 24),
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
                                color: AppTheme.primary.withOpacity(0.25),
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppTheme.primary, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x128C6F65),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFFF5EBE6),
                                backgroundImage: p.avatarUrl.isNotEmpty
                                    ? NetworkImage(p.avatarUrl)
                                    : null,
                                child: p.avatarUrl.isEmpty
                                    ? Text(
                                        p.fullName.isNotEmpty
                                            ? p.fullName[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: AppTheme.primary,
                                            fontWeight: FontWeight.bold),
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


          // Capa 1: Floating Transaccional Search Bar with Aura Trigger
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
                    color: AppTheme.surface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(30),
                    border:
                        Border.all(color: AppTheme.accent.withOpacity(0.4), width: 1.5),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          if (_searchController.text.trim().isNotEmpty) {
                            _navigateToAIChat(_searchController.text);
                          }
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.search, color: AppTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText:
                                '¿Qué servicio o estilista buscas? O pregunta a Aura...',
                            hintStyle: TextStyle(
                                fontSize: 13.5,
                                color: AppTheme.text,
                                overflow: TextOverflow.ellipsis),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              _navigateToAIChat(val);
                            }
                          },
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _navigateToAIChat(_searchController.text);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.auto_awesome, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                // El selector de categorías se ha ocultado conforme a los requerimientos UX
                // SizedBox(height: 12),
                // _buildCategorySelector(),
              ],
            ),
          ),

          // Capa 3: Glassmorphic Floating Navigation Dock (Consolidated 4-item layout)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface.withOpacity(0.92),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(
                    color: AppTheme.accent.withOpacity(0.4),
                    width: 1.5),
                boxShadow: AppTheme.glassShadow,
              ),
              child: Row(
                children: [
                   // Botón 1: Citas
                  _buildNavItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Citas',
                    onTap: () => _checkAuthAndNavigate('/client-bookings'),
                  ),

                  // Botón 2: Ideas (Botón central prominente)
                  _buildProminentCenterNavItem(
                    icon: Icons.lightbulb_outline_rounded,
                    label: 'Ideas',
                    onTap: () => _checkAuthAndNavigate('/ideas'),
                  ),

                  // Botón 3: Perfil
                  _buildNavItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Perfil',
                    onTap: () => _checkAuthAndNavigate('/profile'),
                  ),
                ],
              ),
            ),
          ),

          // Capa: Ajustes de Mapa (Speed Dial Expandible)
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 104,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_isMapMenuOpen) ...[
                  // Botón Tema de Mapa
                  FloatingActionButton.small(
                    heroTag: 'map_theme_main_fab',
                    onPressed: () {
                      setState(() {
                        MapSettings.isDark = !MapSettings.isDark;
                      });
                    },
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.primary,
                    elevation: 3,
                    shape: const CircleBorder(),
                    child: Icon(
                      MapSettings.isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Botón Mi Ubicación
                  FloatingActionButton.small(
                    heroTag: 'my_location_fab',
                    onPressed: _determineUserLocation,
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.primary,
                    elevation: 3,
                    shape: const CircleBorder(),
                    child: const Icon(Icons.my_location, size: 20),
                  ),
                  const SizedBox(height: 10),
                ],
                // Botón principal de menú expandible
                FloatingActionButton(
                  heroTag: 'map_settings_toggle_fab',
                  onPressed: () {
                    setState(() {
                      _isMapMenuOpen = !_isMapMenuOpen;
                    });
                  },
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shape: const CircleBorder(),
                  child: Icon(
                    _isMapMenuOpen ? Icons.close : Icons.layers_outlined,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Pantalla de carga superpuesta
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: Center(
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No se pudo conectar: $_errorMessage',
                          style:
                              TextStyle(color: Colors.red[800], fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: Colors.red),
                        onPressed: _loadProviders,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Capa: Tutorial interactivo guiado por Aura
          if (_showTutorial)
            _buildTutorialOverlay(),
        ],
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    final double topPadding = MediaQuery.of(context).padding.top;
    
    // Contenido dinámico según el paso (0 al 3)
    String stepTitle = '';
    String stepDescription = '';
    Widget? highlightWidget;
    Widget centerGraphic = SizedBox.shrink();

    if (_tutorialStep == 0) {
      stepTitle = '¡Te doy la bienvenida! 🌸';
      stepDescription = 'Hola, soy Aura, tu asistente personal de belleza. Permíteme guiarte en este recorrido interactivo por GlowApp.';
      centerGraphic = Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD4AF37), width: 3.5),
          image: const DecorationImage(
            image: AssetImage('assets/images/avatar_aura.png'),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else if (_tutorialStep == 1) {
      stepTitle = '1. Estilistas en el Mapa';
      stepDescription = 'Los estilistas disponibles cerca de tu zona se muestran como círculos con sus fotos. ¡Toca el marcador de Ana Silva para ver su perfil!';
      // Destacamos un marcador del mapa (simulando un toque)
      highlightWidget = Center(
        child: IgnorePointer(
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Icon(Icons.touch_app, color: Color(0xFFD4AF37), size: 36),
          ),
        ),
      );
    } else if (_tutorialStep == 2) {
      stepTitle = '2. Perfil Profesional y Portafolio';
      stepDescription = 'Explora la galería de fotos certificadas de trabajos anteriores, opiniones reales y su catálogo de servicios de belleza disponibles.';
      // Renderizamos el perfil detallado del proveedor simulado
      highlightWidget = Positioned(
        top: topPadding + 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).size.height * 0.45,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 90,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/logo_maestro_v5.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('assets/images/logo_maestro_v3.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ana Silva', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.text)),
                        Text('Estilista Capilar Profesional', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Servicios Disponibles:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.text),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildMockServiceTile('Corte de Cabello Dama', '\$45.000 COP'),
                    _buildMockServiceTile('Peinado Especial Fiesta', '\$60.000 COP'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_tutorialStep == 3) {
      stepTitle = '3. Reserva y Pago Seguro';
      stepDescription = 'Selecciona el día y la hora de tu conveniencia. El pago se procesa por Wompi Bancolombia en modo garantía: el dinero solo se libera cuando ingreses el PIN OTP al finalizar el servicio.';
      centerGraphic = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAEFEA),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF4A5D4E), width: 2),
        ),
        child: Column(
          children: [
            Icon(Icons.security, color: Color(0xFF4A5D4E), size: 48),
            SizedBox(height: 8),
            Text(
              'Transacción Segura de Pago',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A5D4E)),
            ),
            SizedBox(height: 4),
            Text(
              'Depósito de Garantía Wompi Activo\nMonto total: \$45.000 COP',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF4A5D4E)),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // Fondo translúcido que bloquea clics traseros
        GestureDetector(
          onTap: () {}, 
          child: Container(
            color: Colors.black.withOpacity(0.7),
          ),
        ),
        
        // Elemento destacado si aplica en el paso
        if (highlightWidget != null) highlightWidget,

        // Botón "Omitir" rápido en la esquina superior derecha
        Positioned(
          top: topPadding + 16,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'tutorial_skip_fab',
            onPressed: _completeTutorial,
            backgroundColor: Colors.white.withOpacity(0.9),
            foregroundColor: AppTheme.text,
            child: const Icon(Icons.close, size: 20),
          ),
        ),

        // Tarjeta interactiva de Aura (centrada en el paso 0, inferior en los demás)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          left: 20,
          right: 20,
          bottom: _tutorialStep == 0 
              ? MediaQuery.of(context).size.height * 0.25 
              : 20,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppTheme.accent.withOpacity(0.4), width: 1.5),
              boxShadow: AppTheme.glassShadow,
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: centerGraphic is! SizedBox 
                        ? Container(
                            key: ValueKey<int>(_tutorialStep),
                            margin: const EdgeInsets.only(bottom: 20),
                            child: centerGraphic,
                          )
                        : SizedBox.shrink(),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Row(
                      key: ValueKey<int>(_tutorialStep),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_tutorialStep > 0) ...[
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFD4AF37), width: 2.0),
                              image: const DecorationImage(
                                image: AssetImage('assets/images/avatar_aura.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stepTitle,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.text,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                stepDescription,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Indicador de progreso con 4 puntos interactivos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final bool isActive = _tutorialStep == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 12 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primary :  Color(0xFFE5CECA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _completeTutorial,
                        child: Text(
                          'Saltar',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (_tutorialStep > 0)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppTheme.accent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                onPressed: () => _handleTutorialStepChange(_tutorialStep - 1),
                                child: Text(
                                  'Atrás',
                                  style: TextStyle(color: AppTheme.text),
                                ),
                              ),
                            ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              if (_tutorialStep < 3) {
                                _handleTutorialStepChange(_tutorialStep + 1);
                              } else {
                                _completeTutorial();
                              }
                            },
                            child: Text(
                              _tutorialStep == 3 ? 'Finalizar' : 'Siguiente',
                              style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }

  // Helpers para los Mocks Visuales del Tutorial
  Widget _buildMockServiceTile(String title, String price) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text(price, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ],
        ),
      ),
    );
  }

  Widget _buildMockDayTile(String day, String dayName, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppTheme.primary : Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(day, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
          Text(dayName, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white70 : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildMockHourTile(String hour, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        hour,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black54),
      ),
    );
  }
}
