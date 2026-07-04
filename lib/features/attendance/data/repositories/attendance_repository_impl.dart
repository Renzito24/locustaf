import '../../../../core/services/firestore_service.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirestoreService _firestoreService;

  AttendanceRepositoryImpl(this._firestoreService);

  @override
  Stream<List<AttendanceModel>> getAttendancesByUser(String userId) {
    return _firestoreService.queryStream<AttendanceModel>(
      path: 'attendances',
      field: 'userId',
      value: userId,
      fromJson: AttendanceModel.fromJson,
    );
  }

  @override
  Stream<AttendanceModel?> getActiveAttendance(String userId) {
    return _firestoreService.queryStreamWithoutOrder<AttendanceModel>(
      path: 'attendances',
      field: 'userId',
      value: userId,
      fromJson: AttendanceModel.fromJson,
    ).map((list) {
      final active = list.where((a) => a.status == AttendanceStatus.active).toList();
      if (active.isEmpty) return null;
      active.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return active.first;
    });
  }

  @override
  Future<void> checkIn(String userId, String date) async {
    final now = DateTime.now();
    await _firestoreService.addDocument(
      path: 'attendances',
      data: {
        'userId': userId,
        'checkInTime': now.toIso8601String(),
        'date': date,
        'status': 'active',
      },
    );
  }

  @override
  Future<void> checkOut(String attendanceUid) async {
    final now = DateTime.now();
    final docSnapshot = await _firestoreService.getDocument(
      path: 'attendances',
      documentId: attendanceUid,
    );
    if (docSnapshot == null) return;

    final checkInTime = DateTime.parse(docSnapshot['checkInTime'] as String);
    final duration = now.difference(checkInTime);
    final durationMinutes = duration.inMinutes;

    await _firestoreService.updateDocument(
      path: 'attendances',
      documentId: attendanceUid,
      data: {
        'checkOutTime': now.toIso8601String(),
        'durationMinutes': durationMinutes,
        'status': 'completed',
      },
    );
  }
}
