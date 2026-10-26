// lib/router/app_router.dart
// GoRouter based navigation for the Salon redesign.
// Uses BottomNavigationBar + Drawer (MainScaffold) as a shell.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:beauty_app/shared/theme.dart';
import 'package:beauty_app/screens/auth/login_screen.dart';
import 'package:beauty_app/screens/salon_dashboard_screen.dart';
import 'package:beauty_app/screens/salon/servicios_screen.dart';
import 'package:beauty_app/screens/salon/reservas_screen.dart';
import 'package:beauty_app/screens/salon/inventario_screen.dart';
import 'package:beauty_app/screens/profile/user_profile.dart';
import 'package:beauty_app/screens/superadmin/superadmin_screen.dart';
import 'package:beauty_app/services/secure_storage_service.dart';
import 'dart:async';

// -------------------------------------------------------------------
// Auth guard – redirects unauthenticated users to /login
// -------------------------------------------------------------------
FutureOr<String?> authRedirectGuard(BuildContext context, GoRouterState state) async {
  // Allow free access to the login route
  if (state.location == '/login') return null;
  // Read JWT from secure storage
  final token = await SecureStorageService().read('jwt');
  // If no token, force redirect to login
  if (token == null) return '/login';
  // Additional role‑based logic could be added here
  return null; // navigation allowed
}

final appRouter = GoRouter(
  initialLocation: '/login',
  redirect: authRedirectGuard,
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    // Shell route that hosts the MainScaffold with bottom nav + drawer
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        // Home placeholder (redirect to dashboard)
        GoRoute(
          path: '/home',
          redirect: (context, state) => '/salon/dashboard',
        ),
        // Salon section routes
        GoRoute(
          path: '/salon/dashboard',
          builder: (context, state) => const SalonDashboardScreen(),
        ),
        GoRoute(
          path: '/salon/servicios',
          builder: (context, state) => const ServiciosScreen(),
        ),
        GoRoute(
          path: '/salon/reservas',
          builder: (context, state) => const ReservasScreen(),
        ),
        GoRoute(
          path: '/salon/inventario',
          builder: (context, state) => const InventarioScreen(),
        ),
        GoRoute(
          path: '/salon/perfil',
          builder: (context, state) => const UserProfileScreen(),
        ),
        // Optional legacy redirects
        GoRoute(
          path: '/provider',
          redirect: (context, state) => '/salon/dashboard',
        ),
        GoRoute(
          path: '/superadmin',
          builder: (context, state) => const SuperAdminScreen(),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text(state.error?.toString() ?? 'Page not found')),
  ),
);

// -------------------------------------------------------------------
// MainScaffold – shell UI with BottomNavigationBar and Drawer
// -------------------------------------------------------------------
class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({required this.child, super.key});

  static const _navItems = [
    _NavItem(label: 'Dashboard', icon: Icons.dashboard, route: '/salon/dashboard'),
    _NavItem(label: 'Servicios', icon: Icons.design_services, route: '/salon/servicios'),
    _NavItem(label: 'Reservas', icon: Icons.event, route: '/salon/reservas'),
    _NavItem(label: 'Inventario', icon: Icons.inventory, route: '/salon/inventario'),
    _NavItem(label: 'Perfil', icon: Icons.person, route: '/salon/perfil'),
  ];

  int _calcSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).location;
    for (var i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calcSelectedIndex(context);
    return WillPopScope(key: const Key('mainScaffold'),
      onWillPop: () async {
        final scaffoldState = Scaffold.maybeOf(context);
        if (scaffoldState?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('BeautyApp')),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Text('Menú', style: TextStyle(color: Colors.white, fontSize: 24)),
              ),
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Analytics'),
                onTap: () => context.go('/superadmin'),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuración no implementada')),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Ayuda'),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ayuda no implementada')),
                ),
              ),
            ],
          ),
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: child,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey[600],
          onTap: (index) => context.go(_navItems[index].route),
          items: _navItems
              .map((item) => BottomNavigationBarItem(icon: Icon(item.icon), label: item.label))
              .toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;
  const _NavItem({required this.label, required this.icon, required this.route});
}
