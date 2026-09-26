import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Chip/badge corporativo compartido (Restyle Corporativo, PR2).
///
/// Reemplaza `AppTheme.badge` con esquinas más rectas (radio 8), tipografía
/// IBM Plex e ícono opcional. El texto es siempre el contrato visual: si el
/// label cambia, los tests que lo buscan deben actualizarse a propósito.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foregroundColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}