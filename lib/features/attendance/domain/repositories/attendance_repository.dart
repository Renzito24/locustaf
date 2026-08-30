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
  Future<void> checkIn(AttendanceModel attendance);
  Future<void> checkOut(
    String attendanceId,
    String userId, {
    double? checkOutLatitud,
    double? checkOutLongitud,
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
