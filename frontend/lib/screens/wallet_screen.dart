// frontend/lib/screens/wallet_screen.dart
// Pantalla de Wallet del Prestador: saldo, historial, retiros

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class WalletScreen extends StatefulWidget {
  final bool isEmbedded;
  const WalletScreen({super.key, this.isEmbedded = false});

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

  // Pagination fields
  int _currentPage = 1;
  bool _hasMore = true;
  bool _loadingMore = false;

  static final _formatCOP = NumberFormat.currency(
    locale: 'es_CO', symbol: '\$', decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      _cargarTransacciones(loadMore: false);
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _cargarTransacciones({bool loadMore = false}) async {
    if (loadMore) {
      if (_loadingMore || !_hasMore) return;
      setState(() { _loadingMore = true; });
    } else {
      setState(() { _loadingTx = true; _currentPage = 1; _hasMore = true; });
    }
    try {
      final res = await ApiService.get('/api/wallet/transactions?page=$_currentPage&limit=15');
      final newTxs = res['transacciones'] ?? [];
      final pagination = res['pagination'];
      final total = pagination != null ? (pagination['total'] ?? 0) : 0;

      setState(() {
        if (loadMore) {
          _transacciones.addAll(newTxs);
        } else {
          _transacciones = newTxs;
        }
        _hasMore = _transacciones.length < total && newTxs.isNotEmpty;
        if (_hasMore) {
          _currentPage++;
        }
        _loadingTx = false;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() { _loadingTx = false; _loadingMore = false; });
    }
  }

  Future<void> _solicitarRetiro() async {
    final wallet = _wallet!;
    final disponible = double.tryParse(wallet['saldo_disponible'].toString()) ?? 0;
    final minimo = double.tryParse(wallet['minimo_retiro_cop'].toString()) ?? 50000;

    final TextEditingController montoCtrl = TextEditingController(
      text: disponible.toStringAsFixed(0),
    );

    final String targetCuenta = '${wallet['banco'] ?? ''} ****${(wallet['numero_cuenta'] ?? '').toString().length > 4 ? wallet['numero_cuenta'].toString().substring(wallet['numero_cuenta'].toString().length - 4) : '????'}';

    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RetiroBottomSheet(
        disponible: disponible,
        minimo: minimo,
        montoCtrl: montoCtrl,
        cuenta: targetCuenta,
      ),
    );

    if (resultado == true) {
      if (!mounted) return;
      // 2-step confirmation dialog
      final double montoFinal = double.parse(montoCtrl.text.replaceAll('.', '').replaceAll(',', ''));
      final bool? verificado = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            '¿Confirmar retiro?',
            style: TextStyle(color: Color(0xFF4A3E3D), fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Estás a punto de retirar ${_formatCOP.format(montoFinal)} a tu cuenta $targetCuenta. Esta acción no se puede deshacer.',
            style: const TextStyle(color: Color(0xFF8E7D7A), fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8E7D7A))),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC89D93),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirmar Retiro'),
            ),
          ],
        ),
      );

      if (verificado == true) {
        if (!mounted) return;
        try {
          await ApiService.post('/api/wallet/withdraw', {'monto': montoFinal});
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Retiro solicitado. Llegará en 1-2 días hábiles.'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC89D93)))
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.isEmbedded
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFC89D93)),
                onPressed: () => Navigator.pop(context),
              ),
        title: const Text(
          'Error de Wallet',
          style: TextStyle(
            color: Color(0xFFC89D93),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFF4A3E3D), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC89D93),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
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
      color: const Color(0xFFC89D93),
      child: CustomScrollView(
        slivers: [
          // ─── Header con saldo principal ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFC89D93), Color(0xFFE8D7D3)],
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
                      if (!widget.isEmbedded)
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
                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                        onPressed: () => _mostrarConfigRetiro(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Saldo disponible',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
                              ? Colors.white
                              : Colors.white38,
                          foregroundColor: puedeRetirar
                              ? const Color(0xFFC89D93)
                              : Colors.black26,
                          elevation: puedeRetirar ? 2 : 0,
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
                          style: const TextStyle(color: Colors.white, fontSize: 12),
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
                labelColor: const Color(0xFFC89D93),
                unselectedLabelColor: const Color(0xFF8E7D7A),
                indicatorColor: const Color(0xFFC89D93),
                tabs: const [
                  Tab(text: 'Movimientos'),
                  Tab(text: 'Retiros'),
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
                _buildRetirosTab(),
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFFC89D93)));
    }
    if (_transacciones.isEmpty) {
      return const Center(
        child: Text('Sin movimientos aún', style: TextStyle(color: Color(0xFF8E7D7A), fontSize: 14)),
      );
    }

    int itemCount = _transacciones.length;
    if (_hasMore || _loadingMore) {
      itemCount++;
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (ctx, i) {
        if (i == _transacciones.length) {
          if (_loadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator(color: Color(0xFFC89D93))),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: OutlinedButton(
              onPressed: () => _cargarTransacciones(loadMore: true),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC89D93)),
                foregroundColor: const Color(0xFFC89D93),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cargar más movimientos', style: TextStyle(fontSize: 14)),
            ),
          );
        }
        return _TransaccionTile(tx: _transacciones[i]);
      },
    );
  }

  Widget _buildRetirosTab() {
    final retiros = _transacciones.where((tx) => tx['tipo'] == 'DEBITO_RETIRO').toList();
    if (_loadingTx) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFC89D93)));
    }
    if (retiros.isEmpty) {
      return const Center(
        child: Text(
          'Sin retiros aún',
          style: TextStyle(color: Color(0xFF8E7D7A), fontSize: 14),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: retiros.length,
      itemBuilder: (ctx, i) {
        final tx = retiros[i];
        final monto = double.tryParse(tx['monto'].toString()) ?? 0;
        final fecha = tx['created_at'] != null
            ? DateFormat('dd MMM, hh:mm a', 'es').format(DateTime.parse(tx['created_at']))
            : '';
        final estadoRaw = (tx['estado'] ?? '').toString().toUpperCase();

        String estadoTexto = 'Solicitado';
        Color estadoColor = Colors.orange;
        if (estadoRaw == 'COMPLETADO' || estadoRaw == 'ACREDITADO') {
          estadoTexto = 'Acreditado';
          estadoColor = const Color(0xFF10B981);
        } else if (estadoRaw == 'PENDIENTE') {
          estadoTexto = 'Procesando';
          estadoColor = Colors.blue;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: const Color(0xFFF7ECE9)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFC89D93).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Color(0xFFC89D93), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Retiro solicitado',
                      style: TextStyle(color: Color(0xFF4A3E3D), fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(fecha, style: const TextStyle(color: Color(0xFF8E7D7A), fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '-${_formatCOP.format(monto)}',
                    style: const TextStyle(
                      color: Color(0xFF4A3E3D),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      estadoTexto,
                      style: TextStyle(
                        color: estadoColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
          color: const Color(0xFFC89D93),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF7ECE9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Modelo de retiro',
                style: TextStyle(color: Color(0xFF8E7D7A), fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                _nombreModelo(modelo),
                style: const TextStyle(
                  color: Color(0xFF4A3E3D),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _descripcionModelo(modelo),
                style: const TextStyle(color: Color(0xFF8E7D7A), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (wallet['cuenta_verificada'] == true)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981).withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified, color: Color(0xFF10B981)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cuenta verificada',
                      style: TextStyle(color: Color(0xFF4A3E3D), fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(
                      '${wallet['banco'] ?? ''} ****${wallet['numero_cuenta'].toString().length > 4 ? wallet['numero_cuenta'].toString().substring(wallet['numero_cuenta'].toString().length - 4) : ''}',
                      style: const TextStyle(color: Color(0xFF8E7D7A), fontSize: 12),
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
      backgroundColor: Colors.white,
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
                style: TextStyle(color: Color(0xFF4A3E3D), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...[
                ('DEMANDA', 'Por demanda', 'Cada 3 días, mín. \$50.000'),
                ('QUINCENA', 'Cada 15 días', 'Automático los días 15 y último del mes'),
                ('MENSUAL', 'Mensual', 'Automático el último día del mes'),
              ].map((m) => RadioListTile<String>(
                value: m.$1,
                groupValue: modeloSeleccionado,
                activeColor: const Color(0xFFC89D93),
                title: Text(m.$2, style: const TextStyle(color: Color(0xFF4A3E3D))),
                subtitle: Text(m.$3, style: const TextStyle(color: Color(0xFF8E7D7A), fontSize: 12)),
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
                    backgroundColor: const Color(0xFFC89D93),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Guardar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: color, fontSize: 12)),
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
      'DEBITO_RETIRO'       => (Icons.arrow_upward, const Color(0xFFC89D93), 'Retiro'),
      'RETENCION_DISPUTA'   => (Icons.gavel, Colors.orange, 'Fondos retenidos'),
      'LIBERACION_DISPUTA'  => (Icons.check_circle, const Color(0xFF10B981), 'Disputa resuelta'),
      'BONO_CANCELACION'    => (Icons.card_giftcard, Colors.blue, 'Bono recibido'),
      'AJUSTE_ADMIN'        => (Icons.tune, Colors.grey, 'Ajuste administrativo'),
      _                     => (Icons.swap_horiz, Colors.grey, tipo),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF7ECE9)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(color: Color(0xFF4A3E3D), fontWeight: FontWeight.w600, fontSize: 14)),
                if (tx['servicio_nombre'] != null)
                  Text(tx['servicio_nombre'], style: const TextStyle(color: Color(0xFF8E7D7A), fontSize: 12)),
                Text(fecha, style: const TextStyle(color: Color(0xFF8E7D7A), fontSize: 12)),
              ],
            ),
          ),
          Text(
            '${esCredito ? '+' : '-'}${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(monto)}',
            style: TextStyle(
              color: esCredito ? const Color(0xFF10B981) : const Color(0xFFC89D93),
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
              Text(titulo, style: const TextStyle(color: Color(0xFF8E7D7A), fontSize: 13)),
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

class _RetiroBottomSheet extends StatefulWidget {
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
  State<_RetiroBottomSheet> createState() => _RetiroBottomSheetState();
}

class _RetiroBottomSheetState extends State<_RetiroBottomSheet> {
  void _setPercent(double percent) {
    final amount = (widget.disponible * percent).floor();
    setState(() {
      widget.montoCtrl.text = amount.toString();
    });
  }

  Widget _buildPercentButton(double percent, String label) {
    return ElevatedButton(
      onPressed: () => _setPercent(percent),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFF7ECE9),
        foregroundColor: const Color(0xFFC89D93),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE8D7D3)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 20),
          const Text('Solicitar retiro',
            style: TextStyle(color: Color(0xFF4A3E3D), fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Disponible: ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(widget.disponible)}',
            style: const TextStyle(color: Color(0xFF8E7D7A), fontSize: 14)),
          const SizedBox(height: 16),
          // Quick selector buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPercentButton(0.25, '25%'),
              _buildPercentButton(0.50, '50%'),
              _buildPercentButton(1.0, '100%'),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.montoCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Color(0xFF4A3E3D), fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixText: '\$ ',
              prefixStyle: const TextStyle(color: Color(0xFFC89D93), fontSize: 24, fontWeight: FontWeight.bold),
              helperText: 'Mínimo: ${NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(widget.minimo)}',
              helperStyle: const TextStyle(color: Color(0xFF8E7D7A), fontSize: 12),
              filled: true,
              fillColor: const Color(0xFFFAF5F4),
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
              color: const Color(0xFFFAF5F4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF7ECE9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance, color: Color(0xFFC89D93), size: 18),
                const SizedBox(width: 10),
                Text(widget.cuenta, style: const TextStyle(color: Color(0xFF4A3E3D), fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '⏱ El dinero llegará en 1-2 días hábiles. La plataforma asume el costo de transferencia.',
            style: TextStyle(color: Color(0xFF8E7D7A), fontSize: 12),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC89D93),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Confirmar retiro',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF8E7D7A), fontSize: 14)),
            ),
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
      color: Colors.white,
      child: tabBar,
    );
  }
}
