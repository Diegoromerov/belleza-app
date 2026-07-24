import 'package:flutter/material.dart';
import '../services/audience_service.dart';
import '../shared/mens_theme.dart';

class AudienceToggleWidget extends StatelessWidget {
  final bool compact;

  const AudienceToggleWidget({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AudienceMode>(
      valueListenable: AudienceService.currentAudience,
      builder: (context, currentMode, child) {
        final isMen = currentMode == AudienceMode.men;

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isMen ? MensTheme.obsidianCard : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isMen
                  ? MensTheme.champagneGold.withValues(alpha: 0.4)
                  : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: isMen ? MensTheme.goldGlow : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildItem(
                context: context,
                mode: AudienceMode.all,
                label: 'Todos',
                icon: Icons.grid_view_rounded,
                isSelected: currentMode == AudienceMode.all,
                isMenMode: isMen,
              ),
              _buildItem(
                context: context,
                mode: AudienceMode.women,
                label: 'Mujeres',
                icon: Icons.woman_rounded,
                isSelected: currentMode == AudienceMode.women,
                isMenMode: isMen,
              ),
              _buildItem(
                context: context,
                mode: AudienceMode.men,
                label: 'Hombres',
                icon: Icons.man_rounded,
                isSelected: currentMode == AudienceMode.men,
                isMenMode: isMen,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required AudienceMode mode,
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isMenMode,
  }) {
    Color selectedBg = isMenMode
        ? MensTheme.champagneGold
        : Theme.of(context).primaryColor;
    Color selectedText = isMenMode ? Colors.black : Colors.white;
    Color unselectedText = isMenMode ? MensTheme.textSecondary : Colors.grey.shade700;

    return GestureDetector(
      onTap: () {
        AudienceService.setAudience(mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: compact ? 14 : 16,
              color: isSelected ? selectedText : unselectedText,
            ),
            if (!compact || isSelected) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? selectedText : unselectedText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
