import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glowapp_frontend/providers/auth_provider.dart';
import 'package:glowapp_frontend/ui/screens/login_screen.dart';
import 'package:glowapp_frontend/ui/screens/home_screen.dart';
import 'package:glowapp_frontend/ui/screens/nback_screen.dart';
import 'package:glowapp_frontend/ui/screens/beauty_screen.dart';

/// Provider that creates the app router.
/// It redirects unauthenticated users to `/login` and authenticated users
/// away from the login page.
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authState.stream),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
        // Nested routes for Home
        routes: [
          GoRoute(
            path: 'nback',
            builder: (context, state) => const NBackScreen(),
          ),
          GoRoute(
            path: 'beauty',
            builder: (context, state) => const BeautyScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/home';
      return null;
    },
  );
});

/// Helper that bridges Riverpod's stream with GoRouter's refresh mechanism.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    stream.listen((_) => notifyListeners());
  }
}
