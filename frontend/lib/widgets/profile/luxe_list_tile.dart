import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';

/// Toggle Luxe personalizado con track nude200/nude900 y thumb gold871 cuando activo
class LuxeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const LuxeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: LuxeColors.gold871,
      trackColor: LuxeColors.nude200,
    );
  }
}

/// LuxeListTile Concierge para perfil y ajustes
class LuxeProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const LuxeProfileTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: LuxeSpacing.xl,
            vertical: LuxeSpacing.sm,
          ),
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LuxeColors.nude100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: LuxeColors.gold871, size: 20),
          ),
          title: Text(
            title,
            style: LuxeTypography.bodyMd.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle!,
                  style: LuxeTypography.bodySm,
                )
              : null,
          trailing: trailing ??
              const Icon(Icons.arrow_forward_ios, size: 14, color: LuxeColors.nude500),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 64.0, right: LuxeSpacing.xl),
            child: Divider(color: LuxeColors.nude200, height: 1, thickness: 0.5),
          ),
      ],
    );
  }
}
