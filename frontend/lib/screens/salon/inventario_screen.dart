// frontend/lib/screens/salon/inventario_screen.dart
// E-06 (D-GL-027) — Inventario operable del salón.
//
// El stock no se escribe desde aquí: se manda un movimiento (ENTRADA, SALIDA o
// AJUSTE) y el servidor recalcula el saldo en su transacción. Si la salida supera
// el stock, la pantalla muestra el rechazo del backend con el saldo real.

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../design/icons/glow_icon.dart';
import '../../services/api_service.dart';

class InventarioScreen extends StatefulWidget {
  final int salonId;
  final bool cargarDatos;
  final List<Map<String, dynamic>>? itemsIniciales;
  final bool? puedeEditarInicial;

  const InventarioScreen({
    super.key,
    required this.salonId,
    this.cargarDatos = true,
    this.itemsIniciales,
    this.puedeEditarInicial,
  });

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  List<Map<String, dynamic>> _items = const [];
  bool _puedeEditar = false;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _items = widget.itemsIniciales ?? const [];
    _puedeEditar = widget.puedeEditarInicial ?? false;
    if (widget.cargarDatos && widget.itemsIniciales == null) _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/api/salon/${widget.salonId}/inventario');
      if (!mounted) return;
      if (res is Map && res['success'] == true) {
        setState(() {
          _items = ((res['items'] as List?) ?? const [])
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
          _puedeEditar = res['puede_editar'] == true;
          _cargando = false;
        });
      } else {
        setState(() {
          _error = (res is Map ? res['error']?.toString() : null) ??
              'No se pudo leer el inventario.';
          _cargando = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con el inventario.';
        _cargando = false;
      });
    }
  }

  Future<void> _nuevoInsumo() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioInsumo(salonId: widget.salonId),
    );
    if (ok == true) _cargar();
  }

  Future<void> _mover(Map<String, dynamic> item) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioMovimiento(salonId: widget.salonId, item: item),
    );
    if (ok == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final t = Token.of(context);
    final bajos = _items.where((i) => i['stock_bajo'] == true).length;

    return Scaffold(
            appBar: AppBar(
                elevation: 0,
        title: Text(
          'Inventario',
          style: TypographyTokens.h3(t).copyWith(fontSize: 17, color: t.textPrimary),
        ),
      ),
      floatingActionButton: _puedeEditar
          ? FloatingActionButton.extended(
              onPressed: _nuevoInsumo,
              backgroundColor: t.brandPrimary,
              foregroundColor: t.brandPrimaryOn,
              icon: const Icon(Icons.add),
              label: const Text('Insumo'),
            )
          : null,
      body: _cargando && _items.isEmpty
          ? Center(child: CircularProgressIndicator(color: t.brandPrimary))
          : _error != null && _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_off_rounded, color: t.textSecondary, size: 30),
                        const SizedBox(height: Spacing.md),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TypographyTokens.bodySmall(t)
                              .copyWith(color: t.textSecondary),
                        ),
                        const SizedBox(height: Spacing.lg),
                        TextButton(onPressed: _cargar, child: const Text('Reintentar')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargar,
                  color: t.brandPrimary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.lg, Spacing.lg, Spacing.lg, Spacing.xxl + 56,
                    ),
                    children: [
                      if (bajos > 0)
                        Container(
                          margin: const EdgeInsets.only(bottom: Spacing.md),
                          padding: const EdgeInsets.all(Spacing.md),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC62828).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(Radii.sm),
                            border: Border.all(
                              color: const Color(0xFFC62828).withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 16, color: Color(0xFFC62828)),
                              const SizedBox(width: Spacing.xs),
                              Expanded(
                                child: Text(
                                  '$bajos insumo${bajos == 1 ? '' : 's'} en o bajo el mínimo',
                                  style: TypographyTokens.bodySmall(t).copyWith(
                                    color: const Color(0xFFC62828),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_items.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(Spacing.xl),
                          decoration: BoxDecoration(
                            color: t.surfaceLevel1,
                            borderRadius: BorderRadius.circular(Radii.md),
                            border: Border.all(color: t.borderSubtle),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  color: t.textSecondary, size: 26),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                'El inventario está vacío. '
                                'Registra el primer insumo para empezar a controlarlo.',
                                textAlign: TextAlign.center,
                                style: TypographyTokens.bodySmall(t)
                                    .copyWith(color: t.textSecondary),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._items.map((i) => _ItemTile(
                              item: i,
                              puedeEditar: _puedeEditar,
                              onMover: () => _mover(i),
                            )),
                    ],
                  ),
                ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool puedeEditar;
  final VoidCallback onMover;

  const _ItemTile({
    required this.item,
    required this.puedeEditar,
    required this.onMover,
  });

  @override
  Widget build(BuildContext context) {
    final t = Token.of(context);
    final bajo = item['stock_bajo'] == true;
    final stock = (item['stock_actual'] as num?) ?? 0;
    final minimo = (item['stock_minimo'] as num?) ?? 0;

    Widget numero(num n) => Text(
          n % 1 == 0 ? n.toInt().toString() : n.toString(),
          style: TypographyTokens.body(t).copyWith(
            fontWeight: FontWeight.w700,
            color: bajo ? const Color(0xFFC62828) : t.textPrimary,
            fontSize: 14,
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: t.surfaceLevel1,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: t.borderSubtle),
      ),
      child: Row(
        children: [
          GlowIcon.resolve('box',
              size: GlowIconSize.sm,
              color: bajo ? const Color(0xFFC62828) : t.textSecondary),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['nombre'] ?? ''}',
                  style: TypographyTokens.bodySmall(t).copyWith(
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                Text(
                  '${item['categoria'] ?? ''} · mínimo ${minimo % 1 == 0 ? minimo.toInt() : minimo} ${item['unidad'] ?? ''}'
                      .toLowerCase(),
                  style: TypographyTokens.bodySmall(t).copyWith(
                    color: t.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              numero(stock),
              Text(
                '${item['unidad'] ?? ''}'.toLowerCase(),
                style: TypographyTokens.bodySmall(t).copyWith(
                  color: t.textSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
          if (puedeEditar)
            IconButton(
              onPressed: onMover,
              icon: Icon(Icons.swap_vert_rounded, size: 18, color: t.brandPrimary),
              tooltip: 'Registrar entrada o salida',
            ),
        ],
      ),
    );
  }
}

class _FormularioInsumo extends StatefulWidget {
  final int salonId;
  const _FormularioInsumo({required this.salonId});

  @override
  State<_FormularioInsumo> createState() => _FormularioInsumoState();
}

class _FormularioInsumoState extends State<_FormularioInsumo> {
  final _nombre = TextEditingController();
  final _minimo = TextEditingController();
  final _costo = TextEditingController();
  String _categoria = 'INSUMO';
  String _unidad = 'UNIDAD';
  bool _enviando = false;
  String? _error;

  static const _categorias = ['INSUMO', 'PRODUCTO', 'HERRAMIENTA', 'OTRO'];
  static const _unidades = ['UNIDAD', 'LITRO', 'ML', 'KG', 'GR', 'CAJA'];

  @override
  void dispose() {
    _nombre.dispose();
    _minimo.dispose();
    _costo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().length < 2) {
      setState(() => _error = 'Escribe un nombre de al menos 2 caracteres.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });

    final res = await ApiService.post('/api/salon/${widget.salonId}/inventario', {
      'nombre': _nombre.text.trim(),
      'categoria': _categoria,
      'unidad': _unidad,
      'stock_minimo': num.tryParse(_minimo.text) ?? 0,
      if (_costo.text.trim().isNotEmpty) 'costo_unitario': num.tryParse(_costo.text),
    });

    if (!mounted) return;
    if (res is Map && res['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _enviando = false;
      _error = (res is Map ? res['error']?.toString() : null) ?? 'No se pudo crear el insumo.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Token.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(Spacing.xl),
        decoration: BoxDecoration(
          color: t.surfaceLevel1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nuevo insumo',
                style: TypographyTokens.h3(t).copyWith(fontSize: 16)),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _categoria,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: _categorias
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _categoria = v ?? _categoria),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unidad,
                    decoration: const InputDecoration(labelText: 'Unidad'),
                    items: _unidades
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _unidad = v ?? _unidad),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minimo,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Stock mínimo'),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: TextField(
                    controller: _costo,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Costo unitario'),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(_error!,
                  style: TypographyTokens.bodySmall(t)
                      .copyWith(color: const Color(0xFFC62828))),
            ],
            const SizedBox(height: Spacing.lg),
            _BotonPrimario(
              texto: 'Guardar',
              enviando: _enviando,
              onTap: _guardar,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormularioMovimiento extends StatefulWidget {
  final int salonId;
  final Map<String, dynamic> item;
  const _FormularioMovimiento({required this.salonId, required this.item});

  @override
  State<_FormularioMovimiento> createState() => _FormularioMovimientoState();
}

class _FormularioMovimientoState extends State<_FormularioMovimiento> {
  final _cantidad = TextEditingController();
  final _motivo = TextEditingController();
  String _tipo = 'ENTRADA';
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _cantidad.dispose();
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final cant = num.tryParse(_cantidad.text);
    if (cant == null || cant <= 0) {
      setState(() => _error = 'Escribe una cantidad mayor que cero.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });

    final res = await ApiService.post(
      '/api/salon/${widget.salonId}/inventario/${widget.item['id']}/movimientos',
      {
        'tipo': _tipo,
        'cantidad': cant,
        if (_motivo.text.trim().isNotEmpty) 'motivo': _motivo.text.trim(),
      },
    );

    if (!mounted) return;
    if (res is Map && res['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _enviando = false;
      _error = (res is Map ? res['error']?.toString() : null) ??
          'No se pudo registrar el movimiento.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Token.of(context);
    final stock = (widget.item['stock_actual'] as num?) ?? 0;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(Spacing.xl),
        decoration: BoxDecoration(
          color: t.surfaceLevel1,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.lg)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.item['nombre'] ?? 'Insumo'}',
              style: TypographyTokens.h3(t).copyWith(fontSize: 16),
            ),
            Text(
              'Stock actual: ${stock % 1 == 0 ? stock.toInt() : stock} ${widget.item['unidad'] ?? ''}'
                  .toLowerCase(),
              style: TypographyTokens.bodySmall(t).copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: Spacing.md),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ENTRADA', label: Text('Entrada')),
                ButtonSegment(value: 'SALIDA', label: Text('Salida')),
                ButtonSegment(value: 'AJUSTE', label: Text('Ajuste')),
              ],
              selected: {_tipo},
              onSelectionChanged: (s) => setState(() => _tipo = s.first),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _cantidad,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _tipo == 'AJUSTE' ? 'Stock contado' : 'Cantidad',
              ),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _motivo,
              decoration: const InputDecoration(
                labelText: 'Motivo (opcional)',
                hintText: 'Compra a proveedor, uso en servicio',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(_error!,
                  style: TypographyTokens.bodySmall(t)
                      .copyWith(color: const Color(0xFFC62828))),
            ],
            const SizedBox(height: Spacing.lg),
            _BotonPrimario(
              texto: 'Registrar',
              enviando: _enviando,
              onTap: _guardar,
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonPrimario extends StatelessWidget {
  final String texto;
  final bool enviando;
  final VoidCallback onTap;

  const _BotonPrimario({
    required this.texto,
    required this.enviando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Token.of(context);
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        onPressed: enviando ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: t.brandPrimary,
          foregroundColor: t.brandPrimaryOn,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.round)),
        ),
        child: enviando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(texto, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
