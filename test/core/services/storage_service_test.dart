import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/services/storage_service.dart';

void main() {
  group('StorageService.mobileOutcome', () {
    test('path null significa que el usuario canceló el diálogo', () {
      expect(StorageService.mobileOutcome(null), DownloadOutcome.cancelled);
    });

    test('path no nulo significa que el sistema SAF escribió el archivo', () {
      expect(
        StorageService.mobileOutcome(
          '/storage/emulated/0/Download/recibo_2026-10.pdf',
        ),
        DownloadOutcome.downloaded,
      );
    });
  });

  group('DownloadOutcome', () {
    test('dos estados: descargado y cancelado', () {
      expect(DownloadOutcome.values, [
        DownloadOutcome.downloaded,
        DownloadOutcome.cancelled,
      ]);
    });
  });
}
