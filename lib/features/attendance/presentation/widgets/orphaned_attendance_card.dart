import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../data/models/attendance_model.dart';
import '../providers/attendance_notifier.dart';

class OrphanedAttendanceCard extends ConsumerWidget {
  final AttendanceModel orphaned;
  final String userId;
  final bool isActionLoading;
  final VoidCallback onDismiss;

  const OrphanedAttendanceCard({
    super.key,
    required this.orphaned,
    required this.userId,
    required this.isActionLoading,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jornada huérfana detectada',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Iniciaste tu jornada el ${_formatDateTime(orphaned.checkInTime)} y superó el horario de fin sin registrar salida.',
                  style: AppTheme.bodyMd,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onDismiss,
            tooltip: 'Descartar aviso',
            icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          OutlinedButton.icon(
            onPressed: isActionLoading
                ? null
                : () {
                    ref.read(attendanceActionProvider.notifier)
                        .finalizeOrphaned(orphaned.id, userId);
                  },
            icon: const Icon(Icons.check_circle_outline, size: 18),
            label: const Text('Finalizar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.warning,
              side: const BorderSide(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
