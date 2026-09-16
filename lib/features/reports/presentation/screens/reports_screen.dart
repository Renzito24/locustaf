import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/services/report_exporter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
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
    final reportRows = ref.watch(paginatedAttendanceReportProvider);
    final totalPages = ref.watch(attendanceReportTotalPagesProvider);
    final currentPage = ref.watch(attendanceReportPageProvider);
    final filter = ref.watch(attendanceReportFilterProvider);
    final workplacesListAsync = ref.watch(workplacesStreamProvider);
    final exporter = ref.watch(reportExporterProvider);

    final anyLoaded = usersAsync.hasValue || workplacesAsync.hasValue || attendancesAsync.hasValue;
    final isLoading = !anyLoaded && (usersAsync.isLoading || workplacesAsync.isLoading || attendancesAsync.isLoading);
    final hasError = usersAsync.hasError || workplacesAsync.hasError || attendancesAsync.hasError;

    return SingleChildScrollView(
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
            AppTheme.errorState('No se pudieron obtener los datos del sistema.')
          else if (isLoading)
            AppTheme.loadingState()
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMetricCards(totalEmployees, presentToday, absentToday, activeWorkplaces),
                const SizedBox(height: 24),
                _buildFilters(ref, filter, workplacesListAsync),
                const SizedBox(height: 16),
                _buildReportHeader(context, reportRows, exporter),
                const SizedBox(height: 12),
                _buildReportTable(reportRows),
                if (totalPages > 1) ...[
                  const SizedBox(height: 12),
                  _buildPagination(context, ref, currentPage, totalPages),
                ],
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

  /// Cabecera del reporte con botones de exportación, responsive: en anchos
/// reducidos el título y los botones se apilan en columna (expandidndose cada
/// botón) para evitar RIGHT OVERFLOWED. (Fase B — C2)
  Widget _buildReportHeader(
    BuildContext context,
    List<AttendanceReportRow> rows,
    ReportExporter exporter,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 480;
        final excelButton = OutlinedButton.icon(
          onPressed: rows.isEmpty ? null : () => _exportExcel(context, rows, exporter),
          icon: const Icon(Icons.grid_on, size: 18),
          label: const Text('Excel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gold,
            side: const BorderSide(color: AppColors.gold),
          ),
        );
        final pdfButton = OutlinedButton.icon(
          onPressed: rows.isEmpty ? null : () => _exportPdf(context, rows, exporter),
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: const Text('PDF'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gold,
            side: const BorderSide(color: AppColors.gold),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reporte de asistencia', style: AppTheme.headingMd),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: excelButton),
                  const SizedBox(width: 8),
                  Expanded(child: pdfButton),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Text('Reporte de asistencia', style: AppTheme.headingMd),
            const Spacer(),
            excelButton,
            const SizedBox(width: 8),
            pdfButton,
          ],
        );
      },
    );
  }

  Widget _buildFilters(
    WidgetRef ref,
    AttendanceReportFilter filter,
    AsyncValue<List<WorkplaceModel>> workplacesAsync,
  ) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;
          final dateField = const _DatePickerField();
          final workplaceField = _buildWorkplaceField(ref, filter, workplacesAsync);
          final clearButton = TextButton.icon(
            onPressed: () {
              ref.read(attendanceReportFilterProvider.notifier).clear();
              ref.read(attendanceReportPageProvider.notifier).reset();
            },
            icon: const Icon(Icons.clear, color: AppColors.textMuted),
            label: const Text('Limpiar', style: TextStyle(color: AppColors.textMuted)),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                dateField,
                const SizedBox(height: 12),
                workplaceField,
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: clearButton,
                ),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 180, child: dateField),
              const SizedBox(width: 16),
              SizedBox(width: 200, child: workplaceField),
              const SizedBox(width: 16),
              clearButton,
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkplaceField(
    WidgetRef ref,
    AttendanceReportFilter filter,
    AsyncValue<List<WorkplaceModel>> workplacesAsync,
  ) {
    return workplacesAsync.when(
      data: (workplaces) => DropdownButtonFormField<String?>(
        initialValue: filter.workplaceId,
        decoration: AppTheme.inputDecoration(label: 'Lugar de trabajo', icon: Icons.business),
        dropdownColor: AppColors.cardDark,
        style: const TextStyle(color: AppColors.textWhite),
        isExpanded: true,
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
          ref.read(attendanceReportPageProvider.notifier).reset();
        },
      ),
      loading: () => const SizedBox(height: 56),
      error: (_, _) => const SizedBox(height: 56),
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
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
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
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildPagination(
    BuildContext context,
    WidgetRef ref,
    int currentPage,
    int totalPages,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: currentPage > 0
              ? () => ref.read(attendanceReportPageProvider.notifier).setPage(currentPage - 1)
              : null,
          icon: const Icon(Icons.chevron_left, color: AppColors.gold),
          tooltip: 'Anterior',
        ),
        Text(
          'Página ${currentPage + 1} de $totalPages',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        IconButton(
          onPressed: currentPage < totalPages - 1
              ? () => ref.read(attendanceReportPageProvider.notifier).setPage(currentPage + 1)
              : null,
          icon: const Icon(Icons.chevron_right, color: AppColors.gold),
          tooltip: 'Siguiente',
        ),
      ],
    );
  }

  Future<void> _exportExcel(
    BuildContext context,
    List<AttendanceReportRow> rows,
    ReportExporter exporter,
  ) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      final saved = await exporter.exportExcel(
        rows,
        fileName: 'reporte_asistencia_$dateStr',
      );
      if (!context.mounted) return;
      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Reporte Excel exportado correctamente'),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.infoSnackBar('Descarga cancelada. No se generó ningún archivo.'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al exportar Excel: $e'),
        );
      }
    }
  }

  Future<void> _exportPdf(
    BuildContext context,
    List<AttendanceReportRow> rows,
    ReportExporter exporter,
  ) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      final saved = await exporter.exportPdf(
        rows,
        fileName: 'reporte_asistencia_$dateStr',
      );
      if (!context.mounted) return;
      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Reporte PDF exportado correctamente'),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.infoSnackBar('Descarga cancelada. No se generó ningún archivo.'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Error al exportar PDF: $e'),
        );
      }
    }
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

/// Selector de fecha del filtro de reportes (Fase B — C3).
///
/// Reemplaza el ingreso manual (evita crashes de `DateTime.parse` con valores
/// inválidos): abre un `showDatePicker`, muestra la fecha en formato amigable
/// `dd/MM/yyyy` y la persiste internamente en el formato del sistema
/// `yyyy-MM-dd` (el mismo que usa `AttendanceModel.date`).
class _DatePickerField extends ConsumerStatefulWidget {
  const _DatePickerField();

  @override
  ConsumerState<_DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends ConsumerState<_DatePickerField> {
  Future<void> _pick(DateTime? current) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: 'Seleccionar fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.white,
              surface: AppColors.cardDark,
              onSurface: AppColors.textWhite,
            ),
          ),
          child: child!,
        );
      },
    );
    if (selected == null || !mounted) return;
    ref.read(attendanceReportFilterProvider.notifier).setDate(formatIsoDate(selected));
    ref.read(attendanceReportPageProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(attendanceReportFilterProvider);
    final date = tryParseIsoDate(filter.date);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      onTap: () => _pick(date),
      child: InputDecorator(
        decoration: AppTheme.inputDecoration(
          label: 'Fecha',
          icon: Icons.calendar_today,
          hint: 'dd/mm/aaaa',
        ),
        isEmpty: date == null,
        child: date == null
            ? null
            : Text(
                formatUserDate(date),
                style: const TextStyle(color: AppColors.textWhite),
              ),
      ),
    );
  }
}
