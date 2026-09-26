import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

/// Etiqueta de campo de formulario corporativa (Restyle Corporativo, PR2).
///
/// Texto IBM Plex en mayúsculas con el tamaño/color consistentes de la demo.
/// Se usa como cabecera de cada sección de un formulario.
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel(
    this.text, {
    super.key,
    this.req = false,
  });

  final String text;
  final bool req;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: text.toUpperCase(),
        style: AppTheme.sans(
          base: const TextStyle(fontWeight: FontWeight.w600),
          fontSize: 12,
          color: AppColors.textMuted,
          // Preserva el espacio de línea mínimo para no apretar el layout.
        ).copyWith(letterSpacing: 0.8),
        children: req
            ? [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ]
            : null,
      ),
    );
  }
}