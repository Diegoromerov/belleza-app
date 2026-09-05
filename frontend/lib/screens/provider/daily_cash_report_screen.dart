// lib/screens/provider/daily_cash_report_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../design/components/luxe_components.dart';

class DailyCashReportScreen extends StatelessWidget {
  final double totalEfectivo;
  final double totalDatafono;
  final double totalTransferencias;
  final int totalCitasCompletadas;
  final List<Map<String, dynamic>> cierresDetalle;

  const DailyCashReportScreen({
    super.key,
    this.totalEfectivo = 350000,
    this.totalDatafono = 480000,
    this.totalTransferencias = 180000,
    this.totalCitasCompletadas = 8,
    this.cierresDetalle = const [
      {'cliente': 'Carlos Mendoza', 'servicio': 'Visagismo Barba & Corte', 'monto': 85000, 'metodo': '💵 Efectivo'},
      {'cliente': 'Laura Gómez', 'servicio': 'Tratamiento Piel Seda', 'monto': 140000, 'metodo': '💳 Datáfono Propio'},
      {'cliente': 'Ana Silva', 'servicio': 'Manicura Rusa Pro', 'monto': 65000, 'metodo': '📱 QR Nequi Directo'},
      {'cliente': 'María Rodríguez', 'servicio': 'Balayage & Peinado', 'monto': 220000, 'metodo': '💳 Datáfono Propio'},
      {'cliente': 'Daniela Ospina', 'servicio': 'Depilación Láser Rostro', 'monto': 120000, 'metodo': '💵 Efectivo'},
    ],
  });

  double get totalCaja => totalEfectivo + totalDatafono + totalTransferencias;

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
          'ARQUEO Y CIERRE DE CAJA SAAS',
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
              // BANNER TOTAL CAJA
              LuxeCard(
                padding: const EdgeInsets.all(24),
                backgroundColor: LuxeColors.nude900,
                child: Column(
                  children: [
                    const Text(
                      'TOTAL RECAUDADO HOY EN CAJA SAAS',
                      style: TextStyle(fontFamily: 'Didot', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${totalCaja.toStringAsFixed(0)} COP',
                      style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 28, fontWeight: FontWeight.bold, color: LuxeColors.gold871),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$totalCitasCompletadas Servicios Atendidos Hoy',
                      style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: LuxeColors.nude300),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: LuxeSpacing.xl),

              // DESGLOSE POR MÉTODO DE COBRO PROPIO
              const Text(
                'DESGLOSE POR CANAL DIRECTO',
                style: TextStyle(
                  fontFamily: 'Didot',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: LuxeColors.nude100, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          const Icon(Icons.payments_outlined, color: Color(0xFF059669), size: 22),
                          const SizedBox(height: 4),
                          const Text('Efectivo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('\$${totalEfectivo.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: LuxeColors.nude100, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          const Icon(Icons.credit_card_outlined, color: LuxeColors.gold871, size: 22),
                          const SizedBox(height: 4),
                          const Text('Datáfono', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('\$${totalDatafono.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: LuxeColors.nude100, borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        children: [
                          const Icon(Icons.qr_code_outlined, color: Color(0xFF2563EB), size: 22),
                          const SizedBox(height: 4),
                          const Text('Transferencia', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('\$${totalTransferencias.toStringAsFixed(0)}', style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: LuxeSpacing.xxl),

              // LISTADO DE SERVICIOS COBRADOS HOY
              const Text(
                'DETALLE DE COBROS DEL DÍA',
                style: TextStyle(
                  fontFamily: 'Didot',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: LuxeColors.nude900,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cierresDetalle.length,
                separatorBuilder: (_, __) => const Divider(color: LuxeColors.nude200, height: 1),
                itemBuilder: (context, index) {
                  final item = cierresDetalle[index];
                  final double amount = double.tryParse(item['monto']?.toString() ?? '0') ?? 0.0;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    title: Text(
                      item['servicio'] ?? 'Servicio Pro',
                      style: const TextStyle(fontFamily: 'CormorantGaramond', fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text('Cliente: ${item['cliente']} | ${item['metodo']}', style: const TextStyle(fontSize: 11, color: LuxeColors.nude600)),
                    trailing: Text(
                      '\$${amount.toStringAsFixed(0)}',
                      style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 14, fontWeight: FontWeight.bold, color: LuxeColors.nude900),
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
