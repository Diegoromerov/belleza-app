// frontend/lib/screens/ideas/widgets/color_palette.dart
import 'package:flutter/material.dart';
import '../../../services/biometric_service.dart';

class ColorPaletteWidget extends StatefulWidget {
  final String hexColor;

  const ColorPaletteWidget({super.key, required this.hexColor});

  @override
  State<ColorPaletteWidget> createState() => _ColorPaletteWidgetState();
}

class _ColorPaletteWidgetState extends State<ColorPaletteWidget> {
  List<ColorPaletteItem> _palette = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPalette();
  }

  Future<void> _loadPalette() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final palette = await BiometricService.getColorPalette(
        widget.hexColor.replaceFirst('#', ''),
        count: 5,
        mode: 'analogic',
      );
      if (mounted) {
        setState(() {
          _palette = palette;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_palette.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎨 Paleta de colores sugerida',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _palette.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final color = _palette[index];
              final hexString = color.hex.replaceFirst('#', '');
              Color displayColor;
              try {
                displayColor = Color(int.parse('FF$hexString', radix: 16));
              } catch (_) {
                displayColor = Colors.grey;
              }

              return Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: displayColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    color.name.length > 8 ? '${color.name.substring(0, 6)}...' : color.name,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
