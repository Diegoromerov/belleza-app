// lib/screens/superadmin/superadmin_ui.dart
/// Piezas compartidas por las pantallas de SuperAdmin: paleta y estados
/// (cargando, error, vacío, acceso restringido). Evita que cada pantalla
/// reinvente sus colores y sus mensajes de error.
library superadmin_ui;

import 'package:flutter/material.dart';

class SaColors {
  static const bg = Color(0xFFFAF8F5);
  static const ink = Color(0xFF1F1A15);
  static const muted = Color(0xFF8C7E74);
  static const gold = Color(0xFFC5A052);
  static const line = Color(0xFFEFE8DE);
  static const danger = Color(0xFFB3261E);
  static const ok = Color(0xFF2E7D32);
  static const warn = Color(0xFFEF6C00);
}

/// Título + subtítulo de sección.
class SaHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const SaHeader({super.key, required this.title, required this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700, color: SaColors.ink)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: SaColors.muted)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Tarjeta de KPI: etiqueta, valor y nota opcional.
class SaKpi extends StatelessWidget {
  final String label;
  final String value;
  final String? note;
  final Color? valueColor;

  const SaKpi({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 9.5, letterSpacing: .8, fontWeight: FontWeight.w600,
                  color: SaColors.muted)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: valueColor ?? SaColors.ink)),
          if (note != null) ...[
            const SizedBox(height: 4),
            Text(note!, style: const TextStyle(fontSize: 10.5, color: SaColors.muted)),
          ],
        ],
      ),
    );
  }
}

/// Caja con título para agrupar contenido.
class SaPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;

  const SaPanel({super.key, required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10, letterSpacing: .8, fontWeight: FontWeight.w700,
                        color: SaColors.muted)),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class SaLoading extends StatelessWidget {
  const SaLoading({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2, color: SaColors.gold),
          ),
        ),
      );
}

class SaErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const SaErrorState({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF3F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3D6D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('No se pudo cargar',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: SaColors.danger)),
          const SizedBox(height: 6),
          Text('$error', style: const TextStyle(fontSize: 11.5, color: SaColors.muted)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('REINTENTAR')),
        ],
      ),
    );
  }
}

class SaEmptyState extends StatelessWidget {
  final String message;
  const SaEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: SaColors.muted)),
        ),
      );
}

/// Pantalla para quien llega sin permisos: el backend respondió 403.
class SaForbidden extends StatelessWidget {
  const SaForbidden({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaColors.bg,
      appBar: AppBar(
        backgroundColor: SaColors.bg,
        elevation: 0,
        foregroundColor: SaColors.ink,
        title: const Text('Acceso restringido', style: TextStyle(fontSize: 15)),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 40, color: SaColors.muted),
              SizedBox(height: 16),
              Text('Esta consola requiere rol SuperAdmin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: SaColors.ink)),
              SizedBox(height: 6),
              Text('El servidor rechazó la solicitud (403).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: SaColors.muted)),
            ],
          ),
        ),
      ),
    );
  }
}
