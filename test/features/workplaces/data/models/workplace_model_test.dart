import 'package:app_locustaf/features/workplaces/data/models/workplace_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkplaceModel', () {
    test('fromJson tolera tipos numéricos y Strings numéricos', () {
      final json = {
        'id': 'wp-1',
        'nombre': 'Sucursal Test',
        'direccion': 'Calle Falsa 123',
        'latitud': '-34.6037',
        'longitud': -58.3816,
        'radio': '100',
        'toleranciaMinutos': '15',
        'companyId': 'emp-1',
        'isActive': true,
        'createdAt': '2026-01-01T10:00:00.000Z',
      };

      final model = WorkplaceModel.fromJson(json);

      expect(model.id, 'wp-1');
      expect(model.nombre, 'Sucursal Test');
      expect(model.latitud, -34.6037);
      expect(model.longitud, -58.3816);
      expect(model.radio, 100.0);
      expect(model.toleranciaMinutos, 15);
      expect(model.isActive, isTrue);
    });

    test('fromJson usa valores por defecto cuando los campos son nulos', () {
      final json = {
        'id': 'wp-2',
        'nombre': 'Sucursal Minima',
        'direccion': 'Calle 1',
        'latitud': 0.0,
        'longitud': 0.0,
        'radio': 50.0,
        'companyId': 'emp-1',
        'createdAt': '2026-01-01T10:00:00.000Z',
      };

      final model = WorkplaceModel.fromJson(json);

      expect(model.toleranciaMinutos, 15);
      expect(model.isActive, isTrue);
    });
  });
}
