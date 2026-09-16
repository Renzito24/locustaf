import 'package:flutter_test/flutter_test.dart';

import 'package:app_locustaf/features/medical_documents/domain/file_attachment_kind.dart';

/// Fase B — Corrección: el tipo de archivo del adjunto médico no se persiste
/// como campo propio (solo `archivoNombre` con extensión y `mimeType` cuando
/// la app lo subió), por lo que la previsualización depende de inferirlo bien.
void main() {
  group('fileAttachmentKind', () {
    test('imagen por MIME (image/jpeg, image/png...)', () {
      expect(
        fileAttachmentKind(mimeType: 'image/jpeg', fileName: 'x'),
        FileAttachmentKind.image,
      );
      expect(
        fileAttachmentKind(mimeType: 'image/png', fileName: 'x'),
        FileAttachmentKind.image,
      );
    });

    test('PDF por MIME application/pdf', () {
      expect(
        fileAttachmentKind(mimeType: 'application/pdf', fileName: 'x'),
        FileAttachmentKind.pdf,
      );
    });

    test('imagen por extensión cuando no hay MIME (docs previos)', () {
      expect(
        fileAttachmentKind(fileName: 'certificado.jpg'),
        FileAttachmentKind.image,
      );
      expect(
        fileAttachmentKind(fileName: 'certificado.jpeg'),
        FileAttachmentKind.image,
      );
      expect(
        fileAttachmentKind(fileName: 'foto.PNG'),
        FileAttachmentKind.image,
      );
    });

    test('PDF por extensión cuando no hay MIME (docs previos)', () {
      expect(
        fileAttachmentKind(fileName: 'certificado.pdf'),
        FileAttachmentKind.pdf,
      );
      expect(
        fileAttachmentKind(fileName: 'CONSTANCIA.Pdf'),
        FileAttachmentKind.pdf,
      );
    });

    test('otro tipo (extensión o MIME desconocidos) → other', () {
      expect(
        fileAttachmentKind(mimeType: 'text/plain', fileName: 'recibo.txt'),
        FileAttachmentKind.other,
      );
      expect(
        fileAttachmentKind(fileName: 'archivo.sin.ext'),
        FileAttachmentKind.other,
      );
      expect(fileAttachmentKind(), FileAttachmentKind.other);
    });
  });
}
