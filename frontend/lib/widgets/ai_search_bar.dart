import 'package:flutter/material.dart';
import '../shared/theme.dart';

class AISearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onAwesomePressed;
  final Widget categorySelector;

  const AISearchBar({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onAwesomePressed,
    required this.categorySelector,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppTheme.accent.withOpacity(0.4), width: 1.5),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: '¿Buscas un estilo o tips de belleza? Pregúntale a la IA aquí...',
                      hintStyle: TextStyle(
                        fontSize: 13.5,
                        color: AppTheme.text,
                        overflow: TextOverflow.ellipsis,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: onSubmitted,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome, color: AppTheme.primary),
                  onPressed: onAwesomePressed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          categorySelector,
        ],
      ),
    );
  }
}
