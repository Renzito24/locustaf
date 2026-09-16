import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/utils/date_formatter.dart';

void main() {
  group('tryParseIsoDate', () {
    test('parsea una fecha ISO válida', () {
      final dt = tryParseIsoDate('2026-09-15');
      expect(dt, isNotNull);
      expect(dt!.year, 2026);
      expect(dt.month, 9);
      expect(dt.day, 15);
    });

    test('null / vacío / espacios → null', () {
      expect(tryParseIsoDate(null), isNull);
      expect(tryParseIsoDate(''), isNull);
      expect(tryParseIsoDate('   '), isNull);
    });

    test('valores inválidos → null sin lanzar (protección ante crashes)', () {
      expect(tryParseIsoDate('no-es-una-fecha'), isNull);
      expect(tryParseIsoDate('15/09/2026'), isNull);
      expect(tryParseIsoDate('2026-13-45'), isNull);
      expect(tryParseIsoDate('2026-02-30'), isNull);
    });
  });

  group('formatIsoDate', () {
    test('usar padding de ceros en mes y día', () {
      expect(formatIsoDate(DateTime(2026, 9, 5)), '2026-09-05');
      expect(formatIsoDate(DateTime(2026, 11, 25)), '2026-11-25');
      expect(formatIsoDate(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });

  group('formatUserDate', () {
    test('formato amigable dd/MM/yyyy', () {
      expect(formatUserDate(DateTime(2026, 9, 5)), '05/09/2026');
      expect(formatUserDate(DateTime(2026, 12, 31)), '31/12/2026');
      expect(formatUserDate(DateTime(2026, 1, 1)), '01/01/2026');
    });
  });

  group('roundtrip filtro de reportes', () {
    test('formatIsoDate(tryParseIsoDate(s)) == s para fechas válidas', () {
      const iso = '2026-09-15';
      expect(formatIsoDate(tryParseIsoDate(iso)!), iso);
    });
  });
}