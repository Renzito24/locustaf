import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../features/reports/presentation/providers/reports_provider.dart';

/// Clase encargada de formatear y construir los bytes para los reportes de asistencia.
class AttendanceReportBuilder {
  /// Genera los bytes del `.xlsx`; separado del guardado para poder testear la
  /// construcción del archivo sin depender de la plataforma.
  static Uint8List? buildExcelBytes(List<AttendanceReportRow> rows) {
    final excelFile = Excel.createExcel();

    excelFile.appendRow('Sheet1', [
      TextCellValue('Empleado'),
      TextCellValue('Lugar de trabajo'),
      TextCellValue('Entrada'),
      TextCellValue('Salida'),
      TextCellValue('Duración (min)'),
    ]);

    for (final row in rows) {
      excelFile.appendRow('Sheet1', [
        TextCellValue(row.employeeName),
        TextCellValue(row.workplaceName ?? '-'),
        TextCellValue(_formatDateTime(row.checkInTime)),
        TextCellValue(
          row.checkOutTime != null ? _formatDateTime(row.checkOutTime!) : '',
        ),
        TextCellValue(row.durationMinutes?.toString() ?? ''),
      ]);
    }

    final bytes = excelFile.encode();
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  /// Genera los bytes del `.pdf`; separado del guardado para poder testear la
  /// construcción del archivo sin depender de la plataforma.
  ///
  /// Fase C — C6: se pagina por lotes fijos en vez de renderizar la tabla
  /// completa con `MultiPage`. Con volúmenes grandes (p.ej. 10k filas) la
  /// tabla completa re-maquetaba todas sus filas por página (O(páginas ×
  /// filas)) y terminaba en ~4 minutos o reventando con
  /// `TooManyPagesException`. Cada página ahora es un pequeño `pw.Page` con
  /// hasta 40 filas: 10k filas salen en ~1-2s (~250 páginas).
  static Future<Uint8List> buildPdfBytes(
    List<AttendanceReportRow> rows,
  ) async {
    const double pageMargin = 32;
    const int rowsPerPage = 40;

    final int totalPages = rows.isEmpty
        ? 1
        : (rows.length + rowsPerPage - 1) ~/ rowsPerPage;

    final doc = pw.Document();

    List<List<String>> mapChunk(int start, int end) {
      return rows.sublist(start, end).map((row) {
        return [
          row.employeeName,
          row.workplaceName ?? '-',
          _formatDateTime(row.checkInTime),
          row.checkOutTime != null ? _formatDateTime(row.checkOutTime!) : '-',
          row.durationMinutes?.toString() ?? '-',
        ];
      }).toList();
    }

    pw.Widget buildHeader() {
      return pw.Column(
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
      );
    }

    pw.Widget buildFooter(int pageIndex) {
      return pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Página $pageIndex de $totalPages',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
        ),
      );
    }

    pw.Widget buildTable(List<List<String>> data) {
      return pw.TableHelper.fromTextArray(
        headers: [
          'Empleado',
          'Lugar de trabajo',
          'Entrada',
          'Salida',
          'Duración (min)',
        ],
        data: data,
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
      );
    }

    void addChunk(int start, int end, int pageIndex) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(pageMargin),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              buildHeader(),
              buildTable(mapChunk(start, end)),
              pw.SizedBox(height: 8),
              buildFooter(pageIndex),
            ],
          ),
        ),
      );
    }

    if (rows.isEmpty) {
      addChunk(0, 0, 1);
    } else {
      var pageIndex = 1;
      for (var start = 0; start < rows.length; start += rowsPerPage) {
        final end = (start + rowsPerPage) > rows.length
            ? rows.length
            : start + rowsPerPage;
        addChunk(start, end, pageIndex);
        pageIndex++;
      }
    }

    return doc.save();
  }

  static String _formatDateTime(DateTime dt) {
    final date =
        '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
