import 'package:flutter/material.dart';
import '../../shared/glow_tokens.dart';
import '../../models/biometric_result.dart';
import '../../widgets/glow_glass_card.dart';

/// Pantalla de Resultados del ADN Cromático de Belleza.
/// Muestra un círculo cromático central animado con efecto de "florece" ([AnimatedContainer]),
/// métricas de subtono (94%), estación ("Otoño Cálido") y paleta de 4 colores armónicos.
class ColorDnaResultsScreen extends StatefulWidget {
  final BiometricResult? results;
  final VoidCallback? onContinue;

  const ColorDnaResultsScreen({
    super.key,
    this.results,
    this.onContinue,
  });

  @override
  State<ColorDnaResultsScreen> createState() => _ColorDnaResultsScreenState();
}

class _ColorDnaResultsScreenState extends State<ColorDnaResultsScreen> {
  bool _isBloomed = false;

  @override
  void initState() {
    super.initState();
    // Iniciar animación de "florece" después de montar la pantalla
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isBloomed = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        title: const Text(
          'Tu ADN Cromático',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF1F1A15),
          ),
        ),
        backgroundColor: const Color(0xFFFAF8F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F1A15)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Diagnóstico Finalizado',
                    style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1A15),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Basado en tu escaneo biométrico y subtonos de piel.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF6B5E59),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

              // Círculo Cromático Central con Semantics para accesibilidad
              Center(
                child: Semantics(
                  label: 'Gráfico cromático de resultados: Estación Otoño Cálido con coincidencia de subtono del 94 por ciento.',
                  image: true,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.elasticOut,
                    width: _isBloomed ? 180 : 40,
                    height: _isBloomed ? 180 : 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const SweepGradient(
                        colors: [
                          GlowTokens.terracota,
                          GlowTokens.roseGold,
                          GlowTokens.amber,
                          GlowTokens.emerald,
                          GlowTokens.terracota,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: GlowTokens.roseGold.withValues(alpha: 0.4),
                          blurRadius: _isBloomed ? 24 : 4,
                          spreadRadius: _isBloomed ? 6 : 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: _isBloomed ? 130 : 25,
                        height: _isBloomed ? 130 : 25,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: GlowTokens.creamSilk,
                        ),
                        child: _isBloomed
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.palette_rounded,
                                    color: GlowTokens.terracota,
                                    size: 32,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Otoño',
                                    style: TextStyle(
                                      fontFamily: GlowTokens.fontPlayfairDisplay,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: GlowTokens.nightAndean,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Cards de Información Accesibles
              Semantics(
                container: true,
                label: 'Resultados del análisis: Subtono cálido 94 por ciento, Estación Otoño Cálido',
                child: GlowGlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem('Subtono Cálido', '94%'),
                      Container(
                        width: 1,
                        height: 40,
                        color: GlowTokens.terracota.withValues(alpha: 0.2),
                      ),
                      _buildStatItem('Estación', 'Otoño Cálido'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Paleta de Colores Recomendada (con soporte para Daltonismo)
              Semantics(
                container: true,
                label: 'Paleta armónica sugerida con 4 colores: Terracota Glow, Rose Gold, Bronce Cálido y Ámbar Suave.',
                child: GlowGlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Paleta Armónica Sugerida',
                        style: TextStyle(
                          fontFamily: GlowTokens.fontPlayfairDisplay,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: GlowTokens.nightAndean,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          _ColorSampleWidget(colorHex: '#C89D93', colorName: 'Terracota'),
                          _ColorSampleWidget(colorHex: '#D4AF7A', colorName: 'Rose Gold'),
                          _ColorSampleWidget(colorHex: '#8B5E3C', colorName: 'Bronce'),
                          _ColorSampleWidget(colorHex: '#E8B4A0', colorName: 'Ámbar'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Botón de Continuar Accesible
              Semantics(
                button: true,
                label: 'Botón: Ver Productos Recomendados en GlowStore',
                hint: 'Presiona para explorar la receta de cosméticos apta para tu paleta',
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF3D59B), Color(0xFFC5A052)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC5A052).withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: widget.onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: const Color(0xFF1F1A15),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Ver Productos Recomendados',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1F1A15),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC5A052),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Color(0xFF6B5E59),
          ),
        ),
      ],
    );
  }
}

class _ColorSampleWidget extends StatelessWidget {
  final String colorHex;
  final String colorName;

  const _ColorSampleWidget({
    required this.colorHex,
    required this.colorName,
  });

  @override
  Widget build(BuildContext context) {
    final cleanHex = colorHex.replaceAll('#', '');
    final color = Color(int.parse('FF$cleanHex', radix: 16));

    return Semantics(
      label: 'Muestra de color: $colorName',
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE8DFD8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            colorName,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F1A15),
            ),
          ),
        ],
      ),
    );
  }
}
