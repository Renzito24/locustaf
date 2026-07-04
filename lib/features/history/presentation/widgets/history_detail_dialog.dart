import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Detalle de asistencia',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 24),
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
                    : AppColors.textSecondary,
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
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
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
