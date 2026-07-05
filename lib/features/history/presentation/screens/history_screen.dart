import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
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
          const Text(
            'Historial de Asistencias',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Consulta todas las jornadas registradas en el sistema.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
              color: AppColors.primary,
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
              color: AppColors.textSecondary,
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'Sin registros de asistencia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No hay asistencias para los filtros seleccionados.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
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
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.05)),
                columns: const [
                  DataColumn(label: Text('Empleado', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Lugar de trabajo', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Ingreso', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Egreso', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Duración', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: records.map((r) {
                  return DataRow(
                    onSelectChanged: (_) => HistoryDetailDialog.show(context, r),
                    cells: [
                      DataCell(Text(r.employeeName)),
                      DataCell(Text(r.workplaceName ?? '-')),
                      DataCell(Text(r.date)),
                      DataCell(Text(r.checkInFormatted)),
                      DataCell(Text(r.checkOutFormatted)),
                      DataCell(Text(r.durationFormatted)),
                      DataCell(_buildStatusChip(r)),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar el historial',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(HistoryRecordModel r) {
    final isActive = r.status == AttendanceStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? AppColors.success.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
