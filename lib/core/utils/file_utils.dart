/// Utilidades para el manejo seguro de archivos subidos.
class FileUtils {
  FileUtils._();

  /// Sanea un nombre de archivo para usarlo en un path de Storage:
  /// conserva solo caracteres alfanuméricos, punto, guion y guion bajo.
  static String sanitizeFileName(String name) {
    final base = name.split(RegExp(r'[/\\]')).last;
    final cleaned = base.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return cleaned.isEmpty ? 'archivo' : cleaned;
  }

  /// Devuelve el MIME type a partir de la extensión del archivo.
  /// Devuelve null si la extensión no es reconocida.
  static String? mimeTypeFromExtension(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return null;
    }
  }
}
