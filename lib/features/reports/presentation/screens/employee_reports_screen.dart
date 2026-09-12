import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/presentation/providers/attendance_notifier.dart';
import '../../../incidences/data/models/incidence_model.dart';
import '../../../incidences/presentation/providers/incidences_provider.dart';

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
    final allIncidencesAsync = ref.watch(incidencesStreamProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reportes', style: AppTheme.headingLg),
          const SizedBox(height: 4),
          Text('Tus métricas personales de asistencia.', style: AppTheme.bodyLg),
          const SizedBox(height: 24),
          _buildFilterBar(),
          const SizedBox(height: 20),
          attendancesAsync.when(
            data: (allAttendances) {
              final allIncidences = allIncidencesAsync.value ?? [];
              final incidences = allIncidences.where((i) => i.userId == userId).toList();
              final filtered = _filterByMonth(allAttendances);
              final stats = _calculateStats(filtered, incidences);
              return _buildContent(stats, filtered);
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
          final isNarrow = constraints.maxWidth < 500;
          if (isNarrow) {
            return Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedMonth,
                    decoration: AppTheme.inputDecoration(label: 'Mes', icon: Icons.calendar_today),
                    dropdownColor: AppColors.cardDark,
                    style: const TextStyle(color: AppColors.textWhite),
                    items: List.generate(12, (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(months[i]),
                    )),
                    onChanged: (v) => setState(() => _selectedMonth = v ?? DateTime.now().month),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    decoration: AppTheme.inputDecoration(label: 'Año', icon: Icons.date_range),
                    dropdownColor: AppColors.cardDark,
                    style: const TextStyle(color: AppColors.textWhite),
                    items: List.generate(5, (i) {
                      final year = DateTime.now().year - i;
                      return DropdownMenuItem(value: year, child: Text('$year'));
                    }),
                    onChanged: (v) => setState(() => _selectedYear = v ?? DateTime.now().year),
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedMonth,
                  decoration: AppTheme.inputDecoration(label: 'Mes', icon: Icons.calendar_today),
                  dropdownColor: AppColors.cardDark,
                  style: const TextStyle(color: AppColors.textWhite),
                  items: List.generate(12, (i) => DropdownMenuItem(
                    value: i + 1,
                    child: Text(months[i]),
                  )),
                  onChanged: (v) => setState(() => _selectedMonth = v ?? DateTime.now().month),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 140,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedYear,
                  decoration: AppTheme.inputDecoration(label: 'Año', icon: Icons.date_range),
                  dropdownColor: AppColors.cardDark,
                  style: const TextStyle(color: AppColors.textWhite),
                  items: List.generate(5, (i) {
                    final year = DateTime.now().year - i;
                    return DropdownMenuItem(value: year, child: Text('$year'));
                  }),
                  onChanged: (v) => setState(() => _selectedYear = v ?? DateTime.now().year),
                ),
              ),
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

  _ReportStats _calculateStats(List<AttendanceModel> monthAttendances, List<IncidenceModel> incidences) {
    final completed = monthAttendances.where((a) => a.status == AttendanceStatus.completed).toList();
    final totalMinutes = completed.fold<int>(0, (sum, a) => sum + (a.durationMinutes ?? 0));
    final totalHours = totalMinutes / 60;

    int lateArrivals = completed.where((a) => a.isLate ?? false).length;

    final uniqueDays = completed.map((a) => a.date).toSet().length;

    final hasActiveToday = monthAttendances.any((a) => a.status == AttendanceStatus.active);
    final totalWorkingDays = _selectedYear == DateTime.now().year && _selectedMonth == DateTime.now().month
        ? DateTime.now().day
        : _daysInMonth(_selectedYear, _selectedMonth);

    final absences = (totalWorkingDays - uniqueDays).clamp(0, totalWorkingDays);

    final justificationCount = incidences.where((inc) =>
        inc.fechaInicio.month == _selectedMonth &&
        inc.fechaInicio.year == _selectedYear &&
        (inc.type == IncidenceType.vacaciones ||
         inc.type == IncidenceType.licenciaMedica ||
         inc.type == IncidenceType.enfermedad ||
         inc.type == IncidenceType.ausenciaJustificada)
    ).length;

    final incidenceCount = incidences.where((inc) =>
        inc.fechaInicio.month == _selectedMonth &&
        inc.fechaInicio.year == _selectedYear
    ).length;

    return _ReportStats(
      daysWorked: uniqueDays,
      totalHours: totalHours,
      lateArrivals: lateArrivals,
      absences: absences,
      justifications: justificationCount,
      ownIncidences: incidenceCount,
      hasActiveToday: hasActiveToday,
    );
  }

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  Widget _buildContent(
    _ReportStats stats,
    List<AttendanceModel> attendances,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatCards(stats),
          const SizedBox(height: 24),
          Text('Historial personal', style: AppTheme.headingMd),
          const SizedBox(height: 12),
          _buildHistoryTable(attendances),
        ],
      ),
    );
  }

  Widget _buildStatCards(_ReportStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.6,
          children: [
            _StatCard(
              icon: Icons.calendar_today,
              label: 'Días trabajados',
              value: stats.daysWorked.toString(),
              color: AppColors.gold,
            ),
            _StatCard(
              icon: Icons.access_time,
              label: 'Horas trabajadas',
              value: '${stats.totalHours.toStringAsFixed(1)}h',
              color: AppColors.gold,
            ),
            _StatCard(
              icon: Icons.schedule,
              label: 'Llegadas tarde',
              value: stats.lateArrivals.toString(),
              color: stats.lateArrivals > 0 ? AppColors.warning : AppColors.success,
            ),
            _StatCard(
              icon: Icons.cancel_outlined,
              label: 'Ausencias',
              value: stats.absences.toString(),
              color: stats.absences > 0 ? AppColors.error : AppColors.success,
            ),
            _StatCard(
              icon: Icons.description_outlined,
              label: 'Justificativos',
              value: stats.justifications.toString(),
              color: AppColors.goldLight,
            ),
            _StatCard(
              icon: Icons.warning_amber_outlined,
              label: 'Incidencias propias',
              value: stats.ownIncidences.toString(),
              color: stats.ownIncidences > 0 ? AppColors.error : AppColors.success,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryTable(List<AttendanceModel> attendances) {
    if (attendances.isEmpty) {
      return AppTheme.emptyState(
        icon: Icons.table_chart_outlined,
        title: 'Sin registros',
        subtitle: 'No hay asistencias para el período seleccionado.',
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(AppColors.gold.withValues(alpha: 0.1)),
        columns: const [
          DataColumn(label: Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
          DataColumn(label: Text('Entrada', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
          DataColumn(label: Text('Salida', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
          DataColumn(label: Text('Duración', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
          DataColumn(label: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.gold))),
        ],
        rows: attendances.map((a) {
          final isActive = a.status == AttendanceStatus.active;
          return DataRow(cells: [
            DataCell(Text(a.date, style: const TextStyle(color: AppColors.textWhite))),
            DataCell(Text(_formatTime(a.checkInTime), style: const TextStyle(color: AppColors.textMuted))),
            DataCell(Text(a.checkOutTime != null ? _formatTime(a.checkOutTime!) : '-', style: const TextStyle(color: AppColors.textMuted))),
            DataCell(Text(a.durationMinutes != null ? _formatDuration(a.durationMinutes!) : '-', style: const TextStyle(color: AppColors.textMuted))),
            DataCell(
              isActive
                  ? AppTheme.badge(label: 'Activo', bgColor: AppColors.success.withValues(alpha: 0.15), textColor: AppColors.success)
                  : AppTheme.badge(label: 'Completado', bgColor: AppColors.gold.withValues(alpha: 0.1), textColor: AppColors.gold),
            ),
          ]);
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}min';
  }
}

class _ReportStats {
  final int daysWorked;
  final double totalHours;
  final int lateArrivals;
  final int absences;
  final int justifications;
  final int ownIncidences;
  final bool hasActiveToday;

  const _ReportStats({
    required this.daysWorked,
    required this.totalHours,
    required this.lateArrivals,
    required this.absences,
    required this.justifications,
    required this.ownIncidences,
    required this.hasActiveToday,
  });
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, color: color, size: 20),
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
