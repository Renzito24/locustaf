import '../../../../core/services/firestore_service.dart';
import '../../../../core/models/user_model.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../../domain/exceptions/attendance_exception.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirestoreService _firestoreService;
  final String? _companyId;

  AttendanceRepositoryImpl(this._firestoreService, {String? companyId})
      : _companyId = companyId;

  @override
  Stream<List<AttendanceModel>> getAttendancesByUser(String userId) {
    return _firestoreService.queryStreamWithFilters<AttendanceModel>(
      path: 'attendances',
      filters: {
        'userId': userId,
        if (_companyId != null) 'companyId': _companyId,
      },
      fromJson: AttendanceModel.fromJson,
      orderField: 'checkInTime',
      descending: true,
    );
  }

  @override
  Stream<List<AttendanceModel>> getAllAttendances() {
    if (_companyId == null) return Stream.value(<AttendanceModel>[]);
    return _firestoreService.queryStreamWithFilters<AttendanceModel>(
      path: 'attendances',
      filters: {'companyId': _companyId},
      fromJson: AttendanceModel.fromJson,
    );
  }

  @override
  Stream<AttendanceModel?> getActiveAttendance(String userId) {
    return _firestoreService.queryStreamWithFilters<AttendanceModel>(
      path: 'attendances',
      filters: {
        'userId': userId,
        'status': 'active',
      },
      fromJson: AttendanceModel.fromJson,
    ).map((list) {
      if (list.isEmpty) return null;
      return list.first;
    });
  }

  @override
  Future<void> checkIn(AttendanceModel attendance) async {
    final lockRef =
        _firestoreService.collection('_attendance_locks').doc(attendance.userId);

    await _firestoreService.runTransaction((transaction) async {
      final lockDoc = await transaction.get(lockRef);
      if (lockDoc.exists) {
        final data = lockDoc.data() as Map<String, dynamic>;
        throw AttendanceException(
          'Ya tenés una asistencia activa desde las ${data['checkInTime'] ?? 'desconocido'}. '
          'Finalizala antes de registrar una nueva.',
        );
      }

      final attendanceRef =
          _firestoreService.collection('attendances').doc();
      final data = attendance.toJson();
      data['id'] = attendanceRef.id;
      if (_companyId != null) data['companyId'] = _companyId;

      transaction.set(attendanceRef, data);
      transaction.set(lockRef, {
        'attendanceId': attendanceRef.id,
        'checkInTime': attendance.checkInTime.toIso8601String(),
        'status': 'active',
      });
    });
  }

  @override
  Future<void> checkOut(
    String attendanceId,
    String userId, {
    double? checkOutLatitud,
    double? checkOutLongitud,
  }) async {
    final attendanceRef =
        _firestoreService.collection('attendances').doc(attendanceId);
    final lockRef =
        _firestoreService.collection('_attendance_locks').doc(userId);

    await _firestoreService.runTransaction((transaction) async {
      final attendanceDoc = await transaction.get(attendanceRef);
      if (!attendanceDoc.exists) {
        throw AttendanceException('Registro de asistencia no encontrado.');
      }
      final attendanceData =
          attendanceDoc.data() as Map<String, dynamic>;
      if (attendanceData['userId'] != userId) {
        throw AttendanceException('Este registro no te pertenece.');
      }
      if (attendanceData['status'] == 'completed') {
        throw AttendanceException('Esta asistencia ya fue finalizada.');
      }

      final lockDoc = await transaction.get(lockRef);
      if (!lockDoc.exists) {
        throw AttendanceException('No se encontró un bloqueo de sesión activo. '
            'Es posible que la sesión ya haya sido finalizada.');
      }

      final now = DateTime.now();
      final checkInTime =
          DateTime.parse(attendanceData['checkInTime'] as String);
      final durationMinutes = now.difference(checkInTime).inMinutes;

      transaction.update(attendanceRef, {
        'checkOutTime': now.toIso8601String(),
        'durationMinutes': durationMinutes,
        'status': 'completed',
        'checkOutLatitud': checkOutLatitud,
        'checkOutLongitud': checkOutLongitud,
      });
      transaction.delete(lockRef);
    });
  }

  @override
  Future<void> finalizeOrphaned(String attendanceId, String userId) async {
    final attendanceRef =
        _firestoreService.collection('attendances').doc(attendanceId);
    final lockRef =
        _firestoreService.collection('_attendance_locks').doc(userId);

    await _firestoreService.runTransaction((transaction) async {
      final attendanceDoc = await transaction.get(attendanceRef);
      if (!attendanceDoc.exists) {
        throw AttendanceException('Registro de asistencia no encontrado.');
      }
      final attendanceData =
          attendanceDoc.data() as Map<String, dynamic>;
      if (attendanceData['userId'] != userId) {
        throw AttendanceException('Este registro no te pertenece.');
      }
      if (attendanceData['status'] == 'completed') {
        throw AttendanceException('Esta asistencia ya fue finalizada.');
      }

      final now = DateTime.now();
      final checkInTime =
          DateTime.parse(attendanceData['checkInTime'] as String);
      final durationMinutes = now.difference(checkInTime).inMinutes;

      transaction.update(attendanceRef, {
        'checkOutTime': now.toIso8601String(),
        'durationMinutes': durationMinutes,
        'status': 'completed',
        'isOrphaned': true,
      });
      transaction.delete(lockRef);
    });
  }

  @override
  Future<UserModel?> getUser(String userId) async {
    final doc = await _firestoreService.getDocument(
      path: 'users',
      documentId: userId,
    );
    if (doc == null) return null;
    return UserModel.fromJson(doc);
  }

  @override
  Future<WorkplaceModel?> getWorkplace(String workplaceId) async {
    final doc = await _firestoreService.getDocument(
      path: 'workplaces',
      documentId: workplaceId,
    );
    if (doc == null) return null;
    return WorkplaceModel.fromJson(doc);
  }
}
