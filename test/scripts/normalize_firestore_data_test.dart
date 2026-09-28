import 'package:flutter_test/flutter_test.dart';
import '../../scripts/normalize_firestore_data.dart';

void main() {
  group('Normalizador de Company', () {
    test('convierte toleranciaCheckIn de String a int', () {
      final input = {
        'nombreComercial': 'Test S.A.',
        'toleranciaCheckIn': '30',
      };

      final updates = normalizeCompanyFields(input);
      expect(updates, isNotNull);
      expect(updates!['toleranciaCheckIn'], 30);
      expect(updates['toleranciaCheckIn'], isA<int>());
    });

    test('convierte diasLaborables con elementos String a List<int>', () {
      final input = {
        'nombreComercial': 'Test S.A.',
        'diasLaborables': ['1', 2, '3', 4, '5'],
      };

      final updates = normalizeCompanyFields(input);
      expect(updates, isNotNull);
      expect(updates!['diasLaborables'], [1, 2, 3, 4, 5]);
      expect(updates['diasLaborables'], everyElement(isA<int>()));
    });

    test('no produce cambios si la empresa ya tiene tipos correctos', () {
      final input = {
        'nombreComercial': 'Test S.A.',
        'toleranciaCheckIn': 15,
        'diasLaborables': [1, 2, 3, 4, 5],
      };

      final updates = normalizeCompanyFields(input);
      expect(updates, isNull);
    });
  });

  group('Normalizador de Workplace', () {
    test('convierte toleranciaMinutos, radio, latitud y longitud de String a numérico', () {
      final input = {
        'nombre': 'Sucursal Norte',
        'toleranciaMinutos': '20',
        'radio': '150.5',
        'latitud': '-34.6037',
        'longitud': '-58.3816',
      };

      final updates = normalizeWorkplaceFields(input);
      expect(updates, isNotNull);
      expect(updates!['toleranciaMinutos'], 20);
      expect(updates['toleranciaMinutos'], isA<int>());
      expect(updates['radio'], 150.5);
      expect(updates['radio'], isA<double>());
      expect(updates['latitud'], -34.6037);
      expect(updates['latitud'], isA<double>());
      expect(updates['longitud'], -58.3816);
      expect(updates['longitud'], isA<double>());
    });

    test('no produce cambios si el lugar de trabajo ya tiene tipos correctos', () {
      final input = {
        'nombre': 'Sucursal Central',
        'toleranciaMinutos': 15,
        'radio': 100.0,
        'latitud': -34.6037,
        'longitud': -58.3816,
      };

      final updates = normalizeWorkplaceFields(input);
      expect(updates, isNull);
    });
  });
}
