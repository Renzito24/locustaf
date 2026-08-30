import 'package:app_locustaf/core/providers/firebase_providers.dart';
import 'package:app_locustaf/core/providers/data_providers.dart';
import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/attendance/presentation/providers/attendance_notifier.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

/// Fake de la plataforma geolocator para simular el GPS sin invocar plugins.
/// Extiende [GeolocatorPlatform] (token heredado vía `super`), y solo
/// override de los métodos que usa [LocationService].
class FakeGeolocatorPlatform extends GeolocatorPlatform {
  bool serviceEnabled;
  Position? position;

  FakeGeolocatorPlatform({this.serviceEnabled = true, this.position});

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.always;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.always;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    if (position == null) {
      throw Exception('No se configuró una posición de prueba');
    }
    return position!;
  }
}

/// Test E2E del flujo de asistencia: el notifier con sus providers reales
/// (Firestore fake en memoria + GPS fake) resolviendo checkIn → verificación
/// del estado → checkOut. Cubre el flujo completo sin emulador ni red.
void main() {
  const companyId = 'company-1';
  const userId = 'user-1';
  const workplaceId = 'workplace-1';
  const oficinaLat = -34.6037;
  const oficinaLng = -58.3816;

  late FakeFirebaseFirestore fake;
  late FakeGeolocatorPlatform geolocator;
  late ProviderContainer container;

  Future<void> seedUser({
    bool isActive = true,
    String? lugarDeTrabajoId = workplaceId,
  }) async {
    await fake.collection('users').doc(userId).set({
      'id': userId,
      'nombre': 'Juan',
      'apellido': 'Pérez',
      'email': 'juan@test.com',
      'dni': '12345678',
      'rol': 'employee',
      'isActive': isActive,
      'isDeleted': false,
      'lugarDeTrabajoId': lugarDeTrabajoId,
      'companyId': companyId,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> seedWorkplace({double? radio = 100.0}) async {
    await fake.collection('workplaces').doc(workplaceId).set({
      'id': workplaceId,
      'nombre': 'Oficina Central',
      'latitud': oficinaLat,
      'longitud': oficinaLng,
      'radio': radio,
      'horaInicio': '09:00',
      'horaFin': '18:00',
      'toleranciaMinutos': 15,
      'companyId': companyId,
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Position at(double lat, double lng, {double accuracy = 5.0}) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  setUp(() {
    fake = FakeFirebaseFirestore();
    geolocator = FakeGeolocatorPlatform();
    GeolocatorPlatform.instance = geolocator;

    container = ProviderContainer(
      overrides: [
        firestoreServiceProvider.overrideWithValue(FirestoreService(fake)),
        currentCompanyIdProvider.overrideWithValue(companyId),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Future<AttendanceActionState> runCheckIn() async {
    await container.read(attendanceActionProvider.notifier).checkIn(userId);
    return container.read(attendanceActionProvider);
  }

  Future<AttendanceActionState> runCheckOut(String attendanceId) async {
    await container.read(attendanceActionProvider.notifier).checkOut(attendanceId, userId);
    return container.read(attendanceActionProvider);
  }

  Future<String> activeAttendanceId() async {
    final docs = await fake
        .collection('attendances')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();
    expect(docs.docs, hasLength(1));
    return docs.docs.first.id;
  }

  group('AttendanceNotifier E2E (flujo de asistencia)', () {
    test('checkIn exitoso dentro del radio: persiste asistencia y lock', () async {
      await seedUser();
      await seedWorkplace();
      geolocator.position = at(oficinaLat, oficinaLng);

      final state = await runCheckIn();

      expect(state.status, AttendanceActionStatus.success);
      expect(state.message, contains('Asistencia registrada'));

      final docs = await fake
          .collection('attendances')
          .where('userId', isEqualTo: userId)
          .get();
      expect(docs.docs, hasLength(1));
      expect(docs.docs.first.get('status'), 'active');
      expect(docs.docs.first.get('companyId'), companyId);

      final lock = await fake.collection('_attendance_locks').doc(userId).get();
      expect(lock.exists, isTrue);
    });

    test('checkIn fuera del radio: error de geocerca con mensaje de distancia', () async {
      await seedUser();
      await seedWorkplace();
      // ~1.1 km al este de la oficina.
      geolocator.position = at(oficinaLat, oficinaLng + 0.01);

      final state = await runCheckIn();

      expect(state.status, AttendanceActionStatus.error);
      expect(state.message, contains('Estás a'));
      expect(state.message, contains('radio'));
    });

    test('checkIn con GPS apagado: error claro', () async {
      await seedUser();
      await seedWorkplace();
      geolocator.serviceEnabled = false;

      final state = await runCheckIn();

      expect(state.status, AttendanceActionStatus.error);
      expect(state.message, contains('GPS'));
    });

    test('checkIn de usuario mutado/inactivo: error', () async {
      await seedUser(isActive: false);
      await seedWorkplace();
      geolocator.position = at(oficinaLat, oficinaLng);

      final state = await runCheckIn();

      expect(state.status, AttendanceActionStatus.error);
      expect(state.message, contains('no está activa'));
    });

    test('checkIn sin lugar de trabajo asignado: error', () async {
      await seedUser(lugarDeTrabajoId: null);
      geolocator.position = at(oficinaLat, oficinaLng);

      final state = await runCheckIn();

      expect(state.status, AttendanceActionStatus.error);
      expect(state.message, contains('lugar de trabajo asignado'));
    });

    test('checkIn con workplace sin coordenadas: error', () async {
      await seedUser();
      await seedWorkplace();
      await fake.collection('workplaces').doc(workplaceId).update({
        'latitud': null,
        'longitud': null,
      });
      geolocator.position = at(oficinaLat, oficinaLng);

      final state = await runCheckIn();

      expect(state.status, AttendanceActionStatus.error);
      expect(state.message, contains('coordenadas'));
    });

    test('doble checkIn rechazado por lock activo', () async {
      await seedUser();
      await seedWorkplace();
      geolocator.position = at(oficinaLat, oficinaLng);

      final first = await runCheckIn();
      expect(first.status, AttendanceActionStatus.success);

      final second = await runCheckIn();
      expect(second.status, AttendanceActionStatus.error);
      expect(second.message, contains('Ya tenés una asistencia activa'));
    });

    test('checkOut exitoso: finaliza jornada, calcula duración y limpia el lock', () async {
      await seedUser();
      await seedWorkplace();
      geolocator.position = at(oficinaLat, oficinaLng);

      await runCheckIn();
      final attendanceId = await activeAttendanceId();

      final checkout = await runCheckOut(attendanceId);
      expect(checkout.status, AttendanceActionStatus.success);
      expect(checkout.message, contains('Jornada finalizada'));

      final doc = await fake.collection('attendances').doc(attendanceId).get();
      expect(doc.get('status'), 'completed');
      expect(doc.get('durationMinutes'), greaterThanOrEqualTo(0));
      expect(doc.get('checkOutLatitud'), oficinaLat);

      final lock = await fake.collection('_attendance_locks').doc(userId).get();
      expect(lock.exists, isFalse);
    });

    test('checkOut fuera del radio: error de geocerca', () async {
      await seedUser();
      await seedWorkplace();
      geolocator.position = at(oficinaLat, oficinaLng);
      await runCheckIn();
      final attendanceId = await activeAttendanceId();

      geolocator.position = at(oficinaLat, oficinaLng + 0.01);
      final state = await runCheckOut(attendanceId);

      expect(state.status, AttendanceActionStatus.error);
      expect(state.message, contains('Estás a'));
    });

    test('checkOut de asistencia inexistente: error', () async {
      await seedUser();
      await seedWorkplace();
      geolocator.position = at(oficinaLat, oficinaLng);

      final state = await runCheckOut('missing-attendance');

      expect(state.status, AttendanceActionStatus.error);
      expect(state.message, contains('no encontrado'));
    });
  });
}