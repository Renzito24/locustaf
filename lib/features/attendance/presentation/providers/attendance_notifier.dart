import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../data/services/location_service.dart';
import '../../domain/exceptions/attendance_exception.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/services/attendance_calculator.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../workplaces/data/models/workplace_model.dart';

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

/// Asistencias activas que superaron el fin de jornada de su lugar de trabajo
/// sin registrar salida (jornadas huérfanas).
final orphanedAttendancesProvider = Provider<List<AttendanceModel>>((ref) {
  final attendancesAsync = ref.watch(allAttendancesStreamProvider);
  final workplacesAsync = ref.watch(allWorkplacesStreamProvider);
  final attendances = attendancesAsync.value ?? [];
  final workplaces = workplacesAsync.value ?? [];

  final orphaned = <AttendanceModel>[];
  for (final a in attendances) {
    if (a.status != AttendanceStatus.active) continue;
    WorkplaceModel? workplace;
    for (final w in workplaces) {
      if (w.id == a.workplaceId) {
        workplace = w;
        break;
      }
    }
    if (workplace == null || workplace.horaFin == null) continue;
    final shiftEnd = AttendanceCalculator.shiftTimeOn(a.checkInTime, workplace.horaFin!);
    if (AttendanceCalculator.isOrphaned(
      attendance: a,
      shiftEnd: shiftEnd,
      now: DateTime.now(),
    )) {
      orphaned.add(a);
    }
  }
  return orphaned;
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

      final locationResult = await _validateLocation(workplace);
      if (locationResult.error != null) {
        state = AttendanceActionState.error(locationResult.error!);
        return;
      }
      final location = locationResult.location!;

      final now = DateTime.now();
      final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final isLate = workplace.horaInicio != null
          ? AttendanceCalculator.isLate(
              checkInTime: now,
              shiftStart: AttendanceCalculator.shiftTimeOn(now, workplace.horaInicio!),
              toleranceMinutes: workplace.toleranciaMinutos,
            )
          : null;

      final attendance = AttendanceModel(
        id: '',
        userId: userId,
        checkInTime: now,
        date: today,
        status: AttendanceStatus.active,
        checkInLatitud: location.latitude,
        checkInLongitud: location.longitude,
        isLate: isLate,
        workplaceId: workplaceId,
      );

      await repo.checkIn(attendance);
      state = AttendanceActionState.success('Asistencia registrada correctamente.');
    } on AttendanceException catch (e) {
      state = AttendanceActionState.error(e.message);
    } catch (e) {
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

      final locationResult = await _validateLocation(workplace);
      if (locationResult.error != null) {
        state = AttendanceActionState.error(locationResult.error!);
        return;
      }
      final location = locationResult.location!;

      await repo.checkOut(
        attendanceId,
        userId,
        checkOutLatitud: location.latitude,
        checkOutLongitud: location.longitude,
      );
      state = AttendanceActionState.success('Jornada finalizada correctamente.');
    } on AttendanceException catch (e) {
      state = AttendanceActionState.error(e.message);
    } catch (e) {
      state = AttendanceActionState.error('Error al finalizar jornada: $e');
    }
  }

  /// Finaliza una jornada huérfana (activa que superó el fin de jornada)
  /// sin validar ubicación, ya que el empleado puede no estar en el lugar.
  Future<void> finalizeOrphaned(String attendanceId, String userId) async {
    state = const AttendanceActionState.loading();
    final repo = ref.read(attendanceRepositoryProvider);
    try {
      await repo.finalizeOrphaned(attendanceId, userId);
      state = AttendanceActionState.success('Jornada huérfana finalizada correctamente.');
    } on AttendanceException catch (e) {
      state = AttendanceActionState.error(e.message);
    } catch (e) {
      state = AttendanceActionState.error('Error al finalizar jornada: $e');
    }
  }

  /// Valida que la ubicación actual esté disponible y dentro del radio del
  /// lugar de trabajo. Devuelve la ubicación o un mensaje de error.
  Future<({LocationResult? location, String? error})> _validateLocation(
    WorkplaceModel workplace,
  ) async {
    final locationService = LocationService();
    final location = await locationService.getCurrentPosition();

    if (location.status != LocationStatus.available) {
      return (location: null, error: location.message ?? 'Error de ubicación.');
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
      return (
        location: null,
        error: 'Estás a $distStr del lugar de trabajo (${workplace.nombre}). '
            'Debés estar dentro del radio de ${workplace.radio!.toStringAsFixed(0)} m para registrar asistencia.',
      );
    }

    return (location: location, error: null);
  }

  void reset() {
    state = const AttendanceActionState.idle();
  }
}

final attendanceActionProvider = NotifierProvider<AttendanceNotifier, AttendanceActionState>(
  AttendanceNotifier.new,
);
