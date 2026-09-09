import '../../data/models/attendance_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../workplaces/data/models/workplace_model.dart';

/// Página de asistencias ordenadas por checkInTime descendente.
class AttendancePage {
  final List<AttendanceModel> items;
  final bool hasMore;
  final Object? lastCheckInTime;

  const AttendancePage({
    required this.items,
    required this.hasMore,
    this.lastCheckInTime,
  });
}

abstract class AttendanceRepository {
  Stream<List<AttendanceModel>> getAttendancesByUser(String userId);
  Stream<List<AttendanceModel>> getAllAttendances();
  Stream<List<AttendanceModel>> getAllActiveAttendances();
  Stream<AttendanceModel?> getActiveAttendance(String userId);

  /// Registra el ingreso por GPS del propio empleado. La geocerca se valida en
  /// el servidor (callable `checkInGeo`): solo se envían las coordenadas y el
  /// lugar de trabajo se resuelve desde el documento del usuario (AUI-02).
  Future<void> checkIn({required double latitud, required double longitud});

  /// Registra un ingreso manual (realizado por un administrador) sin validar
  /// ubicación, para empleados que no pueden registrarse por sí mismos.
  Future<void> manualCheckIn(AttendanceModel attendance);

  /// Finaliza la jornada del empleado por GPS. La geocerca se valida en el
  /// servidor (callable `checkOutGeo`): solo se envían las coordenadas y el id
  /// de la asistencia; checkOutTime/durationMinutes se derivan en el servidor
  /// (AUI-02, Fase 3).
  Future<void> checkOut({
    required String attendanceId,
    required double latitud,
    required double longitud,
  });
  Future<void> finalizeOrphaned(String attendanceId, String userId);
  Future<UserModel?> getUser(String userId);
  Future<WorkplaceModel?> getWorkplace(String workplaceId);

  /// Página de asistencias de la empresa (o de la compañía configurada)
  /// ordenadas por checkInTime descendente, para paginación por cursor.
  Future<AttendancePage> getAttendancePage({
    required int limit,
    Object? startAfter,
  });

  /// Total real de asistencias de la empresa usando agregación COUNT nativa.
  Future<int> countCompanyAttendances();
}
