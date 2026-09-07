import 'package:app_locustaf/core/services/report_exporter.dart';
import 'package:app_locustaf/features/reports/presentation/providers/reports_provider.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String text(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    return value.toString();
  }

  group('ReportExporter.buildAttendanceExcelBytes (AUI-03)', () {
    test('genera un .xlsx con encabezados y una fila completa', () {
      final bytes = ReportExporter.buildAttendanceExcelBytes([
        AttendanceReportRow(
          employeeName: 'María, González',
          workplaceName: 'Sucursal Central',
          checkInTime: DateTime(2026, 9, 7, 8, 0),
          checkOutTime: DateTime(2026, 9, 7, 17, 0),
          durationMinutes: 480,
        ),
      ]);

      expect(bytes, isNotNull);
      final decoded = Excel.decodeBytes(bytes!);
      final sheet = decoded.tables['Sheet1'];
      expect(sheet, isNotNull);
      final rows = sheet!.rows;

      expect(rows.length, 2);
      expect(text(rows[0][0]), 'Empleado');
      expect(text(rows[0][1]), 'Lugar de trabajo');
      expect(text(rows[0][2]), 'Entrada');
      expect(text(rows[0][3]), 'Salida');
      expect(text(rows[0][4]), 'Duración (min)');

      expect(text(rows[1][0]), 'María, González');
      expect(text(rows[1][1]), 'Sucursal Central');
      expect(text(rows[1][2]), '2026-09-07 08:00');
      expect(text(rows[1][3]), '2026-09-07 17:00');
      expect(text(rows[1][4]), '480');
    });

    test('genera celdas vacías cuando no hay salida ni duración', () {
      final bytes = ReportExporter.buildAttendanceExcelBytes([
        AttendanceReportRow(
          employeeName: 'Juan Pérez',
          workplaceName: null,
          checkInTime: DateTime(2026, 9, 7, 9, 0),
          checkOutTime: null,
          durationMinutes: null,
        ),
      ]);

      expect(bytes, isNotNull);
      final decoded = Excel.decodeBytes(bytes!);
      final sheet = decoded.tables['Sheet1'];
      final rows = sheet!.rows;

      expect(rows.length, 2);
      expect(text(rows[1][1]), '');
      expect(text(rows[1][3]), '');
      expect(text(rows[1][4]), '');
    });

    test('con filas vacías genera únicamente los encabezados', () {
      final bytes = ReportExporter.buildAttendanceExcelBytes([]);

      expect(bytes, isNotNull);
      final decoded = Excel.decodeBytes(bytes!);
      final rows = decoded.tables['Sheet1']!.rows;

      expect(rows.length, 1);
      expect(text(rows[0][0]), 'Empleado');
    });
  });
}