import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glowapp_frontend/ui/widgets/glass_card.dart';
import 'package:glowapp_frontend/core/theme/app_theme.dart';
import 'package:glowapp_frontend/providers/beauty_provider.dart';

class BeautyScreen extends ConsumerWidget {
  const BeautyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beautyItems = ref.watch(beautyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sección Beauty'),
        backgroundColor: GlowTheme.primary,
      ),
      backgroundColor: GlowTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: beautyItems.length,
          itemBuilder: (context, index) {
            final item = beautyItems[index];
            return GlassCard(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 48, color: GlowTheme.accent),
                  const SizedBox(height: 8),
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(item.description,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
