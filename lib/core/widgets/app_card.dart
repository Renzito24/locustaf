import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

/// Tarjeta corporativa compartida (Restyle Corporativo, PR2).
///
/// Reemplaza los `Container(decoration: AppTheme.cardDecoration(), ...)`
/// repetidos: mismo fondo navy, borde verde sutil y esquinas semi-afiladas,
/// con padding homogéneo.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.isHovered = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool isHovered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: AppTheme.cardDecoration(isHovered: isHovered),
      padding: padding,
      child: onTap == null ? child : InkWell(onTap: onTap, child: child),
    );
  }
}

/// Cabecera de tarjeta con ícono y título (patrón repetido en toda la app).
class AppCardHeader extends StatelessWidget {
  const AppCardHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.gold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTheme.sans(
              base: const TextStyle(fontWeight: FontWeight.w600),
              fontSize: 14,
              color: AppColors.textWhite,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}