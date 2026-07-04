import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalEmployees = ref.watch(totalActiveEmployeesProvider);
    final presentToday = ref.watch(employeesPresentTodayProvider);
    final absentToday = ref.watch(employeesAbsentTodayProvider);
    final activeWorkplaces = ref.watch(activeWorkplacesCountProvider);
    final reportRows = ref.watch(filteredAttendanceReportProvider);
    final filter = ref.watch(attendanceReportFilterProvider);
    final workplacesAsync = ref.watch(workplacesStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reportes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Métricas generales del sistema.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _buildMetricCards(totalEmployees, presentToday, absentToday, activeWorkplaces),
          const SizedBox(height: 24),
          _buildFilters(context, ref, filter, workplacesAsync),
          const SizedBox(height: 16),
          const Text(
            'Reporte de asistencia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildReportTable(reportRows)),
        ],
      ),
    );
  }

  Widget _buildMetricCards(int total, int present, int absent, int workplaces) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            _MetricCard(
              icon: Icons.people,
              label: 'Empleados activos',
              value: total.toString(),
              color: AppColors.primary,
            ),
            _MetricCard(
              icon: Icons.check_circle,
              label: 'Presentes hoy',
              value: present.toString(),
              color: AppColors.success,
            ),
            _MetricCard(
              icon: Icons.cancel,
              label: 'Ausentes hoy',
              value: absent.toString(),
              color: absent > 0 ? AppColors.error : AppColors.success,
            ),
            _MetricCard(
              icon: Icons.business,
              label: 'Workplaces activos',
              value: workplaces.toString(),
              color: const Color(0xFF8B5CF6),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilters(
    BuildContext context,
    WidgetRef ref,
    AttendanceReportFilter filter,
    AsyncValue<List<WorkplaceModel>> workplacesAsync,
  ) {
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
            SizedBox(
              width: 180,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Fecha',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                controller: TextEditingController(text: filter.date ?? ''),
                onChanged: (value) {
                  ref.read(attendanceReportFilterProvider.notifier).setDate(
                    value.trim().isEmpty ? null : value.trim(),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 200,
              child: workplacesAsync.when(
                data: (workplaces) => DropdownButtonFormField<String?>(
                  initialValue: filter.workplaceId,
                  decoration: const InputDecoration(
                    labelText: 'Lugar de trabajo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    ...workplaces.map(
                      (w) => DropdownMenuItem<String?>(
                        value: w.id,
                        child: Text(w.nombre, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    ref.read(attendanceReportFilterProvider.notifier).setWorkplaceId(value);
                  },
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              onPressed: () {
                ref.read(attendanceReportFilterProvider.notifier).clear();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTable(List<AttendanceReportRow> rows) {
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_outlined, size: 64, color: Colors.grey.shade400),
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
              'No hay asistencias completadas para los filtros seleccionados.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.05)),
        columns: const [
          DataColumn(label: Text('Empleado', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Lugar de trabajo', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Entrada', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Salida', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Duración', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: rows.map((row) {
          return DataRow(cells: [
            DataCell(Text(row.employeeName)),
            DataCell(Text(row.workplaceName ?? '-')),
            DataCell(Text(_formatTime(row.checkInTime))),
            DataCell(Text(row.checkOutTime != null ? _formatTime(row.checkOutTime!) : '-')),
            DataCell(Text(row.durationMinutes != null ? '${row.durationMinutes} min' : '-')),
          ]);
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
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
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
