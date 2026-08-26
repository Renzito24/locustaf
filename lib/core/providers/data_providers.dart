import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/attendance/data/models/attendance_model.dart';
import '../../core/models/user_model.dart';
import '../../features/workplaces/data/models/workplace_model.dart';
import 'firebase_providers.dart';

/// Fuente única de streams de datos compartidos.
///
/// Centraliza las suscripciones a Firestore para evitar duplicación
/// (antes existían streams paralelos en reports, history y dashboard).
/// Toda feature que necesite listas globales de users, workplaces o
/// attendances debe consumir estos providers.

final allUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final svc = ref.read(firestoreServiceProvider);
  return svc.collectionStream<UserModel>(
    path: 'users',
    fromJson: UserModel.fromJson,
  );
});

final allWorkplacesStreamProvider = StreamProvider<List<WorkplaceModel>>((ref) {
  final svc = ref.read(firestoreServiceProvider);
  return svc.collectionStream<WorkplaceModel>(
    path: 'workplaces',
    fromJson: WorkplaceModel.fromJson,
  );
});

final allAttendancesStreamProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final svc = ref.read(firestoreServiceProvider);
  return svc.collectionStream<AttendanceModel>(
    path: 'attendances',
    fromJson: AttendanceModel.fromJson,
  );
});
