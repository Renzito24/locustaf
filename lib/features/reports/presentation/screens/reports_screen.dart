import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/data_providers.dart';
import '../../../../core/services/report_exporter.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/reports_provider.dart';
import '../widgets/reports_components.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';

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
    final workplacesReady = ref.watch(workplacesNamesReadyProvider);
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
                ReportsMetricCards(
                  totalEmployees: totalEmployees,
                  presentToday: presentToday,
                  absentToday: absentToday,
                  activeWorkplaces: activeWorkplaces,
                ),
                const SizedBox(height: 24),
                ReportsFilterSection(
                  filter: filter,
                  workplacesAsync: workplacesListAsync,
                ),
                const SizedBox(height: 16),
                ReportsHeader(
                  reportRows: reportRows,
                  exporter: exporter,
                  workplacesReady: workplacesReady,
                ),
                const SizedBox(height: 12),
                ReportsTable(reportRows: reportRows),
                if (totalPages > 1) ...[
                  const SizedBox(height: 12),
                  ReportsPagination(
                    currentPage: currentPage,
                    totalPages: totalPages,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
