import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../reports/domain/services/employee_report_stats.dart';
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

/// Tarjeta con ícono, título y subtítulo para estados informativos o de alerta.
class EmployeeInfoCard extends StatelessWidget {
  const EmployeeInfoCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textWhite,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTheme.bodyMd),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta de sección en mayúsculas.
class EmployeeSectionLabel extends StatelessWidget {
  const EmployeeSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.textMuted,
      ),
    );
  }
}

/// Tarjeta del lugar de trabajo asignado al empleado.
class EmployeeWorkplaceCard extends StatelessWidget {
  const EmployeeWorkplaceCard({
    super.key,
    required this.user,
    required this.workplacesAsync,
  });

  final UserModel? user;
  final AsyncValue<List<WorkplaceModel>> workplacesAsync;

  @override
  Widget build(BuildContext context) {
    final String? workplaceId = user?.lugarDeTrabajoId;
    if (workplaceId == null || workplaceId.isEmpty) {
      return const EmployeeInfoCard(
        icon: Icons.location_off_outlined,
        color: AppColors.warning,
        title: 'Sin lugar de trabajo asignado',
        subtitle:
            'Contactá al administrador para asignarte tu lugar de trabajo.',
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold.withValues(alpha: 0.15),
                ),
                child: const Icon(
                  Icons.business_outlined,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tu lugar de trabajo',
                  style: AppTheme.headingMd.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          workplacesAsync.when(
            data: (list) {
              WorkplaceModel? found;
              for (final w in list) {
                if (w.id == workplaceId) {
                  found = w;
                  break;
                }
              }
              if (found == null) {
                return const EmployeeInfoCard(
                  icon: Icons.location_off_outlined,
                  color: AppColors.warning,
                  title: 'Lugar no disponible',
                  subtitle:
                      'No pudimos encontrar tu lugar asignado. Contactá al administrador.',
                );
              }
              return EmployeeWorkplaceDetailsCard(found: found);
            },
            loading: () =>
                AppTheme.loadingState(message: 'Cargando lugar de trabajo...'),
            error: (_, _) => const EmployeeInfoCard(
              icon: Icons.error_outline,
              color: AppColors.error,
              title: 'Error al cargar el lugar de trabajo',
              subtitle: 'Intentá nuevamente en unos minutos.',
            ),
          ),
        ],
      ),
    );
  }
}

/// Grilla de métricas mensuales del empleado.
class EmployeeMetricsGrid extends StatelessWidget {
  const EmployeeMetricsGrid({
    super.key,
    required this.stats,
  });

  final EmployeeReportStats stats;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      EmployeeMetricData(
        icon: Icons.calendar_today,
        label: 'Días trabajados',
        value: stats.daysWorked.toString(),
        color: AppColors.goldLight,
      ),
      EmployeeMetricData(
        icon: Icons.access_time,
        label: 'Horas trabajadas',
        value: stats.formattedHours,
        color: AppColors.gold,
      ),
      EmployeeMetricData(
        icon: Icons.schedule,
        label: 'Llegadas tarde',
        value: stats.lateArrivals.toString(),
        color: stats.lateArrivals > 0 ? AppColors.warning : AppColors.success,
      ),
      EmployeeMetricData(
        icon: Icons.cancel_outlined,
        label: 'Ausencias injustificadas',
        value: stats.absences.toString(),
        color: stats.absences > 0 ? AppColors.error : AppColors.success,
      ),
      EmployeeMetricData(
        icon: Icons.description_outlined,
        label: 'Justificativos',
        value: stats.justifications.toString(),
        color: AppColors.goldLight,
      ),
      EmployeeMetricData(
        icon: Icons.warning_amber_outlined,
        label: 'Incidencias propias',
        value: stats.ownIncidences.toString(),
        color: stats.ownIncidences > 0 ? AppColors.error : AppColors.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isMobile = width < 600;
        final crossAxisCount = isMobile ? 2 : (width > 900 ? 3 : 2);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isMobile ? 0.82 : 1.15,
          ),
          itemCount: 6,
          itemBuilder: (_, index) => EmployeeMetricCardV2(metrics[index]),
        );
      },
    );
  }
}

