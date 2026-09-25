import 'package:app_locustaf/core/models/company_model.dart';
import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/router/app_routes.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/companies/presentation/providers/company_providers.dart';
import 'package:app_locustaf/features/dashboard/presentation/widgets/dashboard_layout.dart';
import 'package:app_locustaf/features/incidences/data/models/incidence_model.dart';
import 'package:app_locustaf/features/incidences/presentation/providers/incidences_provider.dart';
import 'package:app_locustaf/features/reports/presentation/screens/employee_reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regresión del flujo real del usuario común (Fase B — 3ª corrección).
///
/// El usuario reportó `BOTTOM OVERFLOWED` en Reportes entrando con rol
/// empleado. A diferencia de Incidencias/Documentación, la causa está en la
/// grilla de métricas personales de [EmployeeReportsScreen], que usa 2
/// columnas fijas con `childAspectRatio` en pantallas angostas. Este test
/// monta la composición real (GoRouter → ShellRoute → DashboardLayout →
/// [EmployeeReportsScreen]) con teléfono chico y textScale 1.3, y el rol del
/// usuario común.
void main() {
  final now = DateTime.now();
  final todayIso = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  final monthStart = DateTime(now.year, now.month, 1);
  final today = DateTime(now.year, now.month, now.day);

  final attendance = AttendanceModel(
    id: 'a1',
    userId: 'u1',
    checkInTime: now,
    checkOutTime: now.add(const Duration(hours: 8)),
    durationMinutes: 480,
    date: todayIso,
    status: AttendanceStatus.completed,
    companyId: 'c1',
  );

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

  CompanyModel buildCompany({List<int> days = const [1, 2, 3, 4, 5]}) => CompanyModel(
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
    return AttendanceModel(
      id: 'att-active-${iso(day)}',
      userId: 'u1',
      checkInTime: DateTime(day.year, day.month, day.day, 9),
      date: iso(day),
      status: AttendanceStatus.active,
      companyId: 'c1',
    );
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

  // Valida el valor de una tarjeta de métricas buscando la etiqueta y
  // verificando que el valor esté dentro de la misma columna de la tarjeta.
  void expectCardValue(WidgetTester tester, String label, String value) {
    final card =
        find.ancestor(of: find.text(label), matching: find.byType(Column)).first;
    expect(
      find.descendant(of: card, matching: find.text(value)),
      findsOneWidget,
    );
  }

  Future<void> pumpEmployeeReportsInShell(
    WidgetTester tester, {
    required Size size,
    List<AttendanceModel>? attendances,
    List<IncidenceModel> incidences = const [],
    CompanyModel? company,
    UserModel? currentUser,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final effectiveAttendances = attendances ?? [attendance];
    final effectiveCompany = company ?? buildCompany();
    final effectiveUser = currentUser ?? buildEmployeeUser(createdAt: monthStart);

    final router = GoRouter(
      initialLocation: RoutePaths.reports,
      routes: [
        ShellRoute(
          builder: (context, state, child) => DashboardLayout(child: child),
          routes: [
            GoRoute(path: RoutePaths.reports, builder: (_, _) => const EmployeeReportsScreen()),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('u1'),
          userRoleProvider.overrideWithValue(UserRole.employee),
          attendancesByUserProvider('u1').overrideWith((ref) => Stream.value(effectiveAttendances)),
          incidencesStreamProvider.overrideWith((ref) => Stream.value(incidences)),
          currentAppUserProvider.overrideWith((ref) => Stream.value(effectiveUser)),
          currentCompanyProvider.overrideWith((ref) => Stream.value(effectiveCompany)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(
                padding: mq.padding.copyWith(top: 24, bottom: 24),
                viewPadding: mq.viewPadding.copyWith(top: 24, bottom: 24),
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Reportes del usuario común en el shell real (360px, textScale 1.3)', () {
    testWidgets('con métricas y asistencias no produce BOTTOM OVERFLOWED y el contenido scrollea', (
      tester,
    ) async {
      await pumpEmployeeReportsInShell(tester, size: const Size(360, 640));

      expect(tester.takeException(), isNull);

      // Los controles del filtro siguen accesibles.
      expect(find.text('Mes'), findsOneWidget);
      expect(find.text('Año'), findsOneWidget);
      // Las métricas personales están presentes.
      expect(find.text('Días trabajados'), findsOneWidget);
      expect(find.text('Horas trabajadas'), findsOneWidget);

      // El historial (debajo de las tarjetas) es alcanzable con scroll.
      await tester.scrollUntilVisible(
        find.text('Historial personal'),
        400,
        maxScrolls: 30,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Historial personal'), findsOneWidget);
    });

    testWidgets('pantalla muy baja (360x568) con métricas no produce overflow', (tester) async {
      await pumpEmployeeReportsInShell(tester, size: const Size(360, 568));

      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Historial personal'),
        400,
        maxScrolls: 30,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('INC-2 — cálculo de ausencias', () {
    testWidgets('no cuenta fines de semana ni días previos al alta', (tester) async {
      final days = const [1, 2, 3, 4, 5];
      await pumpEmployeeReportsInShell(
        tester,
        size: const Size(360, 640),
        attendances: [],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: monthStart),
      );

      final expected = countLaborableDays(monthStart, today, days);
      expect(tester.takeException(), isNull);
      expectCardValue(tester, 'Ausencias injustificadas', '$expected');
    });

    testWidgets('ausencia justificada aprobada resta del conteo', (tester) async {
      final days = const [1, 2, 3, 4, 5];
      final laborables = laborableDatesInRange(monthStart, today, days);
      final missed = laborables.first;
      final attended = laborables.where((d) => d != missed).toList();

      await pumpEmployeeReportsInShell(
        tester,
        size: const Size(360, 640),
        attendances: attended.map(attendanceOn).toList(),
        incidences: [justifiedOn(missed)],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: monthStart),
      );

      expect(tester.takeException(), isNull);
      expectCardValue(tester, 'Ausencias injustificadas', '0');
      expectCardValue(tester, 'Justificativos', '1');
    });

    testWidgets('la alta a mitad de mes limita los días contables', (tester) async {
      final days = const [1, 2, 3, 4, 5];
      await pumpEmployeeReportsInShell(
        tester,
        size: const Size(360, 640),
        attendances: [],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: today),
      );

      final expected = isLaborable(today, days) ? 1 : 0;
      expect(tester.takeException(), isNull);
      expectCardValue(tester, 'Ausencias injustificadas', '$expected');
    });

    testWidgets('respeta los días laborables configurados de la empresa', (tester) async {
      final days = const [1, 2, 3, 4, 5, 6];
      await pumpEmployeeReportsInShell(
        tester,
        size: const Size(360, 640),
        attendances: [],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: monthStart),
      );

      final expected = countLaborableDays(monthStart, today, days);
      expect(tester.takeException(), isNull);
      expectCardValue(tester, 'Ausencias injustificadas', '$expected');
    });
  });

  group('INC-2 — contratos nuevos del ajuste', () {
    testWidgets('justificativo rechazado NO resta ausencias', (tester) async {
      final days = const [1, 2, 3, 4, 5];
      final laborables = laborableDatesInRange(monthStart, today, days);
      final missed = laborables.first;
      final attended = laborables.where((d) => d != missed).toList();

      await pumpEmployeeReportsInShell(
        tester,
        size: const Size(360, 640),
        attendances: attended.map(attendanceOn).toList(),
        incidences: [justifiedOn(missed, estado: IncidenceEstado.rechazado)],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: monthStart),
      );

      expect(tester.takeException(), isNull);
      expectCardValue(tester, 'Ausencias injustificadas', '1');
      expectCardValue(tester, 'Justificativos', '0');
    });

    testWidgets('mes futuro seleccionado da 0 ausencias', (tester) async {
      if (now.month >= 12) return; // no hay mes futuro seleccionable
      final days = const [1, 2, 3, 4, 5];
      await pumpEmployeeReportsInShell(
        tester,
        size: const Size(360, 640),
        attendances: [],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: monthStart),
      );

      const monthNames = [
        'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
        'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
      ];
      await tester.tap(find.text(monthNames[now.month - 1]).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Diciembre').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expectCardValue(tester, 'Ausencias injustificadas', '0');
    });

    testWidgets('jornada activa cuenta como presente (D-4)', (tester) async {
      final days = const [1, 2, 3, 4, 5];
      final laborables = laborableDatesInRange(monthStart, today, days);
      if (laborables.isEmpty) return; // ventana sin días laborables: D-4 no aplica
      final activeDay = laborables.first;

      await pumpEmployeeReportsInShell(
        tester,
        size: const Size(360, 640),
        attendances: [activeAttendanceOn(activeDay)],
        company: buildCompany(days: days),
        currentUser: buildEmployeeUser(createdAt: monthStart),
      );

      expect(tester.takeException(), isNull);
      // D-4: el día con jornada activa es presente; los demás días laborables
      // de la ventana (desde el alta) quedan como ausencias injustificadas.
      final expected = countLaborableDays(monthStart, today, days) - 1;
      expectCardValue(tester, 'Ausencias injustificadas', '$expected');
    });
  });
}