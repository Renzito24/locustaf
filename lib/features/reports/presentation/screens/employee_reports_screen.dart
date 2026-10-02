import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/user_model.dart';
import '../../../../core/services/report_exporter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/presentation/providers/attendance_notifier.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../providers/reports_provider.dart';
import 'employee_reports_components.dart';

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
          EmployeeReportsFilterBar(
            selectedMonth: _selectedMonth,
            selectedYear: _selectedYear,
            onMonthChanged: (v) => setState(() => _selectedMonth = v ?? DateTime.now().month),
            onYearChanged: (v) => setState(() => _selectedYear = v ?? DateTime.now().year),
          ),
          const SizedBox(height: 20),
          attendancesAsync.when(
            data: (allAttendances) {
              final filtered = _filterByMonth(allAttendances);
              final rows = _buildRows(filtered, userAsync.value, workplacesAsync);
              return EmployeeReportsExportSection(
                selectedMonth: _selectedMonth,
                selectedYear: _selectedYear,
                rowsCount: rows.length,
                workplacesReady: workplacesAsync.hasValue,
                onExportExcel: () => _exportExcel(context, rows, exporter),
                onExportPdf: () => _exportPdf(context, rows, exporter),
              );
            },
            loading: () => AppTheme.loadingState(message: 'Cargando reportes...'),
            error: (e, _) => AppTheme.errorState('Error al cargar reportes: $e'),
          ),
        ],
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