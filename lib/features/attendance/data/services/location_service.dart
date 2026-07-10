import 'dart:math';

import 'package:geolocator/geolocator.dart';

/// Precisión máxima permitida para la ubicación GPS en metros.
/// 25m es un umbral razonable para interiores/exteriores con GPS estándar.
/// En exteriores con cielo abierto el GPS alcanza ~3-5m.
/// En interiores puede degradarse a 20-50m. 25m balancea precisión y usabilidad.
const double kMaxGpsAccuracy = 25.0;

enum LocationStatus {
  available,
  denied,
  deniedForever,
  disabled,
  lowAccuracy,
  unavailable,
}

class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final LocationStatus status;
  final String? message;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy = 0,
    required this.status,
    this.message,
  });
}

class LocationService {
  Future<LocationResult> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
        latitude: 0,
        longitude: 0,
        status: LocationStatus.disabled,
        message: 'El GPS está desactivado. Activá la ubicación para registrar tu asistencia.',
      );
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult(
          latitude: 0,
          longitude: 0,
          status: LocationStatus.denied,
          message: 'Permiso de ubicación denegado. Para registrar asistencia, aceptá el permiso.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
        latitude: 0,
        longitude: 0,
        status: LocationStatus.deniedForever,
        message: 'Permiso de ubicación denegado permanentemente. Activálo desde la configuración del navegador.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      if (position.accuracy > kMaxGpsAccuracy) {
        return LocationResult(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          status: LocationStatus.lowAccuracy,
          message: 'La señal GPS no tiene precisión suficiente (${position.accuracy.toStringAsFixed(0)}m, se requiere ≤ ${kMaxGpsAccuracy.toStringAsFixed(0)}m). '
              'Acercate a una ventana o salí al exterior.',
        );
      }

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        status: LocationStatus.available,
      );
    } catch (e) {
      return LocationResult(
        latitude: 0,
        longitude: 0,
        status: LocationStatus.unavailable,
        message: 'No se pudo obtener la ubicación: $e',
      );
    }
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double r = 6371000.0;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static bool isWithinRadius({
    required double userLat,
    required double userLng,
    required double workplaceLat,
    required double workplaceLng,
    required double radiusMeters,
  }) {
    final double distance = calculateDistance(
      userLat, userLng, workplaceLat, workplaceLng,
    );
    return distance <= radiusMeters;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }
}
