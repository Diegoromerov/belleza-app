// frontend/lib/screens/salon/alquileres_screen.dart
// E-06 (D-GL-027) — Recursos alquilables del salón (sillas, mesas, puestos).
//
// Lo que muestra sale de la API: recursos con su estado y, si están ocupados, a
// quién y desde cuándo. Alquilar exige el id de la persona; hoy se pide a mano
// porque el buscador de miembros todavía no está en esta pantalla (anotado como
// pendiente en T-125, no escondido).

import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../design/icons/glow_icon.dart';
import '../../services/api_service.dart';
import 'caja_screen.dart' show formatearCop;

class AlquileresScreen extends StatefulWidget {
  final int salonId;
  final bool cargarDatos;
  final List<Map<String, dynamic>>? recursosIniciales;
  final bool? puedeEditarInicial;

  const AlquileresScreen({
    super.key,
    required this.salonId,
    this.cargarDatos = true,
    this.recursosIniciales,
    this.puedeEditarInicial,
  });

  @override
  State<AlquileresScreen> createState() => _AlquileresScreenState();
}

class _AlquileresScreenState extends State<AlquileresScreen> {
  List<Map<String, dynamic>> _recursos = const [];
  bool _puedeEditar = false;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recursos = widget.recursosIniciales ?? const [];
    _puedeEditar = widget.puedeEditarInicial ?? false;
    if (widget.cargarDatos && widget.recursosIniciales == null) _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final res = await ApiService.get('/api/salon/${widget.salonId}/recursos');
      if (!mounted) return;
      if (res is Map && res['success'] == true) {
        setState(() {
          _recursos = ((res['items'] as List?) ?? const [])
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
          _puedeEditar = res['puede_editar'] == true;
          _cargando = false;
        });
      } else {
        setState(() {
          _error = (res is Map ? res['error']?.toString() : null) ??
              'No se pudieron leer los recursos.';
          _cargando = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo conectar con los recursos.';
        _cargando = false;
      });
    }
  }

  Future<void> _nuevo() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioRecurso(salonId: widget.salonId),
    );
    if (ok == true) _cargar();
  }

  Future<void> _alquilar(Map<String, dynamic> recurso) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioAlquiler(salonId: widget.salonId, recurso: recurso),
    );
    if (ok == true) _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final t = Token.of(context);

    return Scaffold(
            appBar: AppBar(
                elevation: 0,
        title: Text(
          'Recursos y alquileres',
          style: TypographyTokens.h3(t).copyWith(fontSize: 17, color: t.textPrimary),
        ),
      ),
      floatingActionButton: _puedeEditar
          ? FloatingActionButton.extended(
              onPressed: _nuevo,
              backgroundColor: t.brandPrimary,
              foregroundColor: t.brandPrimaryOn,
              icon: const Icon(Icons.add),
              label: const Text('Recurso'),
            )
          : null,
      body: _cargando && _recursos.isEmpty
          ? Center(child: CircularProgressIndicator(color: t.brandPrimary))
          : _error != null && _recursos.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.xxl),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TypographyTokens.bodySmall(t).copyWith(color: t.textSecondary),
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
                      if (_recursos.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(Spacing.xl),
                          decoration: BoxDecoration(
                            color: t.surfaceLevel1,
                            borderRadius: BorderRadius.circular(Radii.md),
                            border: Border.all(color: t.borderSubtle),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.chair_outlined, color: t.textSecondary, size: 26),
                              const SizedBox(height: Spacing.sm),
                              Text(
                                'Todavía no hay sillas, mesas ni puestos registrados.',
                                textAlign: TextAlign.center,
                                style: TypographyTokens.bodySmall(t)
                                    .copyWith(color: t.textSecondary),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._recursos.map((r) {
                          final ocupado = (r['estado'] ?? '') == 'OCUPADO';
                          final canon = (r['canon_mensual'] as num?) ?? 0;
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
                                GlowIcon.resolve('chair',
                                    size: GlowIconSize.sm,
                                    color: ocupado ? t.brandPrimary : t.textSecondary),
                                const SizedBox(width: Spacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${r['nombre'] ?? ''}',
                                        style: TypographyTokens.bodySmall(t).copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: t.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        [
                                          '${r['tipo'] ?? ''}'.toLowerCase(),
                                          canon > 0 ? '${formatearCop(canon)}/mes' : 'sin canon',
                                          if (ocupado && r['persona_id'] != null)
                                            'persona ${r['persona_id']}',
                                        ].join(' · '),
                                        style: TypographyTokens.bodySmall(t).copyWith(
                                          color: t.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_puedeEditar && !ocupado)
                                  TextButton(
                                    onPressed: () => _alquilar(r),
                                    child: const Text('Alquilar'),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (ocupado
                                              ? t.brandPrimary
                                              : t.textSecondary)
                                          .withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(Radii.sm),
                                    ),
                                    child: Text(
                                      '${r['estado'] ?? ''}'.toLowerCase(),
                                      style: TypographyTokens.bodySmall(t).copyWith(
                                        fontSize: 9,
                                        color: ocupado ? t.brandPrimary : t.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ),
                ),
    );
  }
}

class _FormularioRecurso extends StatefulWidget {
  final int salonId;
  const _FormularioRecurso({required this.salonId});

  @override
  State<_FormularioRecurso> createState() => _FormularioRecursoState();
}

class _FormularioRecursoState extends State<_FormularioRecurso> {
  final _nombre = TextEditingController();
  final _canon = TextEditingController();
  String _tipo = 'PUESTO';
  bool _enviando = false;
  String? _error;

  static const _tipos = ['SILLA', 'MESA', 'PUESTO', 'CABINA', 'OTRO'];

  @override
  void dispose() {
    _nombre.dispose();
    _canon.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombre.text.trim().length < 2) {
      setState(() => _error = 'Escribe un nombre.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });

    final res = await ApiService.post('/api/salon/${widget.salonId}/recursos', {
      'nombre': _nombre.text.trim(),
      'tipo': _tipo,
      'canon_mensual': num.tryParse(_canon.text) ?? 0,
    });

    if (!mounted) return;
    if (res is Map && res['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _enviando = false;
      _error = (res is Map ? res['error']?.toString() : null) ?? 'No se pudo crear el recurso.';
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
            Text('Nuevo recurso', style: TypographyTokens.h3(t).copyWith(fontSize: 16)),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Silla 1, Mesa esquinera',
              ),
            ),
            const SizedBox(height: Spacing.md),
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: _tipos.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _tipo = v ?? _tipo),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _canon,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Canon mensual (COP)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(_error!,
                  style: TypographyTokens.bodySmall(t)
                      .copyWith(color: const Color(0xFFC62828))),
            ],
            const SizedBox(height: Spacing.lg),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _enviando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.brandPrimary,
                  foregroundColor: t.brandPrimaryOn,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.round)),
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormularioAlquiler extends StatefulWidget {
  final int salonId;
  final Map<String, dynamic> recurso;
  const _FormularioAlquiler({required this.salonId, required this.recurso});

  @override
  State<_FormularioAlquiler> createState() => _FormularioAlquilerState();
}

class _FormularioAlquilerState extends State<_FormularioAlquiler> {
  final _persona = TextEditingController();
  bool _enviando = false;
  String? _error;

  @override
  void dispose() {
    _persona.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final persona = int.tryParse(_persona.text.trim());
    if (persona == null || persona <= 0) {
      setState(() => _error = 'Escribe el id numérico del profesional.');
      return;
    }
    setState(() {
      _enviando = true;
      _error = null;
    });

    final res = await ApiService.post('/api/salon/${widget.salonId}/alquileres', {
      'recurso_id': widget.recurso['id'],
      'persona_id': persona,
    });

    if (!mounted) return;
    if (res is Map && res['success'] == true) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _enviando = false;
      _error = (res is Map ? res['error']?.toString() : null) ??
          'No se pudo registrar el alquiler.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Token.of(context);
    final canon = (widget.recurso['canon_mensual'] as num?) ?? 0;

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
            Text('Alquilar ${widget.recurso['nombre'] ?? ''}',
                style: TypographyTokens.h3(t).copyWith(fontSize: 16)),
            Text(
              canon > 0 ? 'Canon: ${formatearCop(canon)}/mes' : 'Sin canon definido',
              style: TypographyTokens.bodySmall(t).copyWith(color: t.textSecondary),
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _persona,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Id del profesional',
                helperText: 'El buscador de miembros llega en una próxima etapa.',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: Spacing.sm),
              Text(_error!,
                  style: TypographyTokens.bodySmall(t)
                      .copyWith(color: const Color(0xFFC62828))),
            ],
            const SizedBox(height: Spacing.lg),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _enviando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.brandPrimary,
                  foregroundColor: t.brandPrimaryOn,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Radii.round)),
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Alquilar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
