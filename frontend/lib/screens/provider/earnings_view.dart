// lib/screens/provider/earnings_view.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../design/components/luxe_components.dart';
import '../../widgets/provider/provider_luxe_components.dart';

class EarningsViewScreen extends StatelessWidget {
  final double totalEarnings;
  final double weeklyEarnings;
  final int completedServices;
  final List<Map<String, dynamic>> recentTransactions;

  const EarningsViewScreen({
    super.key,
    this.totalEarnings = 1450000,
    this.weeklyEarnings = 480000,
    this.completedServices = 18,
    this.recentTransactions = const [
      {'concepto': 'Corte & Visagismo - Cliente Juan', 'monto': 85000, 'fecha': 'Hoy 11:30 AM'},
      {'concepto': 'Tratamiento Piel Seda - Cliente Laura', 'monto': 140000, 'fecha': 'Ayer 4:00 PM'},
      {'concepto': 'Manicura Rusa - Cliente Ana', 'monto': 65000, 'fecha': '28 Jul'},
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LuxeColors.nude50,
      appBar: AppBar(
        backgroundColor: LuxeColors.nude50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: LuxeColors.nude900, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'INGRESOS Y RENDIMIENTO PRO',
          style: TextStyle(
            fontFamily: 'Didot',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: LuxeColors.nude900,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LuxeSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BANNER TOTAL DE INGRESOS
              LuxeCard(
                padding: const EdgeInsets.all(24),
                backgroundColor: LuxeColors.nude100,
                child: Column(
                  children: [
                    const Text(
                      'BALANCE TOTAL ACUMULADO',
                      style: TextStyle(fontFamily: 'Didot', fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${totalEarnings.toStringAsFixed(0)} COP',
                      style: LuxeTypography.monoMd.copyWith(fontSize: 28, color: LuxeColors.gold871),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Esta Semana', style: LuxeTypography.bodySm),
                            const SizedBox(height: 4),
                            Text('\$${weeklyEarnings.toStringAsFixed(0)}', style: LuxeTypography.monoSm.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Container(height: 24, width: 1, color: LuxeColors.nude200),
                        Column(
                          children: [
                            const Text('Servicios', style: LuxeTypography.bodySm),
                            const SizedBox(height: 4),
                            Text('$completedServices realizados', style: LuxeTypography.monoSm.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // HISTORIAL DE TRANSACCIONES RECIENTES
              const Text(
                'TRANSACCIONES RECIENTES',
                style: TextStyle(
                  fontFamily: 'Didot',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentTransactions.length,
                separatorBuilder: (_, __) => const Divider(color: LuxeColors.nude200, height: 1),
                itemBuilder: (context, index) {
                  final item = recentTransactions[index];
                  final double amount = double.tryParse(item['monto']?.toString() ?? '0') ?? 0.0;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: LuxeColors.nude100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward, color: LuxeColors.gold871, size: 20),
                    ),
                    title: Text(
                      item['concepto'] ?? 'Servicio',
                      style: const TextStyle(fontFamily: 'CormorantGaramond', fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(item['fecha'] ?? '', style: LuxeTypography.bodySm),
                    trailing: Text(
                      '+\$${amount.toStringAsFixed(0)}',
                      style: LuxeTypography.monoMd.copyWith(color: LuxeColors.gold871),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
