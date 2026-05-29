// frontend/lib/screens/wallet_screen.dart
// Pantalla de Wallet del Prestador: saldo, historial, retiros

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _wallet;
  List<dynamic> _transacciones = [];
  bool _loading = true;
  bool _loadingTx = false;
  String? _error;

  static final _formatCOP = NumberFormat.currency(
    locale: 'es_CO', symbol: '\$', decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarWallet();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarWallet() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.get('/api/wallet');
      setState(() { _wallet = res; _loading = false; });
      _cargarTransacciones();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _cargarTransacciones() async {
    setState(() { _loadingTx = true; });
    try {
      final res = await ApiService.get('/api/wallet/transactions?limit=30');
      setState(() {
        _transacciones = res['transacciones'] ?? [];
        _loadingTx = false;
      });
    } catch (_) {
      setState(() { _loadingTx = false; });
    }
  }

  Future<void> _solicitarRetiro() async {
    final wallet = _wallet!;
    final disponible = double.tryParse(wallet['saldo_disponible'].toString()) ?? 0;
    final minimo = double.tryParse(wallet['minimo_retiro_cop'].toString()) ?? 50000;

    final TextEditingController montoCtrl = TextEditingController(
      text: disponible.toStringAsFixed(0),
    );

    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RetiroBottomSheet(
        disponible: disponible,
        minimo: minimo,
        montoCtrl: montoCtrl,
        cuenta: '${wallet['banco'] ?? ''} ****${(wallet['numero_cuenta'] ?? '').toString().length > 4 ? wallet['numero_cuenta'].toString().substring(wallet['numero_cuenta'].toString().length - 4) : '????'}',
      ),
    );

    if (resultado == true) {
      try {
        final monto = double.parse(montoCtrl.text.replaceAll('.', '').replaceAll(',', ''));
        await ApiService.post('/api/wallet/withdraw', {'monto': monto});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Retiro solicitado. Llegarás en 1-2 días hábiles.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _cargarWallet();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE040FB)))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _cargarWallet, child: const Text('Reintentar')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final wallet = _wallet!;
    final disponible = double.tryParse(wallet['saldo_disponible'].toString()) ?? 0;
    final pendiente = double.tryParse(wallet['saldo_pendiente'].toString()) ?? 0;
    final enDisputa = double.tryParse(wallet['saldo_en_disputa'].toString()) ?? 0;
    final puedeRetirar = wallet['puede_retirar'] == true;
    final razonBloqueo = wallet['razon_bloqueo'] as String?;

    return RefreshIndicator(
      onRefresh: _cargarWallet,
      color: const Color(0xFFE040FB),
      child: CustomScrollView(
        slivers: [
          // ─── Header con saldo principal ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6B21A8), Color(0xFF1E1B4B)],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24, MediaQuery.of(context).padding.top + 16, 24, 32,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const Text(
                        'Mi Wallet',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                        onPressed: () => _mostrarConfigRetiro(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Saldo disponible',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCOP.format(disponible),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // ─── Saldos secundarios ─────────────────────────
                  Row(
                    children: [
                      _SaldoChip(
                        label: 'En camino',
                        monto: pendiente,
                        color: const Color(0xFFF59E0B),
                        icon: Icons.schedule,
                      ),
                      const SizedBox(width: 12),
                      _SaldoChip(
                        label: 'En disputa',
                        monto: enDisputa,
                        color: Colors.red,
                        icon: Icons.gavel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // ─── Botón de retiro ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: AnimatedOpacity(
                      opacity: puedeRetirar ? 1.0 : 0.7,
                      duration: const Duration(milliseconds: 300),
                      child: ElevatedButton.icon(
                        onPressed: puedeRetirar ? _solicitarRetiro : null,
                        icon: const Icon(Icons.account_balance_wallet),
                        label: Text(
                          puedeRetirar
                              ? 'Retirar ahora'
                              : razonBloqueo ?? 'No disponible',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: puedeRetirar
                              ? const Color(0xFFE040FB)
                              : Colors.white24,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!puedeRetirar && wallet['proxima_fecha_retiro'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Center(
                        child: Text(
                          'Próximo retiro: ${DateFormat('dd MMM, hh:mm a', 'es').format(DateTime.parse(wallet['proxima_fecha_retiro']))}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Tabs ─────────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabDelegate(
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFFE040FB),
                unselectedLabelColor: Colors.white54,
                indicatorColor: const Color(0xFFE040FB),
                tabs: const [
                  Tab(text: 'Movimientos'),
                  Tab(text: 'Resumen'),
                ],
              ),
            ),
          ),

          // ─── Contenido de tabs ────────────────────────────────────
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMovimientos(),
                _buildResumen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovimientos() {
    if (_loadingTx) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE040FB)));
    }
    if (_transacciones.isEmpty) {
      return const Center(
        child: Text('Sin movimientos aún', style: TextStyle(color: Colors.white54)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transacciones.length,
      itemBuilder: (ctx, i) => _TransaccionTile(tx: _transacciones[i]),
    );
  }

  Widget _buildResumen() {
    final wallet = _wallet!;
    final totalGanado = double.tryParse(wallet['total_ganado'].toString()) ?? 0;
    final totalRetirado = double.tryParse(wallet['total_retirado'].toString()) ?? 0;
    final modelo = wallet['modelo_retiro'] ?? 'DEMANDA';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _ResumenCard(
          titulo: 'Total ganado',
          monto: totalGanado,
          icon: Icons.trending_up,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(height: 12),
        _ResumenCard(
          titulo: 'Total retirado',
          monto: totalRetirado,
          icon: Icons.arrow_upward,
          color: const Color(0xFFE040FB),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Modelo de retiro',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                _nombreModelo(modelo),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _descripcionModelo(modelo),
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (wallet['cuenta_verificada'] == true)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF10B981)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cuenta verificada',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(
                      '${wallet['banco'] ?? ''} ****${wallet['numero_cuenta'].toString().length > 4 ? wallet['numero_cuenta'].toString().substring(wallet['numero_cuenta'].toString().length - 4) : ''}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _nombreModelo(String modelo) {
    switch (modelo) {
      case 'QUINCENA': return 'Automático cada 15 días';
      case 'MENSUAL':  return 'Automático mensual';
      default:         return 'Por demanda';
    }
  }

  String _descripcionModelo(String modelo) {
    switch (modelo) {
      case 'QUINCENA': return 'Retiro automático los días 15 y último del mes';
      case 'MENSUAL':  return 'Retiro automático el último día de cada mes';
      default:         return 'Retira cuando quieras, mín. \$50.000 cada 3 días';
    }
  }

  Future<void> _mostrarConfigRetiro() async {
    final wallet = _wallet;
    if (wallet == null) return;

    String modeloSeleccionado = wallet['modelo_retiro'] ?? 'DEMANDA';

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Modelo de retiro',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...[
                ('DEMANDA', 'Por demanda', 'Cada 3 días, mín. \$50.000'),
                ('QUINCENA', 'Cada 15 días', 'Automático los días 15 y último del mes'),
                ('MENSUAL', 'Mensual', 'Automático el último día del mes'),
              ].map((m) => RadioListTile<String>(
                value: m.$1,
                groupValue: modeloSeleccionado,
                activeColor: const Color(0xFFE040FB),
                title: Text(m.$2, style: const TextStyle(color: Colors.white)),
                subtitle: Text(m.$3, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                onChanged: (v) => setModalState(() => modeloSeleccionado = v!),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    try {
                      await ApiService.put('/api/wallet/model', {'modelo': modeloSeleccionado});
                      _cargarWallet();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Modelo actualizado'), backgroundColor: Color(0xFF10B981)),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE040FB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── WIDGETS AUXILIARES ────────────────────────────────────────────────────────

class _SaldoChip extends StatelessWidget {
  final String label;
  final double monto;
  final Color color;
  final IconData icon;

  const _SaldoChip({required this.label, required this.monto, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: color, fontSize: 10)),
                  Text(
                    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(monto),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransaccionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransaccionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final tipo = tx['tipo'] as String;
    final esCredito = tipo.startsWith('CREDITO') || tipo == 'LIBERACION_DISPUTA' || tipo == 'BONO_CANCELACION';
    final monto = double.tryParse(tx['monto'].toString()) ?? 0;
    final fecha = tx['created_at'] != null
        ? DateFormat('dd MMM, hh:mm a', 'es').format(DateTime.parse(tx['created_at']))
        : '';

    final (icono, color, titulo) = switch (tipo) {
      'CREDITO_SERVICIO'    => (Icons.arrow_downward, const Color(0xFF10B981), 'Servicio completado'),
      'DEBITO_RETIRO'       => (Icons.arrow_upward, const Color(0xFFE040FB), 'Retiro'),
      'RETENCION_DISPUTA'   => (Icons.gavel, Colors.orange, 'Fondos retenidos'),
      'LIBERACION_DISPUTA'  => (Icons.check_circle, const Color(0xFF10B981), 'Disputa resuelta'),
      'BONO_CANCELACION'    => (Icons.card_giftcard, Colors.blue, 'Bono recibido'),
      'AJUSTE_ADMIN'        => (Icons.tune, Colors.grey, 'Ajuste administrativo'),
      _                     => (Icons.swap_horiz, Colors.white54, tipo),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                if (tx['servicio_nombre'] != null)
                  Text(tx['servicio_nombre'], style: const TextStyle(color: Colors.white54, fontSize: 12)),
                Text(fecha, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '${esCredito ? '+' : '-'}${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(monto)}',
            style: TextStyle(
              color: esCredito ? const Color(0xFF10B981) : const Color(0xFFE040FB),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final double monto;
  final IconData icon;
  final Color color;

  const _ResumenCard({required this.titulo, required this.monto, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(color: Colors.white60, fontSize: 13)),
              Text(
                NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(monto),
                style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── BOTTOM SHEET RETIRO ──────────────────────────────────────────────────────

class _RetiroBottomSheet extends StatelessWidget {
  final double disponible;
  final double minimo;
  final TextEditingController montoCtrl;
  final String cuenta;

  const _RetiroBottomSheet({
    required this.disponible,
    required this.minimo,
    required this.montoCtrl,
    required this.cuenta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 20),
          const Text('Solicitar retiro',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Disponible: ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(disponible)}',
            style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 20),
          TextField(
            controller: montoCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(color: Color(0xFFE040FB), fontSize: 24, fontWeight: FontWeight.bold),
              helperText: 'Mínimo: ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(minimo)}',
              helperStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: Colors.white54, size: 18),
                const SizedBox(width: 10),
                Text(cuenta, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '⏱ El dinero llegará en 1-2 días hábiles. La plataforma asume el costo de transferencia.',
            style: TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE040FB),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirmar retiro',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
        ],
      ),
    );
  }
}

// ─── TAB DELEGATE ─────────────────────────────────────────────────────────────

class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabDelegate(this.tabBar);

  @override double get minExtent => tabBar.preferredSize.height;
  @override double get maxExtent => tabBar.preferredSize.height;
  @override bool shouldRebuild(covariant _TabDelegate oldDelegate) => false;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0F0F1A),
      child: tabBar,
    );
  }
}
