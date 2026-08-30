import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/attendance/data/models/attendance_model.dart';
import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../../features/workplaces/data/models/workplace_model.dart';
import '../../core/models/user_model.dart';
import 'firebase_providers.dart';

/// Fuente única de streams de datos compartidos.
///
/// Centraliza las suscripciones a Firestore para evitar duplicación.
/// Todos los streams filtran por el `companyId` del usuario autenticado,
/// garantizando aislamiento multiempresa a nivel de consulta.

/// companyId del usuario autenticado (null si no hay sesión o no tiene empresa).
final currentCompanyIdProvider = Provider<String?>((ref) {
  return ref.watch(currentAppUserProvider).value?.companyId;
});

final allUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  final svc = ref.read(firestoreServiceProvider);
  if (companyId == null) return Stream.value(<UserModel>[]);
  return svc.queryStreamWithFilters<UserModel>(
    path: 'users',
    filters: {'companyId': companyId},
    fromJson: UserModel.fromJson,
  );
});

final allWorkplacesStreamProvider = StreamProvider<List<WorkplaceModel>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  final svc = ref.read(firestoreServiceProvider);
  if (companyId == null) return Stream.value(<WorkplaceModel>[]);
  return svc.queryStreamWithFilters<WorkplaceModel>(
    path: 'workplaces',
    filters: {'companyId': companyId},
    fromJson: WorkplaceModel.fromJson,
  );
});

final allAttendancesStreamProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  final svc = ref.read(firestoreServiceProvider);
  if (companyId == null) return Stream.value(<AttendanceModel>[]);
  return svc.queryStreamWithFilters<AttendanceModel>(
    path: 'attendances',
    filters: {'companyId': companyId},
    fromJson: AttendanceModel.fromJson,
  );
});

/// Asistencias activas de la empresa (filtradas en la consulta a Firestore).
/// Usado por flujos que solo necesitan jornadas en curso (locks, huérfanas),
/// evitando descargar el historial completo en cada cambio.
final allActiveAttendancesStreamProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  final svc = ref.read(firestoreServiceProvider);
  if (companyId == null) return Stream.value(<AttendanceModel>[]);
  return svc.queryStreamWithFilters<AttendanceModel>(
    path: 'attendances',
    filters: {'companyId': companyId, 'status': 'active'},
    fromJson: AttendanceModel.fromJson,
  );
});
