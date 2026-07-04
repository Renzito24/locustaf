import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../data/models/history_record_model.dart';

class HistoryCard extends StatelessWidget {
  final HistoryRecordModel record;
  final VoidCallback? onTap;

  const HistoryCard({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                        color: AppColors.textPrimary,
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
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AttendanceStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isActive = status == AttendanceStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Activo' : 'Completado',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.success : AppColors.textSecondary,
        ),
      ),
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
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
