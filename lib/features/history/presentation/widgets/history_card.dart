import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../data/models/history_record_model.dart';

class HistoryCard extends StatelessWidget {
  final HistoryRecordModel record;
  final VoidCallback? onTap;

  const HistoryCard({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        record.employeeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textWhite,
                        ),
                      ),
                    ),
                    _StatusBadge(status: record.status),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(icon: Icons.work, text: record.workplaceName ?? '-'),
                    const SizedBox(width: 12),
                    _InfoChip(icon: Icons.calendar_today, text: record.date),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _InfoChip(icon: Icons.login, text: record.checkInFormatted),
                    const SizedBox(width: 12),
                    _InfoChip(icon: Icons.logout, text: record.checkOutFormatted),
                    const SizedBox(width: 12),
                    _InfoChip(icon: Icons.timer, text: record.durationFormatted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AttendanceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == AttendanceStatus.active;
    return AppTheme.badge(
      label: isActive ? 'Activo' : 'Completado',
      bgColor: isActive
          ? AppColors.success.withValues(alpha: 0.15)
          : AppColors.cardDark,
      textColor: isActive ? AppColors.success : AppColors.textMuted,
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.gold.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppTheme.bodyMd.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}
