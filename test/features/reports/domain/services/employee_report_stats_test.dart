import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/incidences/data/models/incidence_model.dart';
import 'package:app_locustaf/features/reports/domain/services/employee_report_stats.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests unitarios del servicio puro [EmployeeReportStats] (INC-2): el cálculo
/// de ausencias injustificadas queda acá testeado con datos deterministas,
/// incluida la ventana futura que la UI no puede seleccionar (Principal siempre
/// muestra el mes actual).
void main() {
  // Escenario fijo: abril 2026, hoy = viernes 10/04 (laborable).
  final now = DateTime(2026, 4, 10);
  const labDays = [1, 2, 3, 4, 5]; // lun-vie

  AttendanceModel completedOn(String date) {
    return AttendanceModel(
      id: 'a-$date',
      userId: 'u1',
      checkInTime: DateTime(2026, 4, int.parse(date.split('-')[2]), 9),
      checkOutTime: DateTime(2026, 4, int.parse(date.split('-')[2]), 18),
      durationMinutes: 480,
      date: date,
      status: AttendanceStatus.completed,
      companyId: 'c1',
    );
  }

  AttendanceModel activeOn(String date) {
    return AttendanceModel(
      id: 'a-active-$date',
      userId: 'u1',
      checkInTime: DateTime(2026, 4, int.parse(date.split('-')[2]), 9),
      date: date,
      status: AttendanceStatus.active,
      companyId: 'c1',
    );
  }

  IncidenceModel justifiedOn(String date, {IncidenceEstado estado = IncidenceEstado.aprobado}) {
    return IncidenceModel(
      id: 'inc-$date',
      userId: 'u1',
      type: IncidenceType.enfermedad,
      fechaInicio: DateTime(2026, 4, int.parse(date.split('-')[2]), 8),
      fechaFin: DateTime(2026, 4, int.parse(date.split('-')[2]), 18),
      estado: estado,
      companyId: 'c1',
      createdAt: now,
    );
  }

  EmployeeReportStats compute({
    List<AttendanceModel>? attendances,
    List<IncidenceModel> incidences = const [],
    DateTime? employmentStart,
    int selectedMonth = 4,
    int selectedYear = 2026,
  }) {
    return EmployeeReportStats.compute(
      monthAttendances: attendances ?? [],
      incidences: incidences,
      laborableDays: labDays,
      employmentStart: employmentStart ?? DateTime(2026, 1, 1),
      selectedMonth: selectedMonth,
      selectedYear: selectedYear,
      now: now,
    );
  }

  group('EmployeeReportStats — ventana del período', () {
    test('mes futuro seleccionado da 0 ausencias', () {
      final stats = compute(selectedMonth: 5, selectedYear: 2026);

      expect(stats.absences, 0);
      expect(stats.daysWorked, 0);
      expect(stats.totalHours, 0);
    });

    test('mes anterior al alta no genera ausencias (ventana fuera del alta)', () {
      final stats = compute(
        selectedMonth: 3,
        selectedYear: 2026,
        employmentStart: DateTime(2026, 4, 6),
      );

      // El alta es abr/06: la ventana de marzo queda toda previa al alta.
      expect(stats.absences, 0);
    });
  });

  group('EmployeeReportStats — ausencias injustificadas', () {
    test('cuenta solo los días laborables de la ventana desde el alta', () {
      // Alta el lun 06/04 → ventana abr/06..abr/10 = 5 días laborables.
      final stats = compute(employmentStart: DateTime(2026, 4, 6));

      expect(stats.absences, 5);
    });

    test('justificativo aprobado cubre la ausencia; rechazado no', () {
      final approved = compute(
        incidences: [justifiedOn('2026-04-07')],
        employmentStart: DateTime(2026, 4, 6),
      );
      expect(approved.absences, 4);
      expect(approved.justifications, 1);

      final rejected = compute(
        incidences: [justifiedOn('2026-04-07', estado: IncidenceEstado.rechazado)],
        employmentStart: DateTime(2026, 4, 6),
      );
      expect(rejected.absences, 5);
      expect(rejected.justifications, 0);
    });

    test('jornada activa cuenta como presente (D-4)', () {
      final stats = compute(
        attendances: [activeOn('2026-04-07')],
        employmentStart: DateTime(2026, 4, 6),
      );

      expect(stats.absences, 4); // 06, 08, 09, 10 quedan ausentes
      expect(stats.daysWorked, 0); // solo las completadas suman días trabajados
    });

    test('días trabajados y horas suman solo jornadas completadas', () {
      final stats = compute(attendances: [
        completedOn('2026-04-07'),
        activeOn('2026-04-08'),
      ]);

      expect(stats.daysWorked, 1);
      expect(stats.totalHours, 8.0);
      expect(stats.lateArrivals, 0);
      expect(stats.absences, 8 - 2); // 8 laborables abr/01..10 − 2 presentes
    });
  });
}