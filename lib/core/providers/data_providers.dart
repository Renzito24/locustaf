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

/// companyId del usuario autenticado leído directamente de la sesión resuelta.
final currentCompanyIdProvider = Provider<String?>((ref) {
  return ref.watch(sessionProvider).companyId;
});

final allUsersStreamProvider = StreamProvider<List<UserModel>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return const Stream.empty();
  final svc = ref.read(firestoreServiceProvider);
  return svc.queryStreamWithFilters<UserModel>(
    path: 'users',
    filters: {'companyId': companyId},
    fromJson: UserModel.fromJson,
  );
});

final allWorkplacesStreamProvider = StreamProvider<List<WorkplaceModel>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return const Stream.empty();
  final svc = ref.read(firestoreServiceProvider);
  return svc.queryStreamWithFilters<WorkplaceModel>(
    path: 'workplaces',
    filters: {'companyId': companyId},
    fromJson: WorkplaceModel.fromJson,
  );
});

final allAttendancesStreamProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) return const Stream.empty();
  final svc = ref.read(firestoreServiceProvider);
  return svc.queryStreamWithFilters<AttendanceModel>(
    path: 'attendances',
    filters: {'companyId': companyId},
    fromJson: AttendanceModel.fromJson,
  );
});

/// Asistencias activas de la empresa (filtradas en la consulta a Firestore).
/// Usado por flujos que solo necesitan jornadas en curso (locks, huérfanas),
/// evitando descargar el historial completo en cada cambio.

