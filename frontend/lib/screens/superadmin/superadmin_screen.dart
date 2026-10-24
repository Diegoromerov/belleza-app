// lib/screens/superadmin/superadmin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beauty_app/providers/superadmin_providers.dart';
import 'plans_screen.dart';
import 'revenue_screen.dart';
import 'superadmin_ui.dart';
import 'tenants_screen.dart';
import 'usage_screen.dart';

/// Consola de SuperAdmin: un solo punto de entrada con cuatro secciones.
///
/// La autorización NO se decide en el cliente: al montar se consulta el dashboard
/// y, si el backend responde 403, se muestra la pantalla de acceso restringido.
/// Adivinar el rol en el cliente dejaría la puerta abierta a que un usuario sin
/// permiso viera la interfaz y solo fallara al pedir datos.
class SuperAdminScreen extends ConsumerStatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  ConsumerState<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends ConsumerState<SuperAdminScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).load();
    });
  }

  static const _sections = <_Section>[
    _Section('Tenants', Icons.storefront_outlined, Icons.storefront),
    _Section('Ingresos', Icons.trending_up_outlined, Icons.trending_up),
    _Section('Uso', Icons.speed_outlined, Icons.speed),
    _Section('Planes', Icons.layers_outlined, Icons.layers),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);

    if (state.isForbidden) return const SaForbidden();

    final wide = MediaQuery.of(context).size.width >= 760;
    final body = IndexedStack(
      index: _index,
      children: const [
        TenantsScreen(),
        RevenueScreen(),
        UsageScreen(),
        PlansScreen(),
      ],
    );

    return Scaffold(
      backgroundColor: SaColors.bg,
      appBar: AppBar(
        backgroundColor: SaColors.bg,
        elevation: 0,
        foregroundColor: SaColors.ink,
        title: Row(
          children: [
            const Text('CONSOLA',
                style: TextStyle(fontSize: 10, letterSpacing: 2, color: SaColors.gold)),
            const SizedBox(width: 8),
            Text(_sections[_index].label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      body: WideOrNarrow(
        wide: wide,
        rail: NavigationRail(
          backgroundColor: SaColors.bg,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelType: NavigationRailLabelType.all,
          selectedIconTheme: const IconThemeData(color: SaColors.gold),
          selectedLabelTextStyle: const TextStyle(fontSize: 11, color: SaColors.gold),
          unselectedLabelTextStyle:
              const TextStyle(fontSize: 11, color: SaColors.muted),
          destinations: [
            for (final s in _sections)
              NavigationRailDestination(
                icon: Icon(s.icon, size: 20),
                selectedIcon: Icon(s.selectedIcon, size: 20),
                label: Text(s.label),
              ),
          ],
        ),
        body: body,
      ),
      bottomNavigationBar: wide
          ? null
          : BottomNavigationBar(
              currentIndex: _index,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: SaColors.gold,
              unselectedItemColor: SaColors.muted,
              backgroundColor: Colors.white,
              onTap: (i) => setState(() => _index = i),
              items: [
                for (final s in _sections)
                  BottomNavigationBarItem(icon: Icon(s.icon, size: 20), label: s.label),
              ],
            ),
    );
  }
}

/// Contenedor que pone el rail al lado en pantallas anchas y deja el cuerpo
/// a ancho completo con navegación inferior en móvil.
class WideOrNarrow extends StatelessWidget {
  final bool wide;
  final Widget rail;
  final Widget body;

  const WideOrNarrow({super.key, required this.wide, required this.rail, required this.body});

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: body,
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        rail,
        const VerticalDivider(width: 1, color: SaColors.line),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: body,
          ),
        ),
      ],
    );
  }
}

class _Section {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _Section(this.label, this.icon, this.selectedIcon);
}
