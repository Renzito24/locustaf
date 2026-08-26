import 'dart:convert';

import 'package:file_saver/file_saver.dart';

import '../../../features/reports/presentation/providers/reports_provider.dart';

/// Servicio de exportación de reportes.
///
/// Genera un archivo CSV (compatible con Excel) a partir de las filas del
/// reporte de asistencia y lo descarga en la plataforma actual.
class ReportExporter {
  ReportExporter._();

  static Future<void> exportAttendanceCsv(
    List<AttendanceReportRow> rows, {
    required String fileName,
  }) async {
    final buffer = StringBuffer();

    // Encabezados
    buffer.writeln(
      'Empleado,Lugar de trabajo,Entrada,Salida,Duración (min)',
    );

    // Filas
    for (final row in rows) {
      final name = _escapeCsv(row.employeeName);
      final workplace = _escapeCsv(row.workplaceName ?? '');
      final checkIn = _formatDateTime(row.checkInTime);
      final checkOut = row.checkOutTime != null
          ? _formatDateTime(row.checkOutTime!)
          : '';
      final duration = row.durationMinutes?.toString() ?? '';
      buffer.writeln('$name,$workplace,$checkIn,$checkOut,$duration');
    }

    final bytes = utf8.encode(buffer.toString());

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: 'csv',
      mimeType: MimeType.csv,
    );
  }

  static String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String _formatDateTime(DateTime dt) {
    final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
