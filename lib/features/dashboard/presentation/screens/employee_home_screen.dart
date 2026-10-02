import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_version.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../attendance/presentation/providers/attendance_notifier.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../companies/presentation/providers/company_providers.dart';
import '../../../incidences/presentation/providers/incidences_provider.dart';
import '../../../reports/domain/services/employee_report_stats.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../widgets/employee_home_components.dart';

/// Pantalla Principal del empleado (Ronda 3A — B3).
///
/// Resume su lugar de trabajo y las métricas del mes actual (calculadas desde
/// el alta, ver [EmployeeReportStats]) y muestra la versión instalada al pie.
class EmployeeHomeScreen extends ConsumerWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
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

    final userAsync = ref.watch(currentAppUserProvider);
    return userAsync.when(
      loading: () => AppTheme.loadingState(message: 'Cargando información...'),
      error: (e, _) => AppTheme.errorState(
        'Error al cargar perfil: $e',
        onRetry: () => ref.invalidate(currentAppUserProvider),
      ),
      data: (user) {
        if (user == null || user.companyId == null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: AppTheme.emptyState(
              icon: Icons.business_outlined,
              title: 'Empresa no asignada',
              subtitle: 'Tu usuario no tiene una empresa asignada.',
            ),
          );
        }

        return _EmployeeHomeContent(
          user: user,
          userId: userId,
        );
      },
    );
  }
}

class _EmployeeHomeContent extends ConsumerWidget {
  const _EmployeeHomeContent({
    required this.user,
    required this.userId,
  });

  final UserModel user;
  final String userId;

  static const List<String> _months = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendancesAsync = ref.watch(attendancesByUserProvider(userId));
    final incidencesAsync = ref.watch(incidencesStreamProvider);
    final companyAsync = ref.watch(currentCompanyProvider);
    final workplacesAsync = ref.watch(activeWorkplacesProvider);
    final now = DateTime.now();

    final incidences = (incidencesAsync.value ?? [])
        .where((i) => i.userId == userId)
        .toList();
    final company = companyAsync.value;
    final laborableDays = (company?.diasLaborables.isNotEmpty ?? false)
        ? company!.diasLaborables
        : const [1, 2, 3, 4, 5];

    return RefreshIndicator(
      onRefresh: () => _refreshAll(ref, userId),
      child: SingleChildScrollView(
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
            if (incidencesAsync.hasError) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Aviso: no se pudieron cargar las incidencias. Las ausencias justificadas pueden no reflejarse en las métricas.',
                        style: AppTheme.bodyMd.copyWith(color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            attendancesAsync.when(
              data: (allAttendances) {
                final stats = EmployeeReportStats.compute(
                  monthAttendances: allAttendances,
                  incidences: incidences,
                  laborableDays: laborableDays,
                  employmentStart: user.createdAt,
                  selectedMonth: now.month,
                  selectedYear: now.year,
                  now: now,
                );
                return _buildMetrics(stats);
              },
              loading: () =>
                  AppTheme.loadingState(message: 'Cargando métricas...'),
              error: (e, _) => AppTheme.errorState(
                'Error al cargar métricas: $e',
                onRetry: () => _refreshAll(ref, userId),
              ),
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
      ),
    );
  }

  /// Re-pide TODOS los datos de la pantalla.
  Future<void> _refreshAll(WidgetRef ref, String userId) async {
    ref.invalidate(attendancesByUserProvider(userId));
    ref.invalidate(incidencesStreamProvider);
    ref.invalidate(activeWorkplacesProvider);
    ref.invalidate(workplacesStreamProvider);
    ref.invalidate(currentAppUserProvider);
    await Future.delayed(const Duration(milliseconds: 500));
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
                return _infoCard(
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

  Widget _buildMetrics(EmployeeReportStats stats) {
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
