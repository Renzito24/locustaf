import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/report_exporter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/presentation/providers/attendance_notifier.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../providers/reports_provider.dart';

/// Reportes del empleado (Ronda 3A — B5).
///
/// Selección de mes/año y exportación a PDF/Excel del reporte de asistencia
/// personal (solo sus jornadas completadas del período seleccionado).
class EmployeeReportsScreen extends ConsumerStatefulWidget {
  const EmployeeReportsScreen({super.key});

  @override
  ConsumerState<EmployeeReportsScreen> createState() => _EmployeeReportsScreenState();
}

class _EmployeeReportsScreenState extends ConsumerState<EmployeeReportsScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AppTheme.emptyState(
          icon: Icons.person_off_outlined,
          title: 'Usuario no autenticado',
          subtitle: 'Iniciá sesión para ver tus reportes.',
        ),
      );
    }

    final attendancesAsync = ref.watch(attendancesByUserProvider(userId));
    final userAsync = ref.watch(currentAppUserProvider);
    final workplacesAsync = ref.watch(activeWorkplacesProvider);
    final exporter = ref.watch(reportExporterProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reportes', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text(
            'Descargá el reporte mensual de tus asistencias.',
            style: AppTheme.bodyLg,
          ),
          const SizedBox(height: 24),
          _buildFilterBar(),
          const SizedBox(height: 20),
          attendancesAsync.when(
            data: (allAttendances) {
              final filtered = _filterByMonth(allAttendances);
              final rows = _buildRows(filtered, userAsync.value, workplacesAsync);
              return _buildExportSection(context, rows, exporter);
            },
            loading: () => AppTheme.loadingState(message: 'Cargando reportes...'),
            error: (e, _) => AppTheme.errorState('Error al cargar reportes: $e'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
    ];

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final monthField = SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<int>(
              initialValue: _selectedMonth,
              isExpanded: true,
              decoration: AppTheme.inputDecoration(label: 'Mes', icon: Icons.calendar_today),
              dropdownColor: AppColors.cardDark,
              style: const TextStyle(color: AppColors.textWhite),
              items: List.generate(12, (i) => DropdownMenuItem(
                value: i + 1,
                child: Text(months[i]),
              )),
              onChanged: (v) => setState(() => _selectedMonth = v ?? DateTime.now().month),
            ),
          );
          final yearField = SizedBox(
            width: double.infinity,
            child: DropdownButtonFormField<int>(
              initialValue: _selectedYear,
              isExpanded: true,
              decoration: AppTheme.inputDecoration(label: 'Año', icon: Icons.date_range),
              dropdownColor: AppColors.cardDark,
              style: const TextStyle(color: AppColors.textWhite),
              items: List.generate(5, (i) {
                final year = DateTime.now().year - i;
                return DropdownMenuItem(value: year, child: Text('$year'));
              }),
              onChanged: (v) => setState(() => _selectedYear = v ?? DateTime.now().year),
            ),
          );

          final isNarrow = constraints.maxWidth < 500;
          if (isNarrow) {
            return Column(
              children: [
                monthField,
                const SizedBox(height: 12),
                yearField,
              ],
            );
          }
          return Row(
            children: [
              SizedBox(width: 200, child: monthField),
              const SizedBox(width: 16),
              SizedBox(width: 140, child: yearField),
            ],
          );
        },
      ),
    );
  }

  List<AttendanceModel> _filterByMonth(List<AttendanceModel> all) {
    return all.where((a) {
      final d = a.checkInTime;
      return d.month == _selectedMonth && d.year == _selectedYear;
    }).toList();
  }

  List<AttendanceReportRow> _buildRows(
    List<AttendanceModel> month,
    UserModel? user,
    AsyncValue<List<WorkplaceModel>> workplacesAsync,
  ) {
    final workplaceMap = <String, String>{};
    workplacesAsync.whenData((list) {
      for (final w in list) {
        workplaceMap[w.id] = w.nombre;
      }
    });

    final completed = month
        .where((a) => a.status == AttendanceStatus.completed)
        .toList()
      ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    return completed.map((a) {
      return AttendanceReportRow(
        employeeName: user?.nombreCompleto ?? 'Empleado',
        workplaceName: a.workplaceId != null ? workplaceMap[a.workplaceId!] : null,
        checkInTime: a.checkInTime,
        checkOutTime: a.checkOutTime,
        durationMinutes: a.durationMinutes,
      );
    }).toList();
  }

  Widget _buildExportSection(
    BuildContext context,
    List<AttendanceReportRow> rows,
    ReportExporter exporter,
  ) {
    final monthName = _monthName(_selectedMonth);

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reporte de asistencia de $monthName de $_selectedYear',
            style: AppTheme.headingMd,
          ),
          const SizedBox(height: 4),
          if (rows.isEmpty)
            Text(
              'Sin registros para el período seleccionado.',
              style: AppTheme.bodyMd,
            )
          else
            Row(
              children: [
                Text(
                  '${rows.length}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'jornada(s) completadas.',
                    style: AppTheme.bodyMd,
                  ),
                ),
              ],
            ),
          if (rows.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'No se pueden exportar reportes si no hay asistencias completadas.',
              style: AppTheme.bodyMd.copyWith(color: AppColors.warning),
            ),
          ],
          const SizedBox(height: 16),
          LayoutBuilder(
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
                return Row(
                  children: [
                    Expanded(child: excelButton),
                    const SizedBox(width: 8),
                    Expanded(child: pdfButton),
                  ],
                );
              }
              return Row(
                children: [
                  excelButton,
                  const SizedBox(width: 8),
                  pdfButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
    ];
    return months[month - 1];
  }

  String _periodSuffix() {
    return '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}';
  }

  Future<void> _exportExcel(
    BuildContext context,
    List<AttendanceReportRow> rows,
    ReportExporter exporter,
  ) async {
    try {
      final saved = await exporter.exportExcel(
        rows,
        fileName: 'reporte_asistencia_${_periodSuffix()}',
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
    try {
      final saved = await exporter.exportPdf(
        rows,
        fileName: 'reporte_asistencia_${_periodSuffix()}',
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