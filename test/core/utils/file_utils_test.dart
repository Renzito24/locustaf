import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/utils/file_utils.dart';

void main() {
  group('FileUtils.sanitizeFileName', () {
    test('conserva nombre simple', () {
      expect(FileUtils.sanitizeFileName('certificado.pdf'), 'certificado.pdf');
    });

    test('reemplaza caracteres inválidos por guion bajo', () {
      expect(
        FileUtils.sanitizeFileName('mi certificado (1).pdf'),
        'mi_certificado__1_.pdf',
      );
    });

    test('quita rutas de directorio', () {
      expect(
        FileUtils.sanitizeFileName(r'C:\Users\juan\docs\archivo.pdf'),
        'archivo.pdf',
      );
      expect(
        FileUtils.sanitizeFileName('docs/archivo.pdf'),
        'archivo.pdf',
      );
    });

    test('reemplaza caracteres especiales', () {
      expect(
        FileUtils.sanitizeFileName('informe#2026@final.pdf'),
        'informe_2026_final.pdf',
      );
    });

    test('devuelve "archivo" si el nombre queda vacío', () {
      expect(FileUtils.sanitizeFileName('///'), 'archivo');
    });
  });

  group('FileUtils.mimeTypeFromExtension', () {
    test('pdf', () {
      expect(FileUtils.mimeTypeFromExtension('pdf'), 'application/pdf');
      expect(FileUtils.mimeTypeFromExtension('PDF'), 'application/pdf');
    });

    test('jpg y jpeg', () {
      expect(FileUtils.mimeTypeFromExtension('jpg'), 'image/jpeg');
      expect(FileUtils.mimeTypeFromExtension('jpeg'), 'image/jpeg');
    });

    test('png', () {
      expect(FileUtils.mimeTypeFromExtension('png'), 'image/png');
    });

    test('extensión desconocida devuelve null', () {
      expect(FileUtils.mimeTypeFromExtension('exe'), isNull);
      expect(FileUtils.mimeTypeFromExtension(null), isNull);
    });
  });
}
