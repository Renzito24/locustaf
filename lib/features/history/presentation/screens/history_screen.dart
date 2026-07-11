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
    final total = ref.watch(totalRecordsProvider);
    final active = ref.watch(activeRecordsProvider);
    final completed = ref.watch(completedRecordsProvider);
    final attendancesAsync = ref.watch(allAttendancesProvider);

    return Padding(
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
          Expanded(child: _buildContent(context, records, attendancesAsync)),
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
    AsyncValue<List<AttendanceModel>> attendancesAsync,
  ) {
    return attendancesAsync.when(
      data: (_) {
        if (records.isEmpty) {
          return AppTheme.emptyState(
            icon: Icons.history,
            title: 'Sin registros de asistencia',
            subtitle: 'No hay asistencias para los filtros seleccionados.',
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 800) {
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final record = records[index];
                  return HistoryCard(
                    record: record,
                    onTap: () => HistoryDetailDialog.show(context, record),
                  );
                },
              );
            }

            return SingleChildScrollView(
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
                  rows: records.map((r) {
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
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
      loading: () => AppTheme.loadingState(message: 'Cargando historial...'),
      error: (e, _) => AppTheme.errorState('Error al cargar el historial: $e'),
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
