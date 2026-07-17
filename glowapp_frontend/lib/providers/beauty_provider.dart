import 'package:flutter_riverpod/flutter_riverpod.dart';

class BeautyItem {
  final String title;
  final String description;
  final IconData icon;

  BeautyItem({required this.title, required this.description, required this.icon});
}

final beautyProvider = Provider<List<BeautyItem>>((ref) => [
  BeautyItem(
    title: 'Cuidado de la piel',
    description: 'Rutinas y tips para una piel radiante.',
    icon: Icons.spa,
  ),
  BeautyItem(
    title: 'Maquillaje básico',
    description: 'Aprende los fundamentos del maquillaje.',
    icon: Icons.brush,
  ),
  BeautyItem(
    title: 'Color de cabello',
    description: 'Tendencias y cuidados del color.',
    icon: Icons.palette,
  ),
  BeautyItem(
    title: 'Wellness',
    description: 'Ejercicio y nutrición para la belleza interior.',
    icon: Icons.self_improvement,
  ),
]);
