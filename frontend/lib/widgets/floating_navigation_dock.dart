import 'package:flutter/material.dart';
import '../shared/theme.dart';

class FloatingNavigationDock extends StatelessWidget {
  final String? userRole;
  final VoidCallback onChatPressed;
  final VoidCallback onBookingsOrPanelPressed;
  final VoidCallback onIdeasPressed;
  final VoidCallback onServicesOrProfilePressed;
  final VoidCallback onLogoutOrProfilePressed;

  const FloatingNavigationDock({
    super.key,
    required this.userRole,
    required this.onChatPressed,
    required this.onBookingsOrPanelPressed,
    required this.onIdeasPressed,
    required this.onServicesOrProfilePressed,
    required this.onLogoutOrProfilePressed,
  });

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppTheme.text,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProminentCenterNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Transform.translate(
          offset: const Offset(0, -14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE8D7D3),
                      Color(0xFFC89D93),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC89D93).withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 2.5,
                  ),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB07D62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
          color: AppTheme.accent.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: AppTheme.glassShadow,
      ),
      child: Row(
        children: [
          // Botón 1: Asistente IA (Común)
          _buildNavItem(
            icon: Icons.auto_awesome,
            label: 'Asistente IA',
            onTap: onChatPressed,
          ),
          
          // Botón 2: Dinámico (Citas o Panel)
          if (userRole == 'provider')
            _buildNavItem(
              icon: Icons.dashboard_outlined,
              label: 'Panel',
              onTap: onBookingsOrPanelPressed,
            )
          else
            _buildNavItem(
              icon: Icons.calendar_today_outlined,
              label: 'Citas',
              onTap: onBookingsOrPanelPressed,
            ),

          // Botón 3: Ideas (Botón central prominente)
          _buildProminentCenterNavItem(
            icon: Icons.lightbulb_outline_rounded,
            label: 'Ideas',
            onTap: onIdeasPressed,
          ),

          // Botón 4: Dinámico (Servicios o Perfil)
          if (userRole == 'provider')
            _buildNavItem(
              icon: Icons.inventory_2_outlined,
              label: 'Servicios',
              onTap: onServicesOrProfilePressed,
            )
          else
            _buildNavItem(
              icon: Icons.person_outline_rounded,
              label: 'Perfil',
              onTap: onServicesOrProfilePressed,
            ),

          // Botón 5: Dinámico (Perfil o Salir)
          if (userRole == 'provider')
            _buildNavItem(
              icon: Icons.person_outline_rounded,
              label: 'Perfil',
              onTap: onLogoutOrProfilePressed,
            )
          else
            _buildNavItem(
              icon: Icons.logout_rounded,
              label: 'Salir',
              onTap: onLogoutOrProfilePressed,
            ),
        ],
      ),
    );
  }
}
