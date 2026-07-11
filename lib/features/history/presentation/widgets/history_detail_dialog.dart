import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../data/models/history_record_model.dart';

class HistoryDetailDialog extends StatelessWidget {
  final HistoryRecordModel record;

  const HistoryDetailDialog({super.key, required this.record});

  static Future<void> show(BuildContext context, HistoryRecordModel record) {
    return showDialog(
      context: context,
      builder: (_) => HistoryDetailDialog(record: record),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        side: BorderSide(
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.12),
                    ),
                    child: const Icon(Icons.info_outline,
                        color: AppColors.gold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Detalle de asistencia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textWhite,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close,
                        color: AppColors.textMuted.withValues(alpha: 0.7)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Divider(
                height: 24,
                color: AppColors.gold.withValues(alpha: 0.15),
              ),
              _DetailRow(label: 'Nombre', value: record.employeeName),
              _DetailRow(label: 'Email', value: record.employeeEmail),
              _DetailRow(label: 'Workplace', value: record.workplaceName ?? '-'),
              _DetailRow(label: 'Fecha', value: record.date),
              _DetailRow(label: 'Hora ingreso', value: record.checkInFormatted),
              _DetailRow(label: 'Hora egreso', value: record.checkOutFormatted),
              _DetailRow(label: 'Duración', value: record.durationFormatted),
              _DetailRow(
                label: 'Estado',
                value: record.statusLabel,
                valueColor: record.status == AttendanceStatus.active
                    ? AppColors.success
                    : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTheme.bodyMd,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textWhite,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
