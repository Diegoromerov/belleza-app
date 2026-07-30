// lib/widgets/profile/profile_header.dart
import 'package:flutter/material.dart';
import '../../core/theme/belleza_luxe_theme.dart';
import '../../core/theme/belleza_luxe_gradients.dart';
import '../../design/components/luxe_components.dart';

class ProfileHeader extends StatelessWidget {
  final String userName;
  final String userEmail;
  final String membershipLevel;
  final String? avatarUrl;
  final VoidCallback? onEditAvatar;

  const ProfileHeader({
    super.key,
    required this.userName,
    required this.userEmail,
    this.membershipLevel = 'MEMBRESÍA GOLD AURA',
    this.avatarUrl,
    this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: LuxeSpacing.xl),
      decoration: BoxDecoration(
        gradient: LuxeGradients.goldShimmer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border.all(color: LuxeColors.nude200, width: 0.5),
      ),
      child: Column(
        children: [
          // AVATAR CON BORDE 2PX GOLD871 Y SOMBRA DORADA
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: LuxeColors.gold871, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: LuxeColors.shadowGold,
                      blurRadius: 16.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: LuxeColors.nude200,
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? const Icon(Icons.person, size: 48, color: LuxeColors.gold871)
                      : null,
                ),
              ),
              if (onEditAvatar != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: LuxeColors.gold871,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.camera_alt, size: 14, color: LuxeColors.nude900),
                      onPressed: onEditAvatar,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // NOMBRE DIDOT DISPLAY SM CENTRADO
          Text(
            userName,
            style: LuxeTypography.displaySm,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          // EMAIL
          Text(
            userEmail,
            style: LuxeTypography.bodySm,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),

          // CHIP MEMBRESÍA LUXEBADGE FONDO GOLD871 TEXTO NUDE900
          LuxeBadge(
            label: membershipLevel,
            backgroundColor: LuxeColors.gold871,
            textColor: LuxeColors.nude900,
          ),
        ],
      ),
    );
  }
}
