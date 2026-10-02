import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../features/reports/presentation/providers/reports_provider.dart';
import 'attendance_report_builder.dart';
import 'file_exists.dart';

/// Resultado interpretado de [FilePicker.platform.saveFile] en móviles:
/// el sistema SAF escribió el archivo en la ubicación elegida por el usuario
/// (path != null) o el usuario canceló el diálogo (null).
enum MobileSaveOutcome { saved, cancelled }

/// Provider del exportador de reportes.
///
/// ÚNICA vía por la que las pantallas obtienen un [ReportExporter]; en tests se
/// sobrescribe para simular el resultado del guardado sin tocar la plataforma.
final reportExporterProvider = Provider<ReportExporter>((ref) {
  return const ReportExporter();
});

/// Servicio de exportación de reportes.
///
/// Genera archivos Excel (`.xlsx`, AUI-03) y PDF a partir de las filas del
/// reporte de asistencia y los guarda en una ubicación visible para el usuario.
///
/// Fase B — Corrección: en Android `FileSaver.saveFile` escribe en un
/// directorio privado de la app (invisible) y responde éxito siempre, y
/// `FileSaver.saveAs` traga los errores de escritura del SAF y resuelve la
/// ruta a una copia privada (`filesDir/userfiles` en Android 10+), por eso
/// daba "éxito falso sin archivo visible". En móviles se usa
/// `FilePicker.saveFile` (ACTION_CREATE_DOCUMENT / UIDocumentPicker): el
/// usuario elige el destino, el plugin escribe los bytes vía SAF con
/// `flush()+close()` y devuelve `null` si cancela o lanza un error real si la
/// escritura falla. En web/desktop se mantiene `FileSaver` con verificación
/// real del archivo en disco.
class ReportExporter {
  const ReportExporter();

  // Sentinel que el plugin file_saver devuelve cuando NO pudo completar un
  // guardado sin lanzar excepción ni devolver null.
  static const String _webDownloadSentinel = 'Downloads';
  static const String _noSaveSentinel = 'Something went wrong';

  /// Semántica del resultado del guardado móvil (función pura testeable).
  ///
  /// En Android/iOS, `FilePicker.saveFile` con [Uint8List] escribe los bytes
  /// en la ubicación elegida por el usuario y SOLO devuelve `null` cuando el
  /// usuario cancela; cualquier fallo de escritura se propaga como excepción.
  /// Por eso path != null implica archivo realmente escrito por el sistema.
  static MobileSaveOutcome mobileOutcome(String? path) {
    return path == null ? MobileSaveOutcome.cancelled : MobileSaveOutcome.saved;
  }

  /// Exporta a `.xlsx`. Devuelve `true` si el archivo quedó realmente guardado,
  /// `false` si el usuario canceló el diálogo de guardado. Lanza si hubo error.
  Future<bool> exportExcel(
    List<AttendanceReportRow> rows, {
    required String fileName,
  }) async {
    final bytes = AttendanceReportBuilder.buildExcelBytes(rows);
    if (bytes == null) {
      throw StateError('No se pudo generar el archivo .xlsx');
    }

    return _persistFile(
      bytes: bytes,
      fileName: fileName,
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }

  /// Exporta a `.pdf`. Misma semántica de retorno que [exportExcel].
  Future<bool> exportPdf(
    List<AttendanceReportRow> rows, {
    required String fileName,
  }) async {
    final bytes = await AttendanceReportBuilder.buildPdfBytes(rows);

    if (kIsWeb) {
      // En web, printing dispara la descarga visual directamente.
      await Printing.sharePdf(bytes: bytes, filename: fileName);
      return true;
    }

    return _persistFile(
      bytes: bytes,
      fileName: fileName,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  Future<bool> _persistFile({
    required Uint8List bytes,
    required String fileName,
    required String ext,
    required MimeType mimeType,
  }) async {
    if (kIsWeb) {
      // Web: la descarga la dispara el navegador. Un guardado exitoso devuelve
      // exactamente 'Downloads'; si el plugin no pudo, responde con su sentinel
      // de error y eso se reporta como error (nunca como éxito falso).
      final result = await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: ext,
        mimeType: mimeType,
      );
      if (result != _webDownloadSentinel) {
        throw StateError('No se pudo completar la descarga del archivo.');
      }
      return true;
    }

    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (isMobile) {
      // Móviles: FilePicker.saveFile abre el selector de documentos del
      // sistema (ACTION_CREATE_DOCUMENT / UIDocumentPicker), el usuario elige
      // el destino y el plugin escribe los bytes en esa ubicación vía
      // ContentResolver.openOutputStream + flush + close. Devuelve null si el
      // usuario cancela y lanza un error real si la escritura falla; nunca
      // reporta éxito sin haber escrito el archivo (a diferencia de
      // FileSaver.saveAs en Android).
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar reporte',
        fileName: '$fileName.$ext',
        type: FileType.custom,
        allowedExtensions: [ext],
        bytes: bytes,
      );
      return mobileOutcome(path) == MobileSaveOutcome.saved;
    }

    // Desktop: saveFile abre el diálogo nativo de guardado. En desktop el
    // plugin nunca devuelve null: cancelar el diálogo responde con su sentinel
    // "Something went wrong..." y eso equivale a "no se guardó nada".
    final result = await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: ext,
      mimeType: mimeType,
    );

    if (result.startsWith(_noSaveSentinel)) {
      return false;
    }

    if (!fileExistsOnDisk(result)) {
      // La plataforma dijo "éxito" pero el archivo no está en disco:
      // rechazamos el falso positivo en vez de mostrar "exportado correctamente".
      throw StateError(
        'No se pudo guardar el archivo en la ubicación elegida.',
      );
    }
    return true;
  }

}
