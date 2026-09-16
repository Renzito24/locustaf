import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/core/models/user_model.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/core/services/report_exporter.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/companies/presentation/providers/company_providers.dart';
import 'package:app_locustaf/features/reports/presentation/providers/reports_provider.dart';
import 'package:app_locustaf/features/reports/presentation/screens/reports_screen.dart';
import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';
import 'package:app_locustaf/features/workplaces/presentation/providers/workplace_notifier.dart';

/// Fake del exportador: permite simular éxito, cancelación y error sin tocar
/// la plataforma (Fase B — Corrección).
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
  final now = DateTime.now();
  final todayIso = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  final user = UserModel(
    id: 'u1',
    nombre: 'Juan',
    apellido: 'Pérez',
    email: 'juan@test.com',
    dni: '33445566',
    rol: UserRole.employee,
    companyId: 'c1',
    createdAt: DateTime(2026),
  );

  final workplace = WorkplaceModel(
    id: 'w1',
    nombre: 'Sucursal Central',
    direccion: 'Av. Siempre Viva 123',
    latitud: -34.5,
    longitud: -58.6,
    radio: 200,
    isActive: true,
    createdAt: DateTime(2026),
  );

  final attendance = AttendanceModel(
    id: 'a1',
    userId: 'u1',
    checkInTime: now,
    checkOutTime: now.add(const Duration(hours: 8)),
    durationMinutes: 480,
    date: todayIso,
    status: AttendanceStatus.completed,
    workplaceId: 'w1',
    companyId: 'c1',
  );

  Future<void> pumpScreen(
    WidgetTester tester, {
    ReportExporter? exporter,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          allUsersStreamProvider.overrideWith((ref) => Stream.value([user])),
          allWorkplacesStreamProvider.overrideWith((ref) => Stream.value([workplace])),
          allAttendancesStreamProvider.overrideWith((ref) => Stream.value([attendance])),
          workplacesStreamProvider.overrideWith((ref) => Stream.value([workplace])),
          currentCompanyProvider.overrideWith((ref) => Stream.value(null)),
          if (exporter != null)
            reportExporterProvider.overrideWithValue(exporter),
        ],
        child: const MaterialApp(
          home: Scaffold(body: ReportsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Los botones de exportación viven debajo del pliegue en la pantalla de
  // prueba: los lleva a la vista antes de tocarlos.
  Future<void> tapExportButton(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.pump();
  }

  testWidgets(
    'Fase B-Corrección: exportar Excel con archivo realmente guardado muestra '
    'éxito, no con error ni mensaje de cancelación',
    (tester) async {
      await pumpScreen(
        tester,
        exporter: _FakeReportExporter(excelOutcome: true, pdfOutcome: true),
      );

      await tapExportButton(tester, 'Excel');

      expect(find.text('Reporte Excel exportado correctamente'), findsOneWidget);
      expect(
        find.text('Descarga cancelada. No se generó ningún archivo.'),
        findsNothing,
      );
      expect(find.textContaining('Error al exportar Excel'), findsNothing);
    },
  );

  testWidgets(
    'Fase B-Corrección: exportar Excel cancelado por el usuario no muestra '
    'éxito; informa que no se generó ningún archivo',
    (tester) async {
      await pumpScreen(
        tester,
        exporter: _FakeReportExporter(excelOutcome: false, pdfOutcome: false),
      );

      await tapExportButton(tester, 'Excel');

      expect(
        find.text('Descarga cancelada. No se generó ningún archivo.'),
        findsOneWidget,
      );
      expect(find.text('Reporte Excel exportado correctamente'), findsNothing);
      expect(find.textContaining('Error al exportar Excel'), findsNothing);
    },
  );

  testWidgets(
    'Fase B-Corrección: error real al exportar Excel muestra error y nunca éxito',
    (tester) async {
      await pumpScreen(
        tester,
        exporter: _FakeReportExporter(
          excelOutcome: false,
          pdfOutcome: true,
          excelError: true,
        ),
      );

      await tapExportButton(tester, 'Excel');

      expect(find.textContaining('Error al exportar Excel'), findsOneWidget);
      expect(find.text('Reporte Excel exportado correctamente'), findsNothing);
    },
  );

  testWidgets(
    'Fase B-Corrección: exportar PDF con archivo realmente guardado muestra '
    'éxito, y la cancelación no',
    (tester) async {
      await pumpScreen(
        tester,
        exporter: _FakeReportExporter(excelOutcome: true, pdfOutcome: true),
      );

      await tapExportButton(tester, 'PDF');

      expect(find.text('Reporte PDF exportado correctamente'), findsOneWidget);
      expect(
        find.text('Descarga cancelada. No se generó ningún archivo.'),
        findsNothing,
      );
    },
  );

  testWidgets(
    'Fase B-Corrección: exportar PDF cancelado informa que no se generó archivo',
    (tester) async {
      await pumpScreen(
        tester,
        exporter: _FakeReportExporter(excelOutcome: true, pdfOutcome: false),
      );

      await tapExportButton(tester, 'PDF');

      expect(
        find.text('Descarga cancelada. No se generó ningún archivo.'),
        findsOneWidget,
      );
      expect(find.text('Reporte PDF exportado correctamente'), findsNothing);
      expect(find.textContaining('Error al exportar PDF'), findsNothing);
    },
  );

  testWidgets(
    'Fase B-Corrección: error real al exportar PDF muestra error y nunca éxito',
    (tester) async {
      await pumpScreen(
        tester,
        exporter: _FakeReportExporter(
          excelOutcome: true,
          pdfOutcome: false,
          pdfError: true,
        ),
      );

      await tapExportButton(tester, 'PDF');

      expect(find.textContaining('Error al exportar PDF'), findsOneWidget);
      expect(find.text('Reporte PDF exportado correctamente'), findsNothing);
    },
  );
}