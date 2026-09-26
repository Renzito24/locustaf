import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/companies/presentation/providers/company_providers.dart';
import 'package:app_locustaf/features/dashboard/presentation/screens/employee_home_screen.dart';
import 'package:app_locustaf/features/incidences/data/models/incidence_model.dart';
import 'package:app_locustaf/features/incidences/presentation/providers/incidences_provider.dart';
import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';
import 'package:app_locustaf/features/workplaces/presentation/providers/workplace_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pantalla Principal del empleado (Ronda 3A — B3): tarjeta del lugar de
/// trabajo, métricas del mes actual calculadas por [EmployeeReportStats] y
/// versión instalada al pie. Aquí viven los contratos de INC-2 (cálculo de
/// ausencias injustificadas) que antes se probaban en Reportes, ahora contra
/// el flujo real: dados del Firestore fake → stats → tarjetas en pantalla.
void main() {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final today = DateTime(now.year, now.month, now.day);

  String iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  UserModel buildEmployeeUser({required DateTime createdAt}) => UserModel(
        id: 'u1',
        nombre: 'Juan',
        apellido: 'Pérez',
        email: 'juan@test.com',
        dni: '12345678',
        rol: UserRole.employee,
        companyId: 'c1',
        createdAt: createdAt,
      );

  CompanyModel buildCompany({List<int> days = const [1, 2, 3, 4, 5]}) =>
      CompanyModel(
        id: 'c1',
        nombreComercial: 'ACME',
        razonSocial: 'ACME SA',
        cuit: '30-12345678-9',
        createdAt: monthStart,
        diasLaborables: days,
      );

  AttendanceModel attendanceOn(
    DateTime day, {
    AttendanceStatus status = AttendanceStatus.completed,
  }) {
    return AttendanceModel(
      id: 'att-${iso(day)}',
      userId: 'u1',
      checkInTime: DateTime(day.year, day.month, day.day, 9),
      checkOutTime: DateTime(day.year, day.month, day.day, 18),
      durationMinutes: 480,
      date: iso(day),
      status: status,
      companyId: 'c1',
    );
  }

  AttendanceModel activeAttendanceOn(DateTime day) {
    return attendanceOn(day, status: AttendanceStatus.active);
  }

  IncidenceModel justifiedOn(DateTime day, {IncidenceEstado estado = IncidenceEstado.aprobado}) {
    return IncidenceModel(
      id: 'inc-${iso(day)}',
      userId: 'u1',
      type: IncidenceType.enfermedad,
      fechaInicio: DateTime(day.year, day.month, day.day, 8),
      fechaFin: DateTime(day.year, day.month, day.day, 18),
      estado: estado,
      companyId: 'c1',
      createdAt: DateTime.now(),
    );
  }

  Future<void> pumpHome(
    WidgetTester tester, {
    Size size = const Size(800, 1400),
    List<AttendanceModel>? attendances,
    List<IncidenceModel> incidences = const [],
    CompanyModel? company,
    UserModel? currentUser,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final effectiveCompany = company ?? buildCompany();
    final effectiveUser = currentUser ?? buildEmployeeUser(createdAt: monthStart);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('u1'),
          userRoleProvider.overrideWithValue(UserRole.employee),
          attendancesByUserProvider('u1')
              .overrideWith((ref) => Stream.value(attendances ?? <AttendanceModel>[])),
          incidencesStreamProvider.overrideWith((ref) => Stream.value(incidences)),
          currentAppUserProvider.overrideWith((ref) => Stream.value(effectiveUser)),
          currentCompanyProvider.overrideWith((ref) => Stream.value(effectiveCompany)),
          activeWorkplacesProvider
              .overrideWith((ref) => const AsyncValue.data(<WorkplaceModel>[])),
        ],
        child: const MaterialApp(
          home: Scaffold(body: EmployeeHomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Valida el valor dentro de la misma tarjeta de métricas que la etiqueta.
  void expectMetric(WidgetTester tester, String label, String value) {
    final card =
        find.ancestor(of: find.text(label), matching: find.byType(Column)).first;
    expect(
      find.descendant(of: card, matching: find.text(value)),
      findsOneWidget,
      reason: 'métrica "$label" debería mostrar "$value"',
    );
  }

  bool isLaborable(DateTime d, List<int> days) => days.contains(d.weekday);

  int countLaborableDays(DateTime from, DateTime to, List<int> days) {
    if (from.isAfter(to)) return 0;
    var count = 0;
    var d = from;
    while (!d.isAfter(to)) {
      if (isLaborable(d, days)) count++;
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return count;
  }

  List<DateTime> laborableDatesInRange(DateTime from, DateTime to, List<int> days) {
    final result = <DateTime>[];
    var d = from;
    while (!d.isAfter(to)) {
      if (isLaborable(d, days)) result.add(d);
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return result;
  }

  group('Principal (employee) — layout', () {
    testWidgets('pantalla angosta (360x640) sin overflow, con métricas y versión', (tester) async {
      await pumpHome(
        tester,
        size: const Size(360, 640),
        attendances: [attendanceOn(today)],
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Principal'), findsOneWidget);
      expect(find.text('Días trabajados'), findsOneWidget);
      expect(find.text('Ausencias injustificadas'), findsOneWidget);
      // B8: la versión instalada es visible al pie.
      expect(find.textContaining('v2.1'), findsWidgets);
    });

    testWidgets('sin lugar de trabajo asignado: tarjeta con aviso', (tester) async {
      await pumpHome(tester);

      expect(find.text('Sin lugar de trabajo asignado'), findsOneWidget);
    });
  });

  group('Principal (employee) — INC-2: cálculo de ausencias', () {
    testWidgets('no cuenta fines de semana ni días previos al alta', (tester) async {
      final days = const [1, 2, 3, 4, 5];
      await pumpHome(
        tester,
        attendances: [],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: monthStart),
      );

      final expected = countLaborableDays(monthStart, today, days);
      expect(tester.takeException(), isNull);
      expectMetric(tester, 'Ausencias injustificadas', '$expected');
    });

    testWidgets('ausencia justificada aprobada resta del conteo', (tester) async {
      final days = const [1, 2, 3, 4, 5];
      final laborables = laborableDatesInRange(monthStart, today, days);
      if (laborables.isEmpty) return;
      final missed = laborables.first;
      final attended = laborables.where((d) => d != missed).toList();

      await pumpHome(
        tester,
        attendances: attended.map(attendanceOn).toList(),
        incidences: [justifiedOn(missed)],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: monthStart),
      );

      expect(tester.takeException(), isNull);
      expectMetric(tester, 'Ausencias injustificadas', '0');
      expectMetric(tester, 'Justificativos', '1');
    });

    testWidgets('la alta a mitad de mes limita los días contables', (tester) async {
      final days = const [1, 2, 3, 4, 5];
      await pumpHome(
        tester,
        attendances: [],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: today),
      );

      final expected = isLaborable(today, days) ? 1 : 0;
      expect(tester.takeException(), isNull);
      expectMetric(tester, 'Ausencias injustificadas', '$expected');
    });

    testWidgets('respeta los días laborables configurados de la empresa', (tester) async {
      final days = const [1, 2, 3, 4, 5, 6];
      await pumpHome(
        tester,
        attendances: [],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: monthStart),
      );

      final expected = countLaborableDays(monthStart, today, days);
      expect(tester.takeException(), isNull);
      expectMetric(tester, 'Ausencias injustificadas', '$expected');
    });
  });

  group('Principal (employee) — INC-2: contratos nuevos del ajuste', () {
    testWidgets('justificativo rechazado NO resta ausencias', (tester) async {
      final days = const [1, 2, 3, 4, 5];
      final laborables = laborableDatesInRange(monthStart, today, days);
      if (laborables.isEmpty) return;
      final missed = laborables.first;
      final attended = laborables.where((d) => d != missed).toList();

      await pumpHome(
        tester,
        attendances: attended.map(attendanceOn).toList(),
        incidences: [justifiedOn(missed, estado: IncidenceEstado.rechazado)],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: monthStart),
      );

      expect(tester.takeException(), isNull);
      expectMetric(tester, 'Ausencias injustificadas', '1');
      expectMetric(tester, 'Justificativos', '0');
    });

    testWidgets('jornada activa cuenta como presente (D-4)', (tester) async {
      final days = const [1, 2, 3, 4, 5];
      final laborables = laborableDatesInRange(monthStart, today, days);
      if (laborables.isEmpty) return;
      final activeDay = laborables.first;

      await pumpHome(
        tester,
        attendances: [activeAttendanceOn(activeDay)],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: monthStart),
      );

      expect(tester.takeException(), isNull);
      // D-4: el día con jornada activa es presente; el resto de la ventana
      // (desde el alta) queda como ausencias injustificadas.
      final expected = countLaborableDays(monthStart, today, days) - 1;
      expectMetric(tester, 'Ausencias injustificadas', '$expected');
    });

    testWidgets('incidencias propias cuenta todas (aprobadas o no)', (tester) async {
      final days = const [1, 2, 3, 4, 5];
      final laborables = laborableDatesInRange(monthStart, today, days);
      if (laborables.isEmpty) return;
      final attendedDay = laborables.first;

      await pumpHome(
        tester,
        attendances: [attendanceOn(attendedDay)],
        incidences: [justifiedOn(attendedDay, estado: IncidenceEstado.rechazado)],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: monthStart),
      );

      expect(tester.takeException(), isNull);
      expectMetric(tester, 'Días trabajados', '1');
      expectMetric(tester, 'Justificativos', '0');
      expectMetric(tester, 'Incidencias propias', '1');
    });
  });
}