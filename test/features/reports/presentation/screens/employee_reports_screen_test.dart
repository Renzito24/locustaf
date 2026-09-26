import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/services/report_exporter.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:app_locustaf/features/authentication/presentation/providers/auth_provider.dart';
import 'package:app_locustaf/features/reports/presentation/providers/reports_provider.dart';
import 'package:app_locustaf/features/reports/presentation/screens/employee_reports_screen.dart';
import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';
import 'package:app_locustaf/features/workplaces/presentation/providers/workplace_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regresión de la empresa de Reportes del empleado (Ronda 3A — B5).
///
/// La pantalla ya no muestra métricas personales ni historial: solo filtro por
/// mes/año y exportación a PDF/Excel de las jornadas completadas del período.
/// Se prueba el estado vacío, el conteo del período, la interacción con el
/// dropdown de mes y las tres ramas de la exportación (éxito/cancelación/error)
/// con un exportador falso, además de la regresión de overflow en pantallas
/// chicas que antes reportó el usuario.
class _FakeReportExporter extends ReportExporter {
  _FakeReportExporter({
    required this.excelOutcome,
    required this.pdfOutcome,
    this.excelError = false,
    this.pdfError = false,
  });

  final bool excelOutcome;
  final bool pdfOutcome;
  final bool excelError;
  final bool pdfError;

  @override
  Future<bool> exportExcel(
    List<AttendanceReportRow> rows, {
    required String fileName,
  }) async {
    if (excelError) throw StateError('falla xlsx');
    return excelOutcome;
  }

  @override
  Future<bool> exportPdf(
    List<AttendanceReportRow> rows, {
    required String fileName,
  }) async {
    if (pdfError) throw StateError('falla pdf');
    return pdfOutcome;
  }
}

void main() {
  const months = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];
  const monthsLower = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  final now = DateTime.now();
  final todayIso =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final user = UserModel(
    id: 'u1',
    nombre: 'Juan',
    apellido: 'Pérez',
    email: 'juan@test.com',
    dni: '33445566',
    rol: UserRole.employee,
    companyId: 'c1',
    createdAt: DateTime(now.year, 1, 1),
  );

  final workplace = WorkplaceModel(
    id: 'w1',
    nombre: 'Sucursal Central',
    direccion: 'Av. Siempre Viva 123',
    latitud: -34.5,
    longitud: -58.6,
    radio: 200,
    isActive: true,
    createdAt: DateTime(now.year, 1, 1),
  );

  AttendanceModel attendanceIn({required DateTime time}) {
    return AttendanceModel(
      id: 'a-${time.month}-${time.day}',
      userId: 'u1',
      checkInTime: time,
      checkOutTime: time.add(const Duration(hours: 8)),
      durationMinutes: 480,
      date: todayIso,
      status: AttendanceStatus.completed,
      workplaceId: 'w1',
      companyId: 'c1',
    );
  }

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(800, 1200),
    List<AttendanceModel>? attendances,
    ReportExporter? exporter,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue('u1'),
          userRoleProvider.overrideWithValue(UserRole.employee),
          attendancesByUserProvider('u1')
              .overrideWith((ref) => Stream.value(attendances ?? <AttendanceModel>[])),
          currentAppUserProvider.overrideWith((ref) => Stream.value(user)),
          activeWorkplacesProvider
              .overrideWith((ref) => AsyncValue.data([workplace])),
          if (exporter != null)
            reportExporterProvider.overrideWithValue(exporter),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(
                    padding: mq.padding.copyWith(top: 24, bottom: 24),
                    viewPadding: mq.viewPadding.copyWith(top: 24, bottom: 24),
                    textScaler: const TextScaler.linear(1.3),
                  ),
                  child: const EmployeeReportsScreen(),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapExportButton(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump();
  }

  Future<void> selectMonth(WidgetTester tester, String label) async {
    await tester.tap(find.text(months[now.month - 1]).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  group('Reportes del empleado — regresión de overflow', () {
    testWidgets('pantalla angosta (360x640, textScale 1.3) sin BOTTOM OVERFLOWED', (tester) async {
      await pumpScreen(
        tester,
        size: const Size(360, 640),
        attendances: [attendanceIn(time: now)],
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Mes'), findsOneWidget);
      expect(find.text('Año'), findsOneWidget);
      expect(
        find.text('Reporte de asistencia de ${monthsLower[now.month - 1]} de ${now.year}'),
        findsOneWidget,
      );
    });

    testWidgets('pantalla muy baja (360x568) sin overflow', (tester) async {
      await pumpScreen(
        tester,
        size: const Size(360, 568),
        attendances: [attendanceIn(time: now)],
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Excel'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
    });
  });

  group('Reportes del empleado — exportación', () {
    testWidgets('Excel guardado correctamente muestra éxito', (tester) async {
      await pumpScreen(
        tester,
        attendances: [attendanceIn(time: now)],
        exporter: _FakeReportExporter(excelOutcome: true, pdfOutcome: true),
      );

      expect(find.text('1 jornada(s) completadas.'), findsOneWidget);

      await tapExportButton(tester, 'Excel');

      expect(find.text('Reporte Excel exportado correctamente'), findsOneWidget);
      expect(
        find.text('Descarga cancelada. No se generó ningún archivo.'),
        findsNothing,
      );
      expect(find.textContaining('Error al exportar Excel'), findsNothing);
    });

    testWidgets('Excel cancelado informa que no se generó ningún archivo', (tester) async {
      await pumpScreen(
        tester,
        attendances: [attendanceIn(time: now)],
        exporter: _FakeReportExporter(excelOutcome: false, pdfOutcome: true),
      );

      await tapExportButton(tester, 'Excel');

      expect(
        find.text('Descarga cancelada. No se generó ningún archivo.'),
        findsOneWidget,
      );
      expect(find.text('Reporte Excel exportado correctamente'), findsNothing);
    });

    testWidgets('error real al exportar Excel muestra error y nunca éxito', (tester) async {
      await pumpScreen(
        tester,
        attendances: [attendanceIn(time: now)],
        exporter: _FakeReportExporter(
          excelOutcome: false,
          pdfOutcome: true,
          excelError: true,
        ),
      );

      await tapExportButton(tester, 'Excel');

      expect(find.textContaining('Error al exportar Excel'), findsOneWidget);
      expect(find.text('Reporte Excel exportado correctamente'), findsNothing);
    });

    testWidgets('PDF guardado correctamente muestra éxito', (tester) async {
      await pumpScreen(
        tester,
        attendances: [attendanceIn(time: now)],
        exporter: _FakeReportExporter(excelOutcome: true, pdfOutcome: true),
      );

      await tapExportButton(tester, 'PDF');

      expect(find.text('Reporte PDF exportado correctamente'), findsOneWidget);
      expect(
        find.text('Descarga cancelada. No se generó ningún archivo.'),
        findsNothing,
      );
    });

    testWidgets('PDF cancelado informa que no se generó ningún archivo', (tester) async {
      await pumpScreen(
        tester,
        attendances: [attendanceIn(time: now)],
        exporter: _FakeReportExporter(excelOutcome: true, pdfOutcome: false),
      );

      await tapExportButton(tester, 'PDF');

      expect(
        find.text('Descarga cancelada. No se generó ningún archivo.'),
        findsOneWidget,
      );
      expect(find.text('Reporte PDF exportado correctamente'), findsNothing);
      expect(find.textContaining('Error al exportar PDF'), findsNothing);
    });

    testWidgets('error real al exportar PDF muestra error y nunca éxito', (tester) async {
      await pumpScreen(
        tester,
        attendances: [attendanceIn(time: now)],
        exporter: _FakeReportExporter(
          excelOutcome: true,
          pdfOutcome: false,
          pdfError: true,
        ),
      );

      await tapExportButton(tester, 'PDF');

      expect(find.textContaining('Error al exportar PDF'), findsOneWidget);
      expect(find.text('Reporte PDF exportado correctamente'), findsNothing);
    });
  });

  group('Reportes del empleado — período sin registros', () {
    testWidgets('sin asistencias: estado vacío y botones deshabilitados', (tester) async {
      await pumpScreen(
        tester,
        attendances: [],
        exporter: _FakeReportExporter(excelOutcome: true, pdfOutcome: true),
      );

      expect(find.text('Sin registros para el período seleccionado.'), findsOneWidget);
      expect(
        find.text('No se pueden exportar reportes si no hay asistencias completadas.'),
        findsOneWidget,
      );

      final excelBtn = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('Excel'), matching: find.byType(OutlinedButton)),
      );
      final pdfBtn = tester.widget<OutlinedButton>(
        find.ancestor(of: find.text('PDF'), matching: find.byType(OutlinedButton)),
      );
      expect(excelBtn.onPressed, isNull);
      expect(pdfBtn.onPressed, isNull);
    });

    testWidgets('cambiar de mes descarta las asistencias de otro período', (tester) async {
      final target = now.month == 1 ? 'Febrero' : 'Enero';
      await pumpScreen(
        tester,
        attendances: [attendanceIn(time: now)],
      );

      await selectMonth(tester, target);

      expect(find.text('Sin registros para el período seleccionado.'), findsOneWidget);
      expect(find.text('1 jornada(s) completadas.'), findsNothing);
    });
  });
}