import '../../data/models/attendance_model.dart';
import '../../../authentication/data/models/user_model.dart';
import '../../../workplaces/data/models/workplace_model.dart';

abstract class AttendanceRepository {
  Stream<List<AttendanceModel>> getAttendancesByUser(String userId);
  Stream<List<AttendanceModel>> getAllAttendances();
  Stream<AttendanceModel?> getActiveAttendance(String userId);
  Future<void> checkIn(AttendanceModel attendance);
  Future<void> checkOut(String attendanceId, String userId);
  Future<UserModel?> getUser(String userId);
  Future<WorkplaceModel?> getWorkplace(String workplaceId);
}
