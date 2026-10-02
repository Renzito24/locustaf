import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/domain_exceptions.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/services/logging_service.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/services/location_service.dart';
import '../../domain/exceptions/attendance_exception.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/services/attendance_calculator.dart';
import 'attendance_stream_providers.dart';

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

  Future<WorkplaceModel> _validateUserAndWorkplace(
    AttendanceRepository repo,
    String userId, {
    bool requireCoordinates = false,
  }) async {
    final user = await repo.getUser(userId);
    if (user == null) {
      throw AttendanceException('Usuario no encontrado.');
    }

    if (!user.isActive || user.isDeleted) {
      throw AttendanceException('La cuenta no está activa. No se puede registrar asistencia.');
    }

    final workplaceId = user.lugarDeTrabajoId;
    if (workplaceId == null || workplaceId.isEmpty) {
      throw AttendanceException('No tenés un lugar de trabajo asignado. Contactá al administrador.');
    }

    final workplace = await repo.getWorkplace(workplaceId);
    if (workplace == null) {
      throw AttendanceException('El lugar de trabajo asignado no existe.');
    }

    if (!workplace.isActive) {
      throw AttendanceException('El lugar de trabajo está desactivado. Contactá al administrador.');
    }

    if (requireCoordinates) {
      if (workplace.latitud == null || workplace.longitud == null) {
        throw AttendanceException('El lugar de trabajo no tiene coordenadas configuradas.');
      }

      if (workplace.radio == null || workplace.radio! <= 0) {
        throw AttendanceException('El lugar de trabajo no tiene un radio de geocerca configurado.');
      }
    }

    return workplace;
  }

  Future<void> checkIn(String userId) async {
    state = const AttendanceActionState.loading();
    final repo = ref.read(attendanceRepositoryProvider);

    try {
      final workplace = await _validateUserAndWorkplace(repo, userId, requireCoordinates: true);
      final location = await _validateLocation(workplace);

      await repo.checkIn(latitud: location.latitude, longitud: location.longitude);
      LoggingService.instance.info('Check-in registrado', tag: 'attendance');
      state = const AttendanceActionState.success('Asistencia registrada correctamente.');
    } catch (e) {
      LoggingService.instance.error('Error al registrar check-in', tag: 'attendance', error: e);
      state = AttendanceActionState.error(ErrorHandler.parse(e).message);
    }
  }

  /// Registra el ingreso de un empleado de forma manual (realizado por un
  /// administrador), sin validar ubicación. Para empleados que no pueden
  /// registrarse por sí mismos (p. ej. sin celular).
  Future<void> manualCheckIn(String userId) async {
    state = const AttendanceActionState.loading();
    final repo = ref.read(attendanceRepositoryProvider);

    try {
      final workplace = await _validateUserAndWorkplace(repo, userId, requireCoordinates: false);

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
        isLate: isLate,
        workplaceId: workplace.id,
        companyId: ref.read(currentCompanyIdProvider),
      );

      await repo.manualCheckIn(attendance);
      LoggingService.instance.info('Check-in manual registrado', tag: 'attendance');
      state = const AttendanceActionState.success('Ingreso registrado manualmente.');
    } catch (e) {
      LoggingService.instance.error('Error al registrar check-in manual', tag: 'attendance', error: e);
      state = AttendanceActionState.error(ErrorHandler.parse(e).message);
    }
  }

  Future<void> checkOut(String attendanceId, String userId) async {
    state = const AttendanceActionState.loading();
    final repo = ref.read(attendanceRepositoryProvider);

    try {
      final workplace = await _validateUserAndWorkplace(repo, userId, requireCoordinates: true);
      final location = await _validateLocation(workplace);

      await repo.checkOut(
        attendanceId: attendanceId,
        latitud: location.latitude,
        longitud: location.longitude,
      );
      LoggingService.instance.info('Check-out registrado', tag: 'attendance');
      state = const AttendanceActionState.success('Jornada finalizada correctamente.');
    } catch (e) {
      LoggingService.instance.error('Error al finalizar jornada', tag: 'attendance', error: e);
      state = AttendanceActionState.error(ErrorHandler.parse(e).message);
    }
  }

  /// Finaliza una jornada huérfana (activa que superó el fin de jornada)
  /// sin validar ubicación, ya que el empleado puede no estar en el lugar.
  Future<void> finalizeOrphaned(String attendanceId, String userId) async {
    state = const AttendanceActionState.loading();
    final repo = ref.read(attendanceRepositoryProvider);
    try {
      await repo.finalizeOrphaned(attendanceId, userId);
      LoggingService.instance.info('Jornada huérfana finalizada', tag: 'attendance');
      state = const AttendanceActionState.success('Jornada huérfana finalizada correctamente.');
    } catch (e) {
      LoggingService.instance.error('Error al finalizar jornada huérfana', tag: 'attendance', error: e);
      state = AttendanceActionState.error(ErrorHandler.parse(e).message);
    }
  }

  /// Valida que la ubicación actual esté disponible y dentro del radio del
  /// lugar de trabajo. Devuelve la ubicación o un mensaje de error.
  Future<LocationResult> _validateLocation(WorkplaceModel workplace) async {
    final locationService = LocationService();
    final location = await locationService.getCurrentPosition();

    switch (location.status) {
      case LocationStatus.disabled:
        throw LocationDisabledException('El GPS está desactivado.');
      case LocationStatus.denied:
      case LocationStatus.deniedForever:
        throw LocationPermissionException('Permiso de ubicación denegado.');
      case LocationStatus.lowAccuracy:
        throw LocationAccuracyException('Señal GPS débil.');
      case LocationStatus.unavailable:
        throw Exception('Ubicación no disponible.');
      case LocationStatus.available:
        break;
    }

    final withinRadius = LocationService.isWithinRadius(
      userLat: location.latitude,
      userLng: location.longitude,
      workplaceLat: workplace.latitud!,
      workplaceLng: workplace.longitud!,
      radiusMeters: workplace.radio!,
    );

    if (!withinRadius) {
      throw LocationOutOfRangeException('Fuera del área de trabajo.');
    }

    return location;
  }

  void reset() {
    state = const AttendanceActionState.idle();
  }
}

final attendanceActionProvider = NotifierProvider<AttendanceNotifier, AttendanceActionState>(
  AttendanceNotifier.new,
);
