import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/attendance_model.dart';
import '../providers/attendance_notifier.dart';

class AdminAttendanceHeader extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final bool isToday;
  final bool isActionLoading;
  final VoidCallback onManualCheckIn;

  const AdminAttendanceHeader({
    super.key,
    required this.selectedDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.isToday,
    required this.isActionLoading,
    required this.onManualCheckIn,
  });

  String _formatDate(DateTime dt) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return '${dt.day} de ${months[dt.month - 1]} de ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Asistencia', style: AppTheme.headingLg),
        const SizedBox(height: 4),
        Text(
          'Consultá las asistencias del día y registrá ingresos manuales.',
          style: AppTheme.bodyLg,
        ),
        const SizedBox(height: 24),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: onPreviousDay,
                icon: const Icon(Icons.chevron_left, color: AppColors.gold),
                tooltip: 'Día anterior',
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _formatDate(selectedDate),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textWhite,
                      ),
                    ),
                    if (isToday) ...[
                      const SizedBox(height: 2),
                      Text('Hoy', style: AppTheme.bodyMd),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onNextDay,
                icon: const Icon(Icons.chevron_right, color: AppColors.gold),
                tooltip: 'Día siguiente',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isActionLoading ? null : onManualCheckIn,
            icon: isActionLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.person_add_alt_1),
            label: Text(
                isActionLoading ? 'Registrando...' : 'Registrar ingreso manual'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class AdminAttendanceList extends StatelessWidget {
  final List<AttendanceModel> dayAttendances;
  final Map<String, UserModel> userMap;
  final Map<String, String> workplaceMap;

  const AdminAttendanceList({
    super.key,
    required this.dayAttendances,
    required this.userMap,
    required this.workplaceMap,
  });

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}min';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Asistencias del día', style: AppTheme.headingMd),
        const SizedBox(height: 12),
        if (dayAttendances.isEmpty)
          AppTheme.emptyState(
            icon: Icons.event_busy,
            title: 'Sin asistencias',
            subtitle: 'No hay registros para esta fecha.',
          )
        else
          ...dayAttendances.map((a) {
            final user = userMap[a.userId];
            final name = user?.nombreCompleto ??
                'Usuario ${StringUtils.safePrefix(a.userId, 6)}';
            final workplaceName =
                a.workplaceId != null ? workplaceMap[a.workplaceId!] : null;
            final isActive = a.status == AttendanceStatus.active;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isActive
                          ? Icons.play_circle_outline
                          : Icons.check_circle_outline,
                      color: isActive ? AppColors.success : AppColors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Entrada: ${_formatTime(a.checkInTime)}'
                            '${a.checkOutTime != null ? '  |  Salida: ${_formatTime(a.checkOutTime!)}' : ''}'
                            '${a.durationMinutes != null ? '  |  ${_formatDuration(a.durationMinutes!)}' : ''}',
                            style: AppTheme.bodyMd,
                          ),
                          if (workplaceName != null)
                            Text(
                              'Lugar: $workplaceName',
                              style: AppTheme.bodyMd.copyWith(
                                fontSize: 11,
                                color: AppColors.textMuted.withValues(alpha: 0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isActive)
                      const Text(
                        'Activo',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class AdminAttendanceDialogs {
  static Future<void> showManualCheckInDialog(
    BuildContext context,
    WidgetRef ref,
    List<UserModel> users,
  ) async {
    final eligible = users
        .where((u) =>
            u.isActive &&
            !u.isDeleted &&
            u.rol != UserRole.superadmin &&
            u.lugarDeTrabajoId != null &&
            u.lugarDeTrabajoId!.isNotEmpty)
        .toList();

    if (eligible.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppTheme.errorSnackBar(
            'No hay empleados activos con lugar de trabajo asignado.'),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.18)),
        ),
        title: const Text(
          'Registrar ingreso manual',
          style: TextStyle(color: AppColors.textWhite),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: eligible.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: AppColors.gold.withValues(alpha: 0.08),
            ),
            itemBuilder: (context, index) {
              final user = eligible[index];
              return ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.gold),
                title: Text(
                  user.nombreCompleto,
                  style: const TextStyle(color: AppColors.textWhite),
                ),
                subtitle: Text(
                  user.email,
                  style: AppTheme.bodyMd,
                ),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  ref.read(attendanceActionProvider.notifier).manualCheckIn(user.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }
}
