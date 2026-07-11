import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersStreamProvider);
    final workplacesAsync = ref.watch(allWorkplacesStreamProvider);
    final attendancesAsync = ref.watch(allAttendancesStreamProvider);

    final totalEmployees = ref.watch(totalActiveEmployeesProvider);
    final presentToday = ref.watch(employeesPresentTodayProvider);
    final absentToday = ref.watch(employeesAbsentTodayProvider);
    final activeWorkplaces = ref.watch(activeWorkplacesCountProvider);
    final reportRows = ref.watch(filteredAttendanceReportProvider);
    final filter = ref.watch(attendanceReportFilterProvider);
    final workplacesListAsync = ref.watch(workplacesStreamProvider);

    final anyLoaded = usersAsync.hasValue || workplacesAsync.hasValue || attendancesAsync.hasValue;
    final isLoading = !anyLoaded && (usersAsync.isLoading || workplacesAsync.isLoading || attendancesAsync.isLoading);
    final hasError = usersAsync.hasError || workplacesAsync.hasError || attendancesAsync.hasError;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reportes', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text(
            'Métricas generales del sistema.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 24),
          if (hasError)
            Expanded(
              child: AppTheme.errorState('No se pudieron obtener los datos del sistema.'),
            )
          else if (isLoading)
            Expanded(child: AppTheme.loadingState())
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricCards(totalEmployees, presentToday, absentToday, activeWorkplaces),
                const SizedBox(height: 24),
                _buildFilters(context, ref, filter, workplacesListAsync),
                const SizedBox(height: 16),
                Text('Reporte de asistencia', style: AppTheme.headingMd),
                const SizedBox(height: 12),
                Expanded(child: _buildReportTable(reportRows)),
              ],
            ),
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
              color: AppColors.gold,
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
              label: 'Sucursales activas',
              value: workplaces.toString(),
              color: AppColors.warning,
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
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: TextField(
              decoration: AppTheme.inputDecoration(
                label: 'Fecha',
                icon: Icons.calendar_today,
                hint: 'YYYY-MM-DD',
              ),
              style: const TextStyle(color: AppColors.textWhite),
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
                decoration: AppTheme.inputDecoration(label: 'Lugar de trabajo', icon: Icons.business),
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: AppColors.textWhite),
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
            icon: const Icon(Icons.clear, color: AppColors.textMuted),
            label: const Text('Limpiar', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _buildReportTable(List<AttendanceReportRow> rows) {
    if (rows.isEmpty) {
      return AppTheme.emptyState(
        icon: Icons.table_chart_outlined,
        title: 'Sin registros de asistencia',
        subtitle: 'No hay asistencias completadas para los filtros seleccionados.',
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(AppColors.gold.withValues(alpha: 0.1)),
        columns: const [
          DataColumn(label: Text('Empleado', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
          DataColumn(label: Text('Lugar de trabajo', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
          DataColumn(label: Text('Entrada', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
          DataColumn(label: Text('Salida', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
          DataColumn(label: Text('Duración', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
        ],
        rows: rows.map((row) {
          return DataRow(cells: [
            DataCell(Text(row.employeeName, style: const TextStyle(color: AppColors.textWhite))),
            DataCell(Text(row.workplaceName ?? '-', style: const TextStyle(color: AppColors.textMuted))),
            DataCell(Text(_formatTime(row.checkInTime), style: const TextStyle(color: AppColors.textMuted))),
            DataCell(Text(row.checkOutTime != null ? _formatTime(row.checkOutTime!) : '-', style: const TextStyle(color: AppColors.textMuted))),
            DataCell(Text(row.durationMinutes != null ? '${row.durationMinutes} min' : '-', style: const TextStyle(color: AppColors.textMuted))),
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
    return Container(
      decoration: AppTheme.cardDecoration(),
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
                  color: color.withValues(alpha: 0.15),
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
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
