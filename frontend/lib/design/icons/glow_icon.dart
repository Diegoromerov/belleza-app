import 'package:flutter/material.dart';

enum GlowIconColorRole { neutral, accent, aura, secondary }

class GlowIconThemeExtension extends ThemeExtension<GlowIconThemeExtension> {
  final bool isMenMode;
  const GlowIconThemeExtension({this.isMenMode = false});

  @override
  GlowIconThemeExtension copyWith({bool? isMenMode}) => GlowIconThemeExtension(isMenMode: isMenMode ?? this.isMenMode);

  @override
  GlowIconThemeExtension lerp(ThemeExtension<GlowIconThemeExtension>? other, double t) => this;
}

class GlowIcon {
  static Widget resolve(
    String iconName, {
    double size = 24,
    GlowIconColorRole colorRole = GlowIconColorRole.neutral,
    String? semanticLabel,
  }) {
    IconData data = Icons.star;
    if (iconName == 'calendar') data = Icons.calendar_today;
    if (iconName == 'bag') data = Icons.shopping_bag;
    if (iconName == 'aura') data = Icons.auto_awesome;
    if (iconName == 'profile') data = Icons.person;

    return Icon(data, size: size, color: const Color(0xFFC5A052), semanticLabel: semanticLabel);
  }
}
