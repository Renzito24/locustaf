import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/presentation/providers/attendance_notifier.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';

/// Historial del empleado (Ronda 3A — B4): sus propias jornadas, ordenadas
/// por fecha de ingreso descendente.
class EmployeeHistoryScreen extends ConsumerWidget {
  const EmployeeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AppTheme.emptyState(
          icon: Icons.person_off_outlined,
          title: 'Usuario no autenticado',
          subtitle: 'Iniciá sesión para ver tu historial.',
        ),
      );
    }

    final attendancesAsync = ref.watch(attendancesByUserProvider(userId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historial', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text(
            'Todas tus jornadas registradas.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 24),
          attendancesAsync.when(
            data: (list) {
              final sorted = [...list]
                ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
              if (sorted.isEmpty) {
                return AppTheme.emptyState(
                  icon: Icons.history,
                  title: 'Sin registros de asistencia',
                  subtitle: 'Aún no se registraron jornadas.',
                );
              }
              return _buildRecords(ref, sorted);
            },
            loading: () => AppTheme.loadingState(message: 'Cargando historial...'),
            error: (e, _) => AppTheme.errorState(
              'Error al cargar el historial: $e',
              onRetry: () => ref.invalidate(attendancesByUserProvider(userId)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecords(WidgetRef ref, List<AttendanceModel> list) {
    final workplaceMap = <String, String>{};
    ref.watch(activeWorkplacesProvider).whenData((workplaces) {
      for (final w in workplaces) {
        workplaceMap[w.id] = w.nombre;
      }
    });

    return Column(
      children: [
        for (final record in list)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        record.status == AttendanceStatus.active
                            ? Icons.play_circle_outline
                            : Icons.check_circle_outline,
                        size: 18,
                        color: record.status == AttendanceStatus.active
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.date,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textWhite,
                          ),
                        ),
                      ),
                      if (record.status == AttendanceStatus.active)
                        AppTheme.badge(
                          label: 'Activo',
                          bgColor: AppColors.success.withValues(alpha: 0.15),
                          textColor: AppColors.success,
                        )
                      else
                        AppTheme.badge(
                          label: 'Completado',
                          bgColor: AppColors.gold.withValues(alpha: 0.1),
                          textColor: AppColors.gold,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _statColumn('Entrada', _formatTime(record.checkInTime)),
                      if (record.checkOutTime != null)
                        _statColumn('Salida', _formatTime(record.checkOutTime!)),
                      if (record.durationMinutes != null)
                        _statColumn(
                          'Duración',
                          _formatDuration(record.durationMinutes!),
                        ),
                    ],
                  ),
                  if (record.workplaceId != null &&
                      workplaceMap[record.workplaceId!] != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textMuted.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          workplaceMap[record.workplaceId!]!,
                          style: AppTheme.bodyMd.copyWith(
                            fontSize: 12,
                            color: AppColors.textMuted.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _statColumn(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textWhite,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}min';
  }
}
