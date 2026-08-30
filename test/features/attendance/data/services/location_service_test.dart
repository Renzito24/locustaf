import 'package:flutter_test/flutter_test.dart';
import 'package:app_locustaf/features/attendance/data/services/location_service.dart';

void main() {
  group('LocationService.calculateDistance (Haversine)', () {
    test('distancia cero para el mismo punto', () {
      final d = LocationService.calculateDistance(-34.6037, -58.3816, -34.6037, -58.3816);
      expect(d, closeTo(0, 0.001));
    });

    test('distancia aproximada Buenos Aires - Córdoba', () {
      // Buenos Aires (-34.6037, -58.3816) a Córdoba (-31.4201, -64.1888).
      final d = LocationService.calculateDistance(-34.6037, -58.3816, -31.4201, -64.1888);
      // ~647 km según Haversine.
      expect(d, closeTo(646700, 10000));
    });

    test('distancia aproximada Buenos Aires - Nueva York', () {
      // Buenos Aires (-34.6037, -58.3816) a Nueva York (40.7128, -74.0060).
      final d = LocationService.calculateDistance(-34.6037, -58.3816, 40.7128, -74.0060);
      // ~8530 km.
      expect(d, closeTo(8530000, 200000));
    });

    test('es simétrica', () {
      final d1 = LocationService.calculateDistance(-34.6, -58.4, -31.4, -64.2);
      final d2 = LocationService.calculateDistance(-31.4, -64.2, -34.6, -58.4);
      expect(d1, closeTo(d2, 0.001));
    });

    test('distancia de ~111 km por grado de latitud', () {
      // Un grado de latitud ≈ 111.19 km.
      final d = LocationService.calculateDistance(0, 0, 1, 0);
      expect(d, closeTo(111190, 500));
    });
  });

  group('LocationService.isWithinRadius', () {
    test('punto dentro del radio', () {
      final inside = LocationService.isWithinRadius(
        userLat: -34.6037,
        userLng: -58.3816,
        workplaceLat: -34.6037,
        workplaceLng: -58.3816,
        radiusMeters: 100,
      );
      expect(inside, isTrue);
    });

    test('punto en el límite exacto del radio', () {
      // ~89m al norte del workplace (dentro de 100m).
      final onEdge = LocationService.isWithinRadius(
        userLat: -34.6029,
        userLng: -58.3816,
        workplaceLat: -34.6037,
        workplaceLng: -58.3816,
        radiusMeters: 100,
      );
      expect(onEdge, isTrue);
    });

    test('punto fuera del radio', () {
      // ~1km al norte del workplace.
      final outside = LocationService.isWithinRadius(
        userLat: -34.5947,
        userLng: -58.3816,
        workplaceLat: -34.6037,
        workplaceLng: -58.3816,
        radiusMeters: 100,
      );
      expect(outside, isFalse);
    });

    test('radio cero solo acepta el punto exacto', () {
      final same = LocationService.isWithinRadius(
        userLat: -34.6037,
        userLng: -58.3816,
        workplaceLat: -34.6037,
        workplaceLng: -58.3816,
        radiusMeters: 0,
      );
      expect(same, isTrue);

      final different = LocationService.isWithinRadius(
        userLat: -34.6038,
        userLng: -58.3816,
        workplaceLat: -34.6037,
        workplaceLng: -58.3816,
        radiusMeters: 0,
      );
      expect(different, isFalse);
    });
  });
}
