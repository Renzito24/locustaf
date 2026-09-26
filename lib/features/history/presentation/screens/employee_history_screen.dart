import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
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
            error: (e, _) => AppTheme.errorState('Error al cargar el historial: $e'),
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
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: AppTheme.cardDecoration(),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  record.status == AttendanceStatus.active
                      ? Icons.play_circle_outline
                      : Icons.check_circle_outline,
                  color: record.status == AttendanceStatus.active
                      ? AppColors.success
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.date,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _kvRow('Entrada', _formatTime(record.checkInTime)),
                      if (record.checkOutTime != null) ...[
                        Divider(
                          height: 14,
                          color: AppColors.gold.withValues(alpha: 0.1),
                        ),
                        _kvRow('Salida', _formatTime(record.checkOutTime!)),
                      ],
                      if (record.durationMinutes != null) ...[
                        Divider(
                          height: 14,
                          color: AppColors.gold.withValues(alpha: 0.1),
                        ),
                        _kvRow(
                          'Duración',
                          _formatDuration(record.durationMinutes!),
                        ),
                      ],
                      if (record.workplaceId != null &&
                          workplaceMap[record.workplaceId!] != null) ...[
                        Divider(
                          height: 14,
                          color: AppColors.gold.withValues(alpha: 0.1),
                        ),
                        _kvRow(
                          'Lugar',
                          workplaceMap[record.workplaceId!]!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
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
          ),
      ],
    );
  }

  Widget _kvRow(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(key, style: AppTheme.bodyMd),
        const SizedBox(width: 8),
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