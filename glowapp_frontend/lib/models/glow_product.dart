import 'package:flutter/material.dart';

/// Modelo universal para productos de GlowStore dentro del módulo Nia Beauty.
class GlowProduct {
  final String id;
  final String title;
  final String category;
  final String price;
  final String benefitTag; // Beneficio principal (ej: "Hidratación Profunda")
  final String? imageUrl;
  final IconData icon;

  const GlowProduct({
    required this.id,
    required this.title,
    required this.category,
    required this.price,
    required this.benefitTag,
    this.imageUrl,
    this.icon = Icons.spa_rounded,
  });
}
