import '../../../attendance/data/models/attendance_model.dart';
import '../../../incidences/data/models/incidence_model.dart';

/// Tipos de incidencia que justifican una ausencia (no cuentan como falta).
const Set<IncidenceType> justificationTypes = {
  IncidenceType.vacaciones,
  IncidenceType.licenciaMedica,
  IncidenceType.enfermedad,
  IncidenceType.accidenteLaboral,
  IncidenceType.comisionServicio,
  IncidenceType.franco,
  IncidenceType.ausenciaJustificada,
};

/// Métricas personales del empleado para un mes seleccionado.
///
/// Servicio puro compartido entre la pantalla Principal del empleado (mes
/// actual, Ronda 3A) y los reportes personales. Centraliza el cálculo de
/// ausencias injustificadas (desde el alta, respetando días laborables y
/// justificativos aprobados) para que sea testeable de forma unitaria.
class EmployeeReportStats {
  final int daysWorked;
  final double totalHours;
  final int lateArrivals;
  final int absences;
  final int justifications;
  final int ownIncidences;
  final bool hasActiveToday;

  const EmployeeReportStats({
    required this.daysWorked,
    required this.totalHours,
    required this.lateArrivals,
    required this.absences,
    required this.justifications,
    required this.ownIncidences,
    required this.hasActiveToday,
  });

  factory EmployeeReportStats.compute({
    required List<AttendanceModel> monthAttendances,
    required List<IncidenceModel> incidences,
    required List<int> laborableDays,
    required DateTime? employmentStart,
    required int selectedMonth,
    required int selectedYear,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final completed = monthAttendances
        .where((a) => a.status == AttendanceStatus.completed)
        .toList();
    final totalMinutes =
        completed.fold<int>(0, (sum, a) => sum + (a.durationMinutes ?? 0));
    final totalHours = totalMinutes / 60;

    final lateArrivals = completed.where((a) => a.isLate ?? false).length;
    final uniqueDays = completed.map((a) => a.date).toSet().length;
    final hasActiveToday =
        monthAttendances.any((a) => a.status == AttendanceStatus.active);

    final today = DateTime(current.year, current.month, current.day);
    final monthStart = DateTime(selectedYear, selectedMonth, 1);
    final monthEnd = DateTime(selectedYear, selectedMonth + 1, 0);
    // Ningún mes genera ausencias posteriores a hoy. En meses futuros la
    // ventana queda vacía y el conteo da 0.
    final windowEnd = monthEnd.isBefore(today) ? monthEnd : today;

    DateTime startFrom = monthStart;
    if (employmentStart != null) {
      final startDate = DateTime(
        employmentStart.year,
        employmentStart.month,
        employmentStart.day,
      );
      if (startDate.isAfter(monthStart)) startFrom = startDate;
    }

    final days = laborableDays.isEmpty ? const [1, 2, 3, 4, 5] : laborableDays;

    final presentDays = monthAttendances
        .where((a) =>
            a.status == AttendanceStatus.completed ||
            a.status == AttendanceStatus.active)
        .toList();
    final workedDays = <DateTime>{};
    for (final a in presentDays) {
      final parsed = DateTime.tryParse(a.date);
      if (parsed != null) {
        workedDays.add(DateTime(parsed.year, parsed.month, parsed.day));
      }
    }

    final justifiedDays = <DateTime>{};
    for (final inc in incidences) {
      if (!justificationTypes.contains(inc.type)) continue;
      if (inc.estado != IncidenceEstado.aprobado) continue;
      var inicio =
          DateTime(inc.fechaInicio.year, inc.fechaInicio.month, inc.fechaInicio.day);
      final fin =
          DateTime(inc.fechaFin.year, inc.fechaFin.month, inc.fechaFin.day);
      if (fin.isBefore(startFrom) || inicio.isAfter(windowEnd)) continue;
      if (inicio.isBefore(startFrom)) inicio = startFrom;
      final last = fin.isAfter(windowEnd) ? windowEnd : fin;
      var d = inicio;
      while (!d.isAfter(last)) {
        if (days.contains(d.weekday)) justifiedDays.add(d);
        d = DateTime(d.year, d.month, d.day + 1);
      }
    }

    final absences = countUnexcusedAbsences(
      startFrom,
      windowEnd,
      days,
      workedDays,
      justifiedDays,
    );

    final justificationCount = incidences.where((inc) =>
        inc.fechaInicio.month == selectedMonth &&
        inc.fechaInicio.year == selectedYear &&
        justificationTypes.contains(inc.type) &&
        inc.estado == IncidenceEstado.aprobado).length;

    final incidenceCount = incidences.where((inc) =>
        inc.fechaInicio.month == selectedMonth &&
        inc.fechaInicio.year == selectedYear).length;

    return EmployeeReportStats(
      daysWorked: uniqueDays,
      totalHours: totalHours,
      lateArrivals: lateArrivals,
      absences: absences,
      justifications: justificationCount,
      ownIncidences: incidenceCount,
      hasActiveToday: hasActiveToday,
    );
  }

  /// Cuenta los días laborables de la ventana que no fueron trabajados ni
  /// cubiertos por una incidencia justificada (ausencias injustificadas).
  static int countUnexcusedAbsences(
    DateTime from,
    DateTime to,
    List<int> days,
    Set<DateTime> workedDays,
    Set<DateTime> justifiedDays,
  ) {
    if (from.isAfter(to)) return 0;
    var count = 0;
    var d = from;
    while (!d.isAfter(to)) {
      if (days.contains(d.weekday) &&
          !workedDays.contains(d) &&
          !justifiedDays.contains(d)) {
        count++;
      }
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return count;
  }
}