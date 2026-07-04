import '../../data/models/attendance_model.dart';

abstract class AttendanceRepository {
  Stream<List<AttendanceModel>> getAttendancesByUser(String userId);
  Stream<AttendanceModel?> getActiveAttendance(String userId);
  Future<void> checkIn(String userId, String date);
  Future<void> checkOut(String attendanceUid);
}
