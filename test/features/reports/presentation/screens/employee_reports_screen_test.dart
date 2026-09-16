import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/router/app_routes.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
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

  Future<void> pumpEmployeeReportsInShell(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
          attendancesByUserProvider('u1').overrideWith((ref) => Stream.value([attendance])),
          incidencesStreamProvider.overrideWith((ref) => Stream.value(<IncidenceModel>[])),
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
}