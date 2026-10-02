import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/data_providers.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/services/stream_retry.dart';
import '../../../workplaces/data/models/workplace_model.dart';
import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/services/attendance_calculator.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final companyId = ref.watch(currentCompanyIdProvider) ?? '';
  final svc = ref.read(firestoreServiceProvider);
  FirebaseFunctions? functions;
  try {
    functions = ref.read(functionsProvider);
  } catch (_) {
    functions = null;
  }
  return AttendanceRepositoryImpl(svc, companyId: companyId, functions: functions);
});

final attendancesByUserProvider = StreamProvider.family<List<AttendanceModel>, String>((ref, userId) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) {
    return Stream.value(<AttendanceModel>[]);
  }
  final repo = ref.watch(attendanceRepositoryProvider);
  return retryOnError(() => repo.getAttendancesByUser(userId));
});

final activeAttendanceProvider = StreamProvider.family<AttendanceModel?, String>((ref, userId) {
  final companyId = ref.watch(currentCompanyIdProvider);
  if (companyId == null) {
    return Stream.value(null);
  }
  final repo = ref.watch(attendanceRepositoryProvider);
  return retryOnError(() => repo.getActiveAttendance(userId));
});

/// Jornada huérfana del usuario: su asistencia ACTIVA que superó el fin de
/// jornada de su lugar de trabajo sin registrar salida.
///
/// Se deriva de [activeAttendanceProvider] (no de la lista global de la
/// empresa) para que el aviso desaparezca en cuanto la jornada se cierra —
/// incluso si el snapshot global aún no se actualizó — y nunca persista al
/// reabrir la app (Ronda 3A — B7).
final orphanedAttendanceForUserProvider =
    Provider.family<AttendanceModel?, String>((ref, userId) {
  final active = ref.watch(activeAttendanceProvider(userId)).value;
  if (active == null) return null;

  final workplaces = ref.watch(allWorkplacesStreamProvider).value ?? [];
  WorkplaceModel? workplace;
  for (final w in workplaces) {
    if (w.id == active.workplaceId) {
      workplace = w;
      break;
    }
  }
  if (workplace == null || workplace.horaFin == null) return null;

  final shiftEnd = AttendanceCalculator.shiftTimeOn(
    active.checkInTime,
    workplace.horaFin!,
  );
  if (!AttendanceCalculator.isOrphaned(
    attendance: active,
    shiftEnd: shiftEnd,
    now: DateTime.now(),
  )) {
    return null;
  }
  return active;
});
