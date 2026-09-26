import 'package:app_locustaf/core/services/firestore_service.dart';
import 'package:app_locustaf/features/attendance/data/models/attendance_model.dart';
import 'package:app_locustaf/features/attendance/data/repositories/attendance_repository_impl.dart';
import 'package:app_locustaf/features/attendance/data/services/location_service.dart';
import 'package:app_locustaf/features/attendance/domain/exceptions/attendance_exception.dart';
import 'package:app_locustaf/features/attendance/domain/services/attendance_calculator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

/// Emula las callables de Fase 2/3 (`checkInGeo`, `checkOutGeo`): el servidor
/// recibe solo las coordenadas, resuelve al usuario/workplace y persiste con
/// la geocerca y los cálculos server-side. Reproduce la misma orquestación
/// transaccional (asistencia + lock) sin emulador ni red.
///
/// Nota: `test/features/attendance/presentation/providers/attendance_notifier_test.dart`
/// tiene una copia inline histórica de esta clase; este archivo centraliza la
/// versión para los widget E2E (consolidar la copia es deuda técnica menor).
class ServerEmulatorRepository extends AttendanceRepositoryImpl {
  final FakeFirebaseFirestore fake;

  ServerEmulatorRepository(FakeFirebaseFirestore fake, {super.companyId})
      : fake = fake,
        super(FirestoreService(fake));

  @override
  Future<void> checkIn({
    required double latitud,
    required double longitud,
  }) async {
    final user = await getUser('user-1');
    final workplaceId = user?.lugarDeTrabajoId;
    final workplace =
        workplaceId == null ? null : await getWorkplace(workplaceId);

    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final isLate = workplace?.horaInicio != null
        ? AttendanceCalculator.isLate(
            checkInTime: now,
            shiftStart:
                AttendanceCalculator.shiftTimeOn(now, workplace!.horaInicio!),
            toleranceMinutes: workplace.toleranciaMinutos,
          )
        : null;

    await manualCheckIn(
      AttendanceModel(
        id: '',
        userId: 'user-1',
        checkInTime: now,
        date: today,
        status: AttendanceStatus.active,
        isLate: isLate,
        workplaceId: workplaceId,
        companyId: 'company-1',
        checkInLatitud: latitud,
        checkInLongitud: longitud,
      ),
    );
  }

  @override
  Future<void> manualCheckIn(AttendanceModel attendance) async {
    await fake.runTransaction((tx) async {
      final lockRef = fake.collection('_attendance_locks').doc(attendance.userId);
      final lockDoc = await tx.get(lockRef);
      if (lockDoc.exists) {
        final data = lockDoc.data() as Map<String, dynamic>;
        final attendanceId = data['attendanceId'] as String?;
        var isReclaimable = _isStaleLock(data);
        if (!isReclaimable && attendanceId != null) {
          final attendanceRef = fake.collection('attendances').doc(attendanceId);
          final attendanceDoc = await tx.get(attendanceRef);
          isReclaimable = !attendanceDoc.exists ||
              (attendanceDoc.data() as Map<String, dynamic>)['status'] ==
                  'completed';
        }
        if (!isReclaimable) {
          throw AttendanceException(
            'Ya tenés una asistencia activa desde las '
            '${data['checkInTime'] ?? 'desconocido'}. '
            'Finalizala antes de registrar una nueva.',
          );
        }
      }

      final attendanceRef = fake.collection('attendances').doc();
      final data = attendance.toJson();
      data['id'] = attendanceRef.id;
      if (attendance.companyId != null) data['companyId'] = attendance.companyId;

      tx.set(attendanceRef, data);
      tx.set(lockRef, {
        'attendanceId': attendanceRef.id,
        'checkInTime': attendance.checkInTime.toUtc().toIso8601String(),
        'lockedAt': Timestamp.fromDate(DateTime.now().toUtc()),
        'status': 'active',
      });
    });
  }

  @override
  Future<void> checkOut({
    required String attendanceId,
    required double latitud,
    required double longitud,
  }) async {
    final user = await getUser('user-1');
    final workplaceId = user?.lugarDeTrabajoId;
    final workplace =
        workplaceId == null ? null : await getWorkplace(workplaceId);

    if (workplace?.latitud == null || workplace?.longitud == null) {
      throw AttendanceException(
          'El lugar de trabajo no tiene coordenadas configuradas.');
    }
    if (workplace!.radio == null || workplace.radio! <= 0) {
      throw AttendanceException(
          'El lugar de trabajo no tiene un radio de geocerca configurado.');
    }
    if (!LocationService.isWithinRadius(
      userLat: latitud,
      userLng: longitud,
      workplaceLat: workplace.latitud!,
      workplaceLng: workplace.longitud!,
      radiusMeters: workplace.radio!,
    )) {
      final distance = LocationService.calculateDistance(
        latitud,
        longitud,
        workplace.latitud!,
        workplace.longitud!,
      );
      throw AttendanceException(
        'Estás a ${distance.toStringAsFixed(0)} m del lugar de trabajo.',
      );
    }

    final now = DateTime.now();
    await fake.runTransaction((tx) async {
      final attRef = fake.collection('attendances').doc(attendanceId);
      final att = await tx.get(attRef);
      if (!att.exists) {
        throw AttendanceException('Registro de asistencia no encontrado.');
      }
      final data = att.data() as Map<String, dynamic>;
      if (data['userId'] != 'user-1') {
        throw AttendanceException('Este registro no te pertenece.');
      }
      if (data['status'] == 'completed') {
        throw AttendanceException('Esta asistencia ya fue finalizada.');
      }

      final lockRef = fake.collection('_attendance_locks').doc('user-1');
      final lock = await tx.get(lockRef);
      if (!lock.exists) {
        throw AttendanceException('No se encontró un bloqueo de sesión activo.');
      }

      final rawCheckIn = data['checkInTime'];
      final checkInDate = rawCheckIn is Timestamp
          ? rawCheckIn.toDate()
          : DateTime.tryParse(rawCheckIn as String);
      tx.update(attRef, {
        'checkOutTime': Timestamp.fromDate(now.toUtc()),
        'durationMinutes':
            checkInDate == null ? 0 : now.difference(checkInDate).inMinutes,
        'status': 'completed',
        'checkOutLatitud': latitud,
        'checkOutLongitud': longitud,
      });
      tx.delete(lockRef);
    });
  }
}

/// Fake de la plataforma geolocator para simular el GPS sin invocar plugins.
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

bool _isStaleLock(Map<String, dynamic> data) {
  final raw = data['lockedAt'] ?? data['checkInTime'];
  final DateTime? time;
  if (raw is Timestamp) {
    time = raw.toDate();
  } else if (raw is String) {
    time = DateTime.tryParse(raw);
  } else if (raw is DateTime) {
    time = raw;
  } else {
    time = null;
  }
  if (time == null) return false;
  return DateTime.now().difference(time) > const Duration(hours: 24);
}