// frontend/lib/main.dart
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/services.dart';
import 'package:beauty_app/l10n/app_localizations.dart';

import 'services/api_service.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/web_geolocation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'services/secure_storage_service.dart';
import 'services/audience_service.dart';
import 'design/icons/glow_icon_registry_init.dart';
import 'design/icons/glow_icon.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'widgets/audience_toggle.dart';
import 'shared/mens_theme.dart';
import 'shared/theme.dart';

import 'services/notification_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/verification_pending_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/accept_invitation_screen.dart';
import 'screens/auth/context_selection_screen.dart';
import 'screens/provider_detail_screen.dart';
import 'screens/home/providers_screen.dart';
import 'screens/provider_dashboard_screen.dart';
import 'screens/salon_dashboard_screen.dart';
import 'screens/salon/salon_hub_screen.dart';
import 'screens/client_bookings_screen.dart';
import 'screens/provider_services_screen.dart';
import 'screens/provider_portfolio_screen.dart';
import 'screens/chat_list_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile/user_profile.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/wallet_screen.dart';
import 'screens/profile/my_glow_dashboard_screen.dart';
import 'screens/provider_profile_screen.dart';
import 'screens/booking_tracking_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/provider_route_screen.dart';
import 'screens/ideas/welcome_screen.dart';
import 'screens/support/support_center_screen.dart';
import 'screens/support/terms_conditions_screen.dart';
import 'screens/disputes/disputes_list_screen.dart';
import 'screens/disputes/open_dispute_screen.dart';
import 'screens/academy/academy_screen.dart';
import 'screens/store_screen.dart';
import 'screens/designs/evolution_dashboard_screen.dart';
import 'screens/ideas/makeup_lookbook_screen.dart';
import 'models/provider_model.dart';
import 'shared/theme.dart';
import 'glowguide/glowguide.dart';
import 'glowguide/contracts/navigation_delegate.dart';
import 'glowguide/contracts/screen_visibility.dart';
import 'glowguide/audio/audio_engine.dart';
import 'glowguide/persistence/persistence_engine.dart';
import 'glowguide/observer/screen_visibility_observer.dart';

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('🔴 [FLUTTER ERROR DETECTED]: ${details.exception}');
    }
    AnalyticsService().logEvent(
      eventType: 'APP_CRASH_FLUTTER',
      screenName: 'global',
      metadata: {'error': details.exceptionAsString(), 'stack': details.stack.toString()},
    );
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFE91E63), size: 36),
              const SizedBox(height: 8),
              const Text(
                'Elemento no disponible temporalmente',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('es', null);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    AnalyticsService().init();
    await AppTheme.loadThemePreference();
    await AudienceService.init();
    GlowIconRegistryInit.initialize();
    runApp(const BeautyApp());
  }, (Object error, StackTrace stack) {
    if (kDebugMode) {
      print('🔴 [UNHANDLED ASYNC ERROR]: $error');
    }
    AnalyticsService().logEvent(
      eventType: 'APP_CRASH_ASYNC',
      screenName: 'global',
      metadata: {'error': error.toString(), 'stack': stack.toString()},
    );
  });
}

class BeautyApp extends StatelessWidget {
  const BeautyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppTheme.isModernTheme,
      builder: (context, isModern, child) {
        return ValueListenableBuilder<AudienceMode>(
          valueListenable: AudienceService.currentAudience,
          builder: (context, audienceMode, child) {
            final isMen = audienceMode == AudienceMode.men;

            final primaryColor = isMen ? MensTheme.champagneGold : AppTheme.primary;
            final bgColor = isMen ? MensTheme.obsidianBg : AppTheme.background;
            final surfaceColor = isMen ? MensTheme.obsidianCard : AppTheme.surface;
            final textColor = isMen ? MensTheme.textPrimary : AppTheme.text;

            GlowGuideService.instance.initialize();

            return MaterialApp(
              title: 'GlowApp',
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              navigatorKey: GlowGuideService.instance.navigatorKey,
              debugShowCheckedModeBanner: false,
              navigatorObservers: [AnalyticsRouteObserver(), ScreenVisibilityObserverSingleton.instance],
              builder: (context, child) {
                return Stack(
                  children: [
                    if (child != null) child,
                    if (GlowGuideService.instance.engine != null)
                      GlowGuidePresenter(
                        engine: GlowGuideService.instance.engine!,
                        onAction: (action) {
                          final engine = GlowGuideService.instance.engine!;
                          switch (action) {
                            case GlowGuidePresenterAction.next:
                              engine.next();
                              break;
                            case GlowGuidePresenterAction.previous:
                              engine.previous();
                              break;
                            case GlowGuidePresenterAction.dismiss:
                              engine.dismiss();
                              break;
                            case GlowGuidePresenterAction.replay:
                              engine.replay();
                              break;
                            case GlowGuidePresenterAction.pause:
                              engine.pause();
                              break;
                            case GlowGuidePresenterAction.resume:
                              engine.resume();
                              break;
                          }
                        },
                      ),
                  ],
                );
              },
                          theme: ThemeData(
                            brightness: isMen ? Brightness.dark : Brightness.light,
                            primaryColor: primaryColor,
                            colorScheme: ColorScheme.fromSeed(
                              brightness: isMen ? Brightness.dark : Brightness.light,
                              seedColor: primaryColor,
                              primary: primaryColor,
                              secondary: isMen ? MensTheme.bronzeAccent : AppTheme.accent,
                              surface: surfaceColor,
                              background: bgColor,
                            ),
                            scaffoldBackgroundColor: bgColor,
                            useMaterial3: true,
                            cardTheme: CardThemeData(
                              color: surfaceColor,
                              elevation: 0,
                              shadowColor: isMen ? Colors.black38 : const Color(0x0A8C6F65),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                                side: BorderSide(
                                  color: isMen
                                      ? MensTheme.champagneGold.withValues(alpha: 0.2)
                                      : const Color(0xFFE8E0D5), // LuxeColors.nude200
                                  width: 1,
                                ),
                              ),
                            ),
                            appBarTheme: AppBarTheme(
                              backgroundColor: surfaceColor,
                              foregroundColor: textColor,
                              elevation: 0,
                            ),
                            extensions: <ThemeExtension<dynamic>>[
                              GlowIconThemeExtension(isMenMode: isMen),
                            ],
                          ),
              initialRoute: '/home',
              routes: {
                // 1. Autenticación, Registro & Onboarding
                '/login': (_) => const LoginScreen(),
                '/register': (_) => const RegisterScreen(),
                '/forgot-password': (_) => const ForgotPasswordScreen(),
                '/accept-invitation': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  final token = args is String ? args : (args is Map ? (args['token']?.toString()) : null);
                  return AcceptInvitationScreen(token: token);
                },
                '/onboarding': (_) => const OnboardingScreen(),
                '/verification-pending': (_) => const VerificationPendingScreen(),
                '/context-selection': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments as List<dynamic>? ?? [];
                  return ContextSelectionScreen(availableContexts: args);
                },

                // 2. Destinos Principales por Segmentación de Rol
                '/home': (_) => const ProvidersScreen(),             // Rol CLIENTE (Catálogo / Búsqueda)
                '/my-glow': (_) => const MyGlowDashboardScreen(),   // Rol CLIENTE (Tablero VIP Ritual)
                '/provider': (_) => const ProviderDashboardScreen(), // Rol PRESTADOR (Tablero Pro Independiente)
                '/salon': (_) => const SalonDashboardScreen(),       // Rol SALON (Tablero SaaS Salón)
                '/salon-hub': (_) => const SalonHubScreen(),         // Hub Selector de Momento Empresarial (Dueño)

                // 3. Sub-Módulos del Prestador / Salón
                '/provider/services': (_) => const ProviderServicesScreen(),
                '/provider/portfolio': (_) => const ProviderPortfolioScreen(),
                '/provider/profile': (_) => const ProviderProfileScreen(),
                '/provider/academy': (_) => const AcademyScreen(),
                '/provider-route': (context) {
                  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                  return ProviderRouteScreen(booking: args);
                },

                // 4. Citas, Chat & Perfil
                '/client-bookings': (_) => const ClientBookingsScreen(),
                '/booking-tracking': (context) {
                  final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
                  return BookingTrackingScreen(booking: args);
                },
                '/chat': (_) => const ChatListScreen(),
                '/profile': (_) => const UserProfileScreen(),

                // 5. Soporte, Legal & Disputas
                '/support': (_) => const SupportCenterScreen(),
                '/terms': (_) => const TermsConditionsScreen(),
                '/disputes': (_) => const DisputesListScreen(),
                '/dispute': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
                  return OpenDisputeScreen(
                    preselectedBookingId: args?['booking_id'],
                  );
                },

                // 6. Diagnósticos IA, GlowStore & Módulos Visuales
                '/ideas': (_) => const BiometricWelcomeScreen(),
                '/store': (_) => const StoreScreen(),
                '/evolution': (_) => const EvolutionDashboardScreen(),
                '/makeup-lookbook': (_) => const MakeupLookbookScreen(),

                // 7. Rutas ya navegadas pero NO declaradas (A360-2026-09-22/C-09).
                //    Sin ellas, Navigator.pushNamed lanzaba "Could not find a
                //    generator for route".
                '/wallet': (_) => const WalletScreen(),
                '/settings': (context) {
                  // SettingsScreen exige userEmail; se toma del argumento real de
                  // la navegación. Si no viene, queda vacío (no se inventa).
                  final args = ModalRoute.of(context)?.settings.arguments;
                  final email = args is String
                      ? args
                      : (args is Map ? (args['email']?.toString() ?? '') : '');
                  return SettingsScreen(userEmail: email);
                },
                '/provider-detail': (context) {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  final providerId = args is String
                      ? args
                      : (args is Map ? args['provider_id']?.toString() : null);
                  if (providerId == null || providerId.trim().isEmpty) {
                    return const Scaffold(
                      body: Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'No se pudo identificar la proveedora solicitada.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }
                  return ProviderDetailScreen(providerId: providerId);
                },
              },
            );
          },
        );
      },
    );
  }
}
