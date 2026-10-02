import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../data/models/history_record_model.dart';
import '../providers/history_provider.dart';
import '../widgets/history_card.dart';
import '../widgets/history_detail_dialog.dart';

class IndicatorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const IndicatorCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: AppTheme.bodyMd,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class LoadMoreButton extends ConsumerWidget {
  final bool hasMore;
  final bool isLoadingMore;

  const LoadMoreButton({
    super.key,
    required this.hasMore,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: isLoadingMore
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : TextButton.icon(
                onPressed: hasMore
                    ? () => ref
                        .read(historyPaginationProvider.notifier)
                        .loadMore()
                    : null,
                icon: const Icon(Icons.expand_more),
                label: Text(hasMore ? 'Cargar más' : 'No hay más registros'),
              ),
      ),
    );
  }
}

class HistoryDataTable extends StatelessWidget {
  final List<HistoryRecordModel> records;
  final bool hasMore;
  final Widget loadMoreButton;

  const HistoryDataTable({
    super.key,
    required this.records,
    required this.hasMore,
    required this.loadMoreButton,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: AppCard(
          padding: const EdgeInsets.all(2),
          child: DataTable(
            columnSpacing: 20,
            headingRowColor: WidgetStateProperty.all(
              AppColors.gold.withValues(alpha: 0.08),
            ),
            columns: const [
              DataColumn(
                label: Text('Empleado',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold)),
              ),
              DataColumn(
                label: Text('Lugar de trabajo',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold)),
              ),
              DataColumn(
                label: Text('Fecha',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold)),
              ),
              DataColumn(
                label: Text('Ingreso',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold)),
              ),
              DataColumn(
                label: Text('Egreso',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold)),
              ),
              DataColumn(
                label: Text('Duración',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold)),
              ),
              DataColumn(
                label: Text('Estado',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold)),
              ),
            ],
            rows: [
              ...records.map((r) {
                return DataRow(
                  onSelectChanged: (_) =>
                      HistoryDetailDialog.show(context, r),
                  cells: [
                    DataCell(Text(r.employeeName,
                        style: const TextStyle(
                            color: AppColors.textWhite))),
                    DataCell(Text(r.workplaceName ?? '-',
                        style: const TextStyle(
                            color: AppColors.textWhite))),
                    DataCell(Text(r.date,
                        style: const TextStyle(
                            color: AppColors.textWhite))),
                    DataCell(Text(r.checkInFormatted,
                        style: const TextStyle(
                            color: AppColors.textWhite))),
                    DataCell(Text(r.checkOutFormatted,
                        style: const TextStyle(
                            color: AppColors.textWhite))),
                    DataCell(Text(r.durationFormatted,
                        style: const TextStyle(
                            color: AppColors.textWhite))),
                    DataCell(_buildStatusChip(r)),
                  ],
                );
              }),
              if (hasMore)
                DataRow(cells: [
                  DataCell(loadMoreButton),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                  const DataCell(Text('')),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(HistoryRecordModel r) {
    final isActive = r.status == AttendanceStatus.active;
    return AppTheme.badge(
      label: isActive ? 'Activo' : 'Completado',
      bgColor: isActive
          ? AppColors.success.withValues(alpha: 0.15)
          : AppColors.cardDark,
      textColor: isActive ? AppColors.success : AppColors.textMuted,
    );
  }
}

class HistoryListMobile extends StatelessWidget {
  final List<HistoryRecordModel> records;
  final bool hasMore;
  final Widget loadMoreButton;

  const HistoryListMobile({
    super.key,
    required this.records,
    required this.hasMore,
    required this.loadMoreButton,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: records.length + (hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == records.length) return loadMoreButton;
        final record = records[index];
        return HistoryCard(
          record: record,
          onTap: () => HistoryDetailDialog.show(context, record),
        );
      },
    );
  }
}
