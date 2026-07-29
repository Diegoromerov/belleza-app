class BiometricModel {
  final double subtono;
  final String estacion;
  final List<String> paleta;
  final double hidratacion;
  final double sebo;
  final String mensajeAura;

  BiometricModel({
    required this.subtono,
    required this.estacion,
    required this.paleta,
    required this.hidratacion,
    required this.sebo,
    required this.mensajeAura,
  });

  factory BiometricModel.fromJson(Map<String, dynamic> json) {
    return BiometricModel(
      subtono: (json['subtono'] as num).toDouble(),
      estacion: json['estacion'],
      paleta: List<String>.from(json['paleta']),
      hidratacion: (json['hidratacion'] as num).toDouble(),
      sebo: (json['sebo'] as num).toDouble(),
      mensajeAura: json['mensaje_aura'],
    );
  }

  /// Instancia inicial / fallback por defecto.
  factory BiometricModel.initial() {
    return BiometricModel(
      subtono: 94.0,
      estacion: 'Otoño Cálido',
      paleta: const ['#C89D93', '#D4AF7A', '#8B5E3C', '#E8B4A0'],
      hidratacion: 85.5,
      sebo: 40.2,
      mensajeAura: 'Tu piel irradia la calidez de los Andes al atardecer.',
    );
  }
}
