import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

/// Fila etiqueta → valor de tarjetas de datos (Restyle Corporativo, PR2).
///
/// Reemplaza el patrón `Row(key, Expanded(value))` repetido en las vistas
/// del empleado. El valor alinea a la derecha, no desborda en pantallas
/// chicas ([Flexible]) y puede recibir un [child] a medida en lugar de texto.
class AppDataRow extends StatelessWidget {
  const AppDataRow({
    super.key,
    required this.label,
    this.value,
    this.child,
    this.divider = true,
  });

  final String label;
  final String? value;
  final Widget? child;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final content = child ??
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTheme.bodyMd,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                value ?? '',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontWeight: FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );

    if (!divider) return content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        content,
        Divider(height: 24, color: AppColors.gold.withValues(alpha: 0.1)),
      ],
    );
  }
}