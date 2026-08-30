import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/core/utils/string_utils.dart';

void main() {
  group('StringUtils.safePrefix', () {
    test('id largo devuelve el prefijo', () {
      expect(StringUtils.safePrefix('abcdefghij', 6), 'abcdef');
    });

    test('id con longitud exacta devuelve el string completo', () {
      expect(StringUtils.safePrefix('abcdef', 6), 'abcdef');
    });

    test('id más corto devuelve el string completo sin RangeError', () {
      expect(StringUtils.safePrefix('emp-1', 6), 'emp-1');
      expect(StringUtils.safePrefix('abc', 6), 'abc');
    });

    test('id vacío devuelve string vacío sin RangeError', () {
      expect(StringUtils.safePrefix('', 6), '');
    });
  });
}