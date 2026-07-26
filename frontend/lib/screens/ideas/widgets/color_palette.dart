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
        height: 85,
        child: Center(child: CircularProgressIndicator(color: Colors.purple)),
      );
    }

    if (_palette.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.palette_outlined, color: Colors.purple, size: 22),
            SizedBox(width: 8),
            Text(
              'Paleta de colores sugerida',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.12), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SizedBox(
            height: 75,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _palette.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: displayColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      color.name.length > 9 ? '${color.name.substring(0, 7)}...' : color.name,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
