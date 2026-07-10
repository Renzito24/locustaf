import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/services/location_service.dart';
import '../../domain/exceptions/attendance_exception.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../../../core/services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final svc = ref.read(firestoreServiceProvider);
  return AttendanceRepositoryImpl(svc);
});

final attendancesByUserProvider = StreamProvider.family<List<AttendanceModel>, String>((ref, userId) {
  final repo = ref.read(attendanceRepositoryProvider);
  return repo.getAttendancesByUser(userId);
});

final activeAttendanceProvider = StreamProvider.family<AttendanceModel?, String>((ref, userId) {
  final repo = ref.read(attendanceRepositoryProvider);
  return repo.getActiveAttendance(userId);
});

enum AttendanceActionStatus { idle, loading, success, error }

class AttendanceActionState {
  final AttendanceActionStatus status;
  final String? message;

  const AttendanceActionState({
    this.status = AttendanceActionStatus.idle,
    this.message,
  });

  const AttendanceActionState.idle() : this();
  const AttendanceActionState.loading() : this(status: AttendanceActionStatus.loading);
  const AttendanceActionState.success(String msg) : this(status: AttendanceActionStatus.success, message: msg);
  const AttendanceActionState.error(String msg) : this(status: AttendanceActionStatus.error, message: msg);
}

class AttendanceNotifier extends Notifier<AttendanceActionState> {
  @override
  AttendanceActionState build() => const AttendanceActionState.idle();

  Future<void> checkIn(String userId) async {
    state = const AttendanceActionState.loading();

    final repo = ref.read(attendanceRepositoryProvider);

    try {
      final user = await repo.getUser(userId);
      if (user == null) {
        state = const AttendanceActionState.error('Usuario no encontrado.');
        return;
      }

      if (!user.isActive || user.isDeleted) {
        state = const AttendanceActionState.error('La cuenta no está activa. No se puede registrar asistencia.');
        return;
      }

      final workplaceId = user.lugarDeTrabajoId;
      if (workplaceId == null || workplaceId.isEmpty) {
        state = const AttendanceActionState.error('No tenés un lugar de trabajo asignado. Contactá al administrador.');
        return;
      }

      final workplace = await repo.getWorkplace(workplaceId);
      if (workplace == null) {
        state = const AttendanceActionState.error('El lugar de trabajo asignado no existe.');
        return;
      }

      if (!workplace.isActive) {
        state = const AttendanceActionState.error('El lugar de trabajo está desactivado. Contactá al administrador.');
        return;
      }

      if (workplace.latitud == null || workplace.longitud == null) {
        state = const AttendanceActionState.error('El lugar de trabajo no tiene coordenadas configuradas.');
        return;
      }

      if (workplace.radio == null || workplace.radio! <= 0) {
        state = const AttendanceActionState.error('El lugar de trabajo no tiene un radio de geocerca configurado.');
        return;
      }

      final locationService = LocationService();
      final location = await locationService.getCurrentPosition();

      if (location.status != LocationStatus.available) {
        state = AttendanceActionState.error(location.message ?? 'Error de ubicación.');
        return;
      }

      final withinRadius = LocationService.isWithinRadius(
        userLat: location.latitude,
        userLng: location.longitude,
        workplaceLat: workplace.latitud!,
        workplaceLng: workplace.longitud!,
        radiusMeters: workplace.radio!,
      );

      if (!withinRadius) {
        final distance = LocationService.calculateDistance(
          location.latitude, location.longitude,
          workplace.latitud!, workplace.longitud!,
        );
        final distStr = distance >= 1000
            ? '${(distance / 1000).toStringAsFixed(1)} km'
            : '${distance.toStringAsFixed(0)} m';
        state = AttendanceActionState.error(
          'Estás a $distStr del lugar de trabajo (${workplace.nombre}). '
          'Debés estar dentro del radio de ${workplace.radio!.toStringAsFixed(0)} m para registrar asistencia.',
        );
        return;
      }

      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final attendance = AttendanceModel(
        id: '',
        userId: userId,
        checkInTime: now,
        date: today,
        status: AttendanceStatus.active,
        checkInLatitud: location.latitude,
        checkInLongitud: location.longitude,
        workplaceId: workplaceId,
      );

      await repo.checkIn(attendance);
      state = AttendanceActionState.success('Asistencia registrada correctamente.');
    } on AttendanceException catch (e) {
      state = AttendanceActionState.error(e.message);
    } catch (e, _) {
      state = AttendanceActionState.error('Error al registrar asistencia: $e');
    }
  }

  Future<void> checkOut(String attendanceId, String userId) async {
    state = const AttendanceActionState.loading();

    final repo = ref.read(attendanceRepositoryProvider);

    try {
      final user = await repo.getUser(userId);
      if (user == null) {
        state = const AttendanceActionState.error('Usuario no encontrado.');
        return;
      }

      if (!user.isActive || user.isDeleted) {
        state = const AttendanceActionState.error('La cuenta no está activa.');
        return;
      }

      await repo.checkOut(attendanceId, userId);
      state = AttendanceActionState.success('Jornada finalizada correctamente.');
    } on AttendanceException catch (e) {
      state = AttendanceActionState.error(e.message);
    } catch (e, _) {
      state = AttendanceActionState.error('Error al finalizar jornada: $e');
    }
  }

  void reset() {
    state = const AttendanceActionState.idle();
  }
}

final attendanceActionProvider = NotifierProvider<AttendanceNotifier, AttendanceActionState>(
  AttendanceNotifier.new,
);
