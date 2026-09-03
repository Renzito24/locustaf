import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../data/models/history_record_model.dart';
import '../providers/history_provider.dart';
import '../widgets/history_card.dart';
import '../widgets/history_detail_dialog.dart';
import '../widgets/history_filter_bar.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(filteredHistoryProvider);
    final total = ref.watch(attendanceTotalCountProvider).value ?? 0;
    final active = ref.watch(activeRecordsProvider);
    final completed = ref.watch(completedRecordsProvider);
    final pageState = ref.watch(historyPaginationProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Historial de Asistencias', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text(
            'Consulta todas las jornadas registradas en el sistema.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 24),
          _buildIndicatorCards(total, active, completed),
          const SizedBox(height: 24),
          const HistoryFilterBar(),
          const SizedBox(height: 20),
          _buildContent(context, records, pageState),
        ],
      ),
    );
  }

  Widget _buildIndicatorCards(int total, int active, int completed) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 3 : 1;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
          children: [
            _IndicatorCard(
              icon: Icons.list_alt,
              label: 'Total registros',
              value: total.toString(),
              color: AppColors.gold,
            ),
            _IndicatorCard(
              icon: Icons.play_circle,
              label: 'Jornadas activas',
              value: active.toString(),
              color: AppColors.success,
            ),
            _IndicatorCard(
              icon: Icons.check_circle,
              label: 'Jornadas finalizadas',
              value: completed.toString(),
              color: AppColors.textMuted,
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<HistoryRecordModel> records,
    AsyncValue<HistoryPageState> pageState,
  ) {
    final isLoading = pageState.isLoading;
    final hasMore = pageState.value?.hasMore ?? false;
    final isLoadingMore = pageState.isLoading && records.isNotEmpty;

    if (isLoading && records.isEmpty) {
      return AppTheme.loadingState(message: 'Cargando historial...');
    }

    if (pageState.hasError && records.isEmpty) {
      return AppTheme.errorState('Error al cargar el historial: ${pageState.error}');
    }

    return _buildPageContent(
      context,
      records,
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
    );
  }

  Widget _buildPageContent(
    BuildContext context,
    List<HistoryRecordModel> records, {
    required bool hasMore,
    required bool isLoadingMore,
  }) {
    if (records.isEmpty) {
      final loadMoreButton = _LoadMoreButton(
        hasMore: hasMore,
        isLoadingMore: isLoadingMore,
      );
      if (!hasMore) {
        return AppTheme.emptyState(
          icon: Icons.history,
          title: 'Sin registros de asistencia',
          subtitle: 'No hay asistencias para los filtros seleccionados.',
        );
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Sin coincidencias en las páginas cargadas.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
            loadMoreButton,
          ],
        ),
      );
    }

    final loadMoreButton = _LoadMoreButton(
      hasMore: hasMore,
      isLoadingMore: isLoadingMore,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 800) {
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

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              decoration: AppTheme.cardDecoration(),
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
      },
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

class _LoadMoreButton extends ConsumerWidget {
  final bool hasMore;
  final bool isLoadingMore;

  const _LoadMoreButton({
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

class _IndicatorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _IndicatorCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(),
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
