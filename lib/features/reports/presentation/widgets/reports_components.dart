import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/report_exporter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../providers/reports_provider.dart';

class ReportsMetricCards extends StatelessWidget {
  final int totalEmployees;
  final int presentToday;
  final int absentToday;
  final int activeWorkplaces;

  const ReportsMetricCards({
    super.key,
    required this.totalEmployees,
    required this.presentToday,
    required this.absentToday,
    required this.activeWorkplaces,
  });

  @override
  Widget build(BuildContext context) {
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
              value: totalEmployees.toString(),
              color: AppColors.gold,
            ),
            _MetricCard(
              icon: Icons.check_circle,
              label: 'Presentes hoy',
              value: presentToday.toString(),
              color: AppColors.success,
            ),
            _MetricCard(
              icon: Icons.cancel,
              label: 'Ausentes hoy',
              value: absentToday.toString(),
              color: absentToday > 0 ? AppColors.error : AppColors.success,
            ),
            _MetricCard(
              icon: Icons.business,
              label: 'Sucursales activas',
              value: activeWorkplaces.toString(),
              color: AppColors.warning,
            ),
          ],
        );
      },
    );
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
    return AppCard(
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

class ReportsFilterSection extends ConsumerWidget {
  final AttendanceReportFilter filter;
  final AsyncValue<List<WorkplaceModel>> workplacesAsync;

  const ReportsFilterSection({
    super.key,
    required this.filter,
    required this.workplacesAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
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
}

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

class ReportsHeader extends StatelessWidget {
  final List<AttendanceReportRow> reportRows;
  final ReportExporter exporter;
  final bool workplacesReady;

  const ReportsHeader({
    super.key,
    required this.reportRows,
    required this.exporter,
    required this.workplacesReady,
  });

  bool _needsWorkplacesHint() {
    return !workplacesReady && reportRows.isNotEmpty;
  }

  Widget _workplacesPendingHint() {
    return Row(
      children: [
        const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Cargando lugares de trabajo... La exportación se habilita al terminar.',
            style: AppTheme.bodyMd.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Future<void> _exportExcel(BuildContext context) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      final saved = await exporter.exportExcel(
        reportRows,
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

  Future<void> _exportPdf(BuildContext context) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    try {
      final saved = await exporter.exportPdf(
        reportRows,
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

  @override
  Widget build(BuildContext context) {
    final canExport = reportRows.isNotEmpty && workplacesReady;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 480;
        final excelButton = OutlinedButton.icon(
          onPressed: canExport ? () => _exportExcel(context) : null,
          icon: const Icon(Icons.grid_on, size: 18),
          label: const Text('Excel'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gold,
            side: const BorderSide(color: AppColors.gold),
          ),
        );
        final pdfButton = OutlinedButton.icon(
          onPressed: canExport ? () => _exportPdf(context) : null,
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
              if (_needsWorkplacesHint()) ...[
                const SizedBox(height: 8),
                _workplacesPendingHint(),
              ],
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Reporte de asistencia', style: AppTheme.headingMd),
                const Spacer(),
                excelButton,
                const SizedBox(width: 8),
                pdfButton,
              ],
            ),
            if (_needsWorkplacesHint()) ...[
              const SizedBox(height: 8),
              _workplacesPendingHint(),
            ],
          ],
        );
      },
    );
  }
}

class ReportsTable extends StatelessWidget {
  final List<AttendanceReportRow> reportRows;

  const ReportsTable({
    super.key,
    required this.reportRows,
  });

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (reportRows.isEmpty) {
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
          rows: reportRows.map((row) {
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
}

class ReportsPagination extends ConsumerWidget {
  final int currentPage;
  final int totalPages;

  const ReportsPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
}
