/// Determina cómo se previsualiza un adjunto de documentación médica.
///
/// El tipo real del archivo NO se guarda en Firestore: se persisten
/// `archivoNombre` y `mimeType`. Para los adjuntos subidos por la app,
/// `mimeType` viene de `FileUtils.mimeTypeFromExtension`; para documentos
/// creados antes de que se persistiera el MIME, se deduce por la extensión
/// de `archivoNombre`. Esta función combina ambas fuentes (MIME primero).
enum FileAttachmentKind { image, pdf, other }

FileAttachmentKind fileAttachmentKind({String? mimeType, String? fileName}) {
  final mime = mimeType?.toLowerCase() ?? '';
  if (mime.startsWith('image/')) return FileAttachmentKind.image;
  if (mime == 'application/pdf') return FileAttachmentKind.pdf;

  final name = fileName?.toLowerCase() ?? '';
  if (name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.png') ||
      name.endsWith('.gif') ||
      name.endsWith('.webp') ||
      name.endsWith('.bmp')) {
    return FileAttachmentKind.image;
  }
  if (name.endsWith('.pdf')) return FileAttachmentKind.pdf;
  return FileAttachmentKind.other;
}
