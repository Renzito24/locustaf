import 'package:app_locustaf/core/services/report_exporter.dart';
import 'package:app_locustaf/features/reports/presentation/providers/reports_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test de performance (Fase C — C6).
///
/// Objetivo de la auditoría: «Load test reportes con 10k+ records • verificar
/// tiempo de respuesta • <3s para reportes complejos». Se ejercita la
/// generación real de los reportes (Excel y PDF) con 10.000 filas, que es lo
/// que el usuario ve como «reporte complejo». Los umbrales son generosos para
/// no fallar en false-positive en CI, pero detectan regresiones graves
/// (re-computación cuadrática, renderizado por fila excesivo, etc.).
void main() {
  const int totalRows = 10000;

  Future<List<AttendanceReportRow>> buildRows() async {
    final base = DateTime(2026, 9, 1, 8, 0);
    return List.generate(totalRows, (i) {
      return AttendanceReportRow(
        employeeName: 'Empleado ${(i % 50).toString().padLeft(2, '0')}',
        workplaceName: 'Sucursal ${(i % 5) + 1}',
        checkInTime: base.add(Duration(minutes: i * 5)),
        checkOutTime: base.add(Duration(minutes: i * 5 + 480)),
        durationMinutes: 480,
      );
    });
  }

  test('genera el .xlsx de 10.000 filas en menos de 3 segundos', () async {
    final rows = await buildRows();

    final clock = Stopwatch()..start();
    final bytes = ReportExporter.buildAttendanceExcelBytes(rows);
    clock.stop();

    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(100000), reason: 'el archivo debe contener las filas');
    expect(
      clock.elapsed,
      lessThan(const Duration(seconds: 3)),
      reason: 'reporte complejo (10k filas) debe generarse en menos de 3s. Tomó '
          '${clock.elapsedMilliseconds}ms.',
    );
    // ignore: avoid_print
    print('[perf] Excel 10k filas: ${clock.elapsedMilliseconds}ms');
  });

  test('genera el PDF de 10.000 filas sin romperse y en menos de 10 segundos', () async {
    final rows = await buildRows();

    final clock = Stopwatch()..start();
    final bytes = await ReportExporter.buildAttendancePdfBytes(rows);
    clock.stop();

    expect(bytes.length, greaterThan(100000), reason: 'el archivo debe contener las filas');
    expect(
      clock.elapsed,
      lessThan(const Duration(seconds: 10)),
      reason: 'el PDF multipágina (10k filas) no debe degradarse ni romperse '
          'por límite de páginas: la paginación por lotes de la Fase C (C6) '
          'lleva ~600ms contra ~4min del enfoque MultiPage. Tomó '
          '${clock.elapsedMilliseconds}ms.',
    );
    // ignore: avoid_print
    print('[perf] PDF 10k filas: ${clock.elapsedMilliseconds}ms');
  });
}