// lib/screens/profile/glowstore_orders_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';

class GlowStoreOrdersScreen extends StatelessWidget {
  const GlowStoreOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: LuxeColors.nude50,
        appBar: AppBar(
          backgroundColor: LuxeColors.nude50,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: LuxeColors.nude900, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'PEDIDOS GLOWSTORE',
            style: TextStyle(
              fontFamily: 'Didot',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: LuxeColors.nude900,
              letterSpacing: 1.2,
            ),
          ),
          centerTitle: true,
          bottom: const TabBar(
            indicatorColor: LuxeColors.nude900,
            labelColor: LuxeColors.nude900,
            unselectedLabelColor: LuxeColors.nude500,
            labelStyle: TextStyle(
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
            tabs: [
              Tab(text: 'EN CAMINO'),
              Tab(text: 'COMPLETADOS'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // PESTAÑA EN CAMINO
            ListView(
              padding: const EdgeInsets.all(LuxeSpacing.xl),
              children: [
                _buildOrderCard(
                  orderId: '#GLOW-98214',
                  date: '30 de Julio, 2026',
                  status: 'En Camino',
                  statusColor: const Color(0xFFC5A052),
                  items: 'Elixir Facial Biométrico Aura (50ml) + Suero Reparador',
                  total: '\$145.000 COP',
                  trackingNumber: 'GLW-TRACK-99120',
                ),
              ],
            ),
            // PESTAÑA COMPLETADOS
            ListView(
              padding: const EdgeInsets.all(LuxeSpacing.xl),
              children: [
                _buildOrderCard(
                  orderId: '#GLOW-87102',
                  date: '12 de Julio, 2026',
                  status: 'Entregado',
                  statusColor: const Color(0xFF4A5D4E),
                  items: 'Set Completo de Mascarillas de Seda & Miel',
                  total: '\$89.000 COP',
                  trackingNumber: 'GLW-TRACK-88291',
                ),
                _buildOrderCard(
                  orderId: '#GLOW-76193',
                  date: '25 de Junio, 2026',
                  status: 'Entregado',
                  statusColor: const Color(0xFF4A5D4E),
                  items: 'Crema Contorno de Ojos de Oro Rosa 24k',
                  total: '\$120.000 COP',
                  trackingNumber: 'GLW-TRACK-77312',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildOrderCard({
    required String orderId,
    required String date,
    required String status,
    required Color statusColor,
    required String items,
    required String total,
    required String trackingNumber,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LuxeColors.nude200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                orderId,
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude900,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            date,
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 13,
              color: LuxeColors.nude500,
            ),
          ),
          const Divider(height: 24, color: LuxeColors.nude100),
          Text(
            items,
            style: const TextStyle(
              fontFamily: 'Didot',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: LuxeColors.nude900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Guía: $trackingNumber',
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 10,
                  color: LuxeColors.nude600,
                ),
              ),
              Text(
                total,
                style: const TextStyle(
                  fontFamily: 'Didot',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
