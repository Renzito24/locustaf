import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_version.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../attendance/presentation/providers/attendance_notifier.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../companies/presentation/providers/company_providers.dart';
import '../../../incidences/presentation/providers/incidences_provider.dart';
import '../../../reports/domain/services/employee_report_stats.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';

/// Pantalla Principal del empleado (Ronda 3A — B3).
///
/// Resume su lugar de trabajo y las métricas del mes actual (calculadas desde
/// el alta, ver [EmployeeReportStats]) y muestra la versión instalada al pie.
class EmployeeHomeScreen extends ConsumerWidget {
  const EmployeeHomeScreen({super.key});

  static const List<String> _months = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final userAsync = ref.watch(currentAppUserProvider);

    if (userId == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AppTheme.emptyState(
          icon: Icons.person_off_outlined,
          title: 'Usuario no autenticado',
          subtitle: 'Iniciá sesión para ver tu información.',
        ),
      );
    }

    final attendancesAsync = ref.watch(attendancesByUserProvider(userId));
    final incidencesAsync = ref.watch(incidencesStreamProvider);
    final companyAsync = ref.watch(currentCompanyProvider);
    final workplacesAsync = ref.watch(activeWorkplacesProvider);
    final now = DateTime.now();

    final user = userAsync.value;
    final incidences = (incidencesAsync.value ?? [])
        .where((i) => i.userId == userId)
        .toList();
    final company = companyAsync.value;
    final laborableDays = (company?.diasLaborables.isNotEmpty ?? false)
        ? company!.diasLaborables
        : const [1, 2, 3, 4, 5];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Principal', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text(
            'Tu jornada y tus métricas de ${_months[now.month - 1]} de ${now.year}.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 24),
          _buildWorkplaceCard(user, workplacesAsync),
          const SizedBox(height: 24),
          _sectionLabel('Tus métricas de ${_months[now.month - 1]}'),
          const SizedBox(height: 12),
          attendancesAsync.when(
            data: (allAttendances) {
              final stats = EmployeeReportStats.compute(
                monthAttendances: allAttendances,
                incidences: incidences,
                laborableDays: laborableDays,
                employmentStart: user?.createdAt,
                selectedMonth: now.month,
                selectedYear: now.year,
                now: now,
              );
              return _buildMetrics(stats);
            },
            loading: () => AppTheme.loadingState(message: 'Cargando métricas...'),
            error: (e, _) => AppTheme.errorState('Error al cargar métricas: $e'),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '$appVersion · $appBuildLabel',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.5),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkplaceCard(
    UserModel? user,
    AsyncValue<List<WorkplaceModel>> workplacesAsync,
  ) {
    final String? workplaceId = user?.lugarDeTrabajoId;
    if (workplaceId == null || workplaceId.isEmpty) {
      return _infoCard(
        icon: Icons.location_off_outlined,
        color: AppColors.warning,
        title: 'Sin lugar de trabajo asignado',
        subtitle: 'Contactá al administrador para asignarte tu lugar de trabajo.',
      );
    }

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.business_outlined, color: AppColors.gold, size: 20),
              SizedBox(width: 8),
              Text('Tu lugar de trabajo', style: AppTheme.headingMd),
            ],
          ),
          const SizedBox(height: 14),
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
                return _infoCard(
                  icon: Icons.location_off_outlined,
                  color: AppColors.warning,
                  title: 'Lugar de trabajo no disponible',
                  subtitle: 'No pudimos encontrar tu lugar asignado. Contactá al administrador.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kvRow('Ubicación', found.nombre),
                  if (found.direccion != null && found.direccion!.isNotEmpty) ...[
                    Divider(
                      height: 24,
                      color: AppColors.gold.withValues(alpha: 0.1),
                    ),
                    _kvRow('Dirección', found.direccion!),
                  ],
                  Divider(
                    height: 24,
                    color: AppColors.gold.withValues(alpha: 0.1),
                  ),
                  _kvRow(
                    'Horario',
                    '${found.horaInicio ?? '--:--'} - ${found.horaFin ?? '--:--'}',
                  ),
                  if (found.radio != null) ...[
                    Divider(
                      height: 24,
                      color: AppColors.gold.withValues(alpha: 0.1),
                    ),
                    _kvRow(
                      'Geocerca',
                      '${found.radio!.toStringAsFixed(0)} m',
                    ),
                  ],
                ],
              );
            },
            loading: () => AppTheme.loadingState(message: 'Cargando lugar de trabajo...'),
            error: (_, _) => _infoCard(
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

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
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

  Widget _sectionLabel(String text) {
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

  Widget _kvRow(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(key, style: AppTheme.bodyMd),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontWeight: FontWeight.w500,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics(EmployeeReportStats stats) {
    final cards = [
      _MetricCard(
        icon: Icons.calendar_today,
        label: 'Días trabajados',
        value: stats.daysWorked.toString(),
        color: AppColors.goldLight,
      ),
      _MetricCard(
        icon: Icons.access_time,
        label: 'Horas trabajadas',
        value: '${stats.totalHours.toStringAsFixed(1)}h',
        color: AppColors.gold,
      ),
      _MetricCard(
        icon: Icons.schedule,
        label: 'Llegadas tarde',
        value: stats.lateArrivals.toString(),
        color: stats.lateArrivals > 0 ? AppColors.warning : AppColors.success,
      ),
      _MetricCard(
        icon: Icons.cancel_outlined,
        label: 'Ausencias injustificadas',
        value: stats.absences.toString(),
        color: stats.absences > 0 ? AppColors.error : AppColors.success,
      ),
      _MetricCard(
        icon: Icons.description_outlined,
        label: 'Justificativos',
        value: stats.justifications.toString(),
        color: AppColors.goldLight,
      ),
      _MetricCard(
        icon: Icons.warning_amber_outlined,
        label: 'Incidencias propias',
        value: stats.ownIncidences.toString(),
        color: stats.ownIncidences > 0 ? AppColors.error : AppColors.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 900 ? 3 : (width > 600 ? 2 : 1);
        final itemWidth = (width - (crossAxisCount - 1) * 16) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final card in cards) SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}