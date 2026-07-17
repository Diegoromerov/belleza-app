import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glowapp_frontend/routes/app_router.dart';
import 'package:glowapp_frontend/core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: GlowApp()));
}

class GlowApp extends ConsumerWidget {
  const GlowApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'GlowApp',
      theme: GlowTheme.lightTheme,
      darkTheme: GlowTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
