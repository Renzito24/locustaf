import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/models/user_model.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../../domain/exceptions/attendance_exception.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../models/attendance_model.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final FirestoreService _firestoreService;
  final String? _companyId;
  final FirebaseFunctions? _functions;

  AttendanceRepositoryImpl(
    this._firestoreService, {
    String? companyId,
    FirebaseFunctions? functions,
  })  : _functions = functions,
        _companyId = companyId;

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

  /// Asistencias activas de la empresa. Consulta acotada a `status == 'active'`
  /// a nivel de base de datos para no descargar el historial completo en cada
  /// cambio (locks y jornadas huérfanas solo necesitan las activas).
  @override
  Stream<List<AttendanceModel>> getAllActiveAttendances() {
    if (_companyId == null) return Stream.value(<AttendanceModel>[]);
    return _firestoreService.queryStreamWithFilters<AttendanceModel>(
      path: 'attendances',
      filters: {'companyId': _companyId, 'status': 'active'},
      fromJson: AttendanceModel.fromJson,
    );
  }

  @override
  Future<AttendancePage> getAttendancePage({
    required int limit,
    Object? startAfter,
  }) async {
    if (_companyId == null) return const AttendancePage(items: [], hasMore: false);
    final page = await _firestoreService.queryPage<AttendanceModel>(
      path: 'attendances',
      filters: {'companyId': _companyId},
      fromJson: AttendanceModel.fromJson,
      orderField: 'checkInTime',
      descending: true,
      limit: limit,
      startAfter: startAfter,
    );
    return AttendancePage(
      items: page.items,
      hasMore: page.hasMore,
      lastCheckInTime: page.lastOrderValue,
    );
  }

  @override
  Future<int> countCompanyAttendances() async {
    if (_companyId == null) return 0;
    return _firestoreService.countDocuments(
      path: 'attendances',
      filters: {'companyId': _companyId},
    );
  }

  @override
  Stream<AttendanceModel?> getActiveAttendance(String userId) {
    // R-QG-2: sin empresa en sesión no se consulta nada (Opción B).
    if (_companyId == null) return Stream.value(null);
    return _firestoreService.queryStreamWithFilters<AttendanceModel>(
      path: 'attendances',
      filters: {
        'userId': userId,
        'status': 'active',
        'companyId': _companyId,
      },
      fromJson: AttendanceModel.fromJson,
    ).map((list) {
      if (list.isEmpty) return null;
      return list.first;
    });
  }

  @override
  Future<void> checkIn({
    required double latitud,
    required double longitud,
  }) async {
    final functions = _functions;
    if (functions == null) {
      throw AttendanceException('El servicio de Cloud Functions no está configurado.');
    }
    try {
      final callable = functions.httpsCallable('checkInGeo');
      await callable<Map<String, dynamic>>({
        'latitud': latitud,
        'longitud': longitud,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AttendanceException(e.message ?? 'No se pudo registrar la asistencia.');
    }
  }

  @override
  Future<void> manualCheckIn(AttendanceModel attendance) async {
    final functions = _functions;
    if (functions == null) {
      throw AttendanceException('El servicio de Cloud Functions no está configurado.');
    }
    try {
      final callable = functions.httpsCallable('manualCheckIn');
      await callable<Map<String, dynamic>>({
        'targetUserId': attendance.userId,
        'checkInTime': attendance.checkInTime.toUtc().toIso8601String(),
      });
    } on FirebaseFunctionsException catch (e) {
      throw AttendanceException(e.message ?? 'No se pudo registrar la asistencia.');
    }
  }

  @override
  Future<void> checkOut({
    required String attendanceId,
    required double latitud,
    required double longitud,
  }) async {
    final functions = _functions;
    if (functions == null) {
      throw AttendanceException('El servicio de Cloud Functions no está configurado.');
    }
    try {
      final callable = functions.httpsCallable('checkOutGeo');
      await callable<Map<String, dynamic>>({
        'attendanceId': attendanceId,
        'latitud': latitud,
        'longitud': longitud,
      });
    } on FirebaseFunctionsException catch (e) {
      throw AttendanceException(e.message ?? 'No se pudo finalizar la jornada.');
    }
  }

  @override
  Future<void> finalizeOrphaned(String attendanceId, String userId) async {
    final functions = _functions;
    if (functions == null) {
      throw AttendanceException('El servicio de Cloud Functions no está configurado.');
    }
    try {
      final callable = functions.httpsCallable('finalizeOrphaned');
      await callable<Map<String, dynamic>>({'attendanceId': attendanceId});
    } on FirebaseFunctionsException catch (e) {
      throw AttendanceException(e.message ?? 'No se pudo finalizar la jornada.');
    }
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
