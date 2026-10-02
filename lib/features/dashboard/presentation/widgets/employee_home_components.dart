import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../workplaces/data/models/workplace_model.dart';

/// Datos tipados para cada métrica.
class EmployeeMetricData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const EmployeeMetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Tarjeta de métrica rediseñada: ícono en esquina superior, valor grande, etiqueta abajo.
/// Layout 2-columnas en móvil.
class EmployeeMetricCardV2 extends StatelessWidget {
  final EmployeeMetricData data;

  const EmployeeMetricCardV2(this.data, {super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Stack(
        children: [
          // Ícono en esquina superior derecha
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: data.color.withValues(alpha: 0.15),
              ),
              child: Icon(data.icon, color: data.color, size: 18),
            ),
          ),
          // Contenido principal centrado
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      data.value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: data.color,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de detalles del lugar de trabajo con layout vertical mejorado.
class EmployeeWorkplaceDetailsCard extends StatelessWidget {
  final WorkplaceModel found;

  const EmployeeWorkplaceDetailsCard({super.key, required this.found});

  @override
  Widget build(BuildContext context) {
    final String capitalizedName = found.nombre.isNotEmpty
        ? '${found.nombre[0].toUpperCase()}${found.nombre.substring(1)}'
        : '';

    final String horarioValue = found.horaInicio != null
        ? '${found.horaInicio!} - ${found.horaFin ?? '----'}'
        : '---- - ----';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EmployeeDataRowVertical(
          label: 'Ubicación',
          value: capitalizedName,
          icon: Icons.location_on_outlined,
        ),
        const SizedBox(height: 16),
        EmployeeDataRowVertical(
          label: 'Horario',
          value: horarioValue,
          icon: Icons.access_time,
          compact: true,
        ),
      ],
    );
  }
}

/// Fila de datos vertical: etiqueta arriba (muted, pequeño), valor abajo (blanco, destacado).
class EmployeeDataRowVertical extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  const EmployeeDataRowVertical({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = compact
        ? const TextStyle(fontSize: 13, color: AppColors.textWhite, height: 1.4)
        : const TextStyle(
            fontSize: 15,
            color: AppColors.textWhite,
            height: 1.5,
          );
    final labelStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
      letterSpacing: 0.3,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label.toUpperCase(),
              style: labelStyle.copyWith(letterSpacing: 0.5),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.chevron_right,
              size: 14,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
