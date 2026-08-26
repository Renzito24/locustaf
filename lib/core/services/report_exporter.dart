import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../features/reports/presentation/providers/reports_provider.dart';

/// Servicio de exportación de reportes.
///
/// Genera archivos CSV (compatible con Excel) y PDF a partir de las filas del
/// reporte de asistencia y los descarga en la plataforma actual.
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

  static Future<void> exportAttendancePdf(
    List<AttendanceReportRow> rows, {
    required String fileName,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Reporte de Asistencia',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generado el ${_formatDateTime(DateTime.now())}',
              style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: PdfColors.grey400),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: [
              'Empleado',
              'Lugar de trabajo',
              'Entrada',
              'Salida',
              'Duración (min)',
            ],
            data: rows.map((row) {
              return [
                row.employeeName,
                row.workplaceName ?? '-',
                _formatDateTime(row.checkInTime),
                row.checkOutTime != null
                    ? _formatDateTime(row.checkOutTime!)
                    : '-',
                row.durationMinutes?.toString() ?? '-',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey800,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerRight,
            },
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          ),
        ],
      ),
    );

    final bytes = await doc.save();

    // En web, printing genera la descarga; en desktop/móvil usa FileSaver.
    if (kIsWeb) {
      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } else {
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );
    }
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

