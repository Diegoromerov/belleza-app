// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../core/theme/belleza_luxe_gradients.dart';
import '../../design/components/luxe_components.dart';
import '../../widgets/home/hero_section.dart';
import '../../widgets/home/recent_scan_card.dart';
import '../../widgets/store/product_card.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final VoidCallback? onOpenBiometricScanner;
  final VoidCallback? onOpenStore;
  final VoidCallback? onOpenAcademy;

  const HomeScreen({
    super.key,
    this.userName = 'Valeria',
    this.onOpenBiometricScanner,
    this.onOpenStore,
    this.onOpenAcademy,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  final List<Map<String, dynamic>> _recommendedProducts = [
    {
      'id': 101,
      'nombre': 'Sérum Botánico Elixir Aura',
      'precio': 145000,
      'categoria': 'Skincare',
      'sku': 'SKU-AURA-01',
      'is_premium': true,
    },
    {
      'id': 102,
      'nombre': 'Crema Nutritiva de Seda Andina',
      'precio': 189000,
      'categoria': 'Tratamiento',
      'sku': 'SKU-AURA-02',
      'is_premium': false,
    },
  ];

  void _onQuickAccessTap(VoidCallback? action) {
    HapticFeedback.lightImpact(); // Feedback háptico ligero
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxeColors.nude50,
      appBar: AppBar(
        backgroundColor: LuxeColors.nude50,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'GLOWAPP LUXE',
          style: TextStyle(
            fontFamily: 'Didot',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: LuxeColors.nude900),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: LuxeColors.nude900),
            onPressed: widget.onOpenStore,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: LuxeSpacing.xl, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HERO SECTION DASHBOARD
              HeroSection(
                userName: widget.userName,
                skinScore: 88.5,
                skinStatus: 'Luminosidad Óptima (Subtono Cálido)',
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // 2. ÚLTIMO DIAGNÓSTICO BIOMÉTRICO
              RecentScanCard(
                dateText: 'Hace 2 días',
                subtono: 'CÁLIDO',
                estacion: 'OTOÑO',
                hydrationPercent: 78,
                onTap: widget.onOpenBiometricScanner,
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // 3. ACCESOS RÁPIDOS A MÓDULOS (TIENDA, ACADEMIA, RITUALES)
              const Text(
                'ACCESOS RÁPIDOS AL RITUAL',
                style: TextStyle(
                  fontFamily: 'Didot',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: LuxeCard(
                      onTap: () => _onQuickAccessTap(widget.onOpenBiometricScanner),
                      child: const Column(
                        children: [
                          Icon(Icons.camera_front_outlined, size: 28, color: LuxeColors.gold871),
                          SizedBox(height: 8),
                          Text(
                            'Biometría',
                            style: TextStyle(fontFamily: 'Didot', fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: LuxeSpacing.lg),
                  Expanded(
                    child: LuxeCard(
                      onTap: () => _onQuickAccessTap(widget.onOpenStore),
                      child: const Column(
                        children: [
                          Icon(Icons.storefront_outlined, size: 28, color: LuxeColors.gold871),
                          SizedBox(height: 8),
                          Text(
                            'GlowStore',
                            style: TextStyle(fontFamily: 'Didot', fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: LuxeSpacing.lg),
                  Expanded(
                    child: LuxeCard(
                      onTap: () => _onQuickAccessTap(widget.onOpenAcademy),
                      child: const Column(
                        children: [
                          Icon(Icons.school_outlined, size: 28, color: LuxeColors.gold871),
                          SizedBox(height: 8),
                          Text(
                            'Academia',
                            style: TextStyle(fontFamily: 'Didot', fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // 4. BANNER PROMOCIONAL / EVENTOS CON LUXEBUTTON OUTLINED
              Container(
                padding: const EdgeInsets.all(LuxeSpacing.xl),
                decoration: BoxDecoration(
                  color: LuxeColors.nude100,
                  borderRadius: BorderRadius.circular(LuxeSpacing.md),
                  border: Border.all(color: LuxeColors.nude200, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MASTERCLASS EXCLUSIVA',
                            style: TextStyle(fontFamily: 'Didot', fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Diagnóstico dermo-estético avanzado en vivo.',
                            style: LuxeTypography.bodySm,
                          ),
                        ],
                      ),
                    ),
                    LuxeButton(
                      label: 'Reservar',
                      variant: LuxeButtonVariant.outline,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // 5. GRID DE RECOMENDADOS EDITORIAL (2 Columnas, gap LuxeSpacing.lg = 10.5px)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECOMENDACIONES DE AURA',
                    style: TextStyle(
                      fontFamily: 'Didot',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: LuxeColors.nude900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onOpenStore,
                    child: const Text('Ver todos', style: TextStyle(color: LuxeColors.gold871, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: LuxeSpacing.lg,
                  mainAxisSpacing: LuxeSpacing.lg,
                ),
                itemCount: _recommendedProducts.length,
                itemBuilder: (context, index) {
                  final p = _recommendedProducts[index];
                  return ProductCard(
                    product: p,
                    onAddToCart: () {},
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),

      // 6. NAVBAR INFERIOR EDITORIAL LUXE
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: LuxeColors.nude50,
          border: Border(top: BorderSide(color: LuxeColors.nude200, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) {
            setState(() {
              _currentNavIndex = index;
            });
            if (index == 1) widget.onOpenBiometricScanner?.call();
            if (index == 2) widget.onOpenStore?.call();
            if (index == 3) widget.onOpenAcademy?.call();
          },
          backgroundColor: LuxeColors.nude50,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: LuxeColors.gold871,
          unselectedItemColor: LuxeColors.nude500,
          selectedLabelStyle: const TextStyle(fontFamily: 'CormorantGaramond', fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontFamily: 'CormorantGaramond', fontSize: 11),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home, color: LuxeColors.gold871),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_front_outlined),
              activeIcon: Icon(Icons.camera_front, color: LuxeColors.gold871),
              label: 'Biometría',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront, color: LuxeColors.gold871),
              label: 'GlowStore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school, color: LuxeColors.gold871),
              label: 'Academia',
            ),
          ],
        ),
      ),
    );
  }
}
