import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/attendance_model.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../../../core/services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final svc = ref.read(firestoreServiceProvider);
  return AttendanceRepositoryImpl(svc);
});

final attendancesByUserProvider = StreamProvider.family<List<AttendanceModel>, String>((ref, userId) {
  final repo = ref.read(attendanceRepositoryProvider);
  return repo.getAttendancesByUser(userId);
});

final activeAttendanceProvider = StreamProvider.family<AttendanceModel?, String>((ref, userId) {
  final repo = ref.read(attendanceRepositoryProvider);
  return repo.getActiveAttendance(userId);
});

class AttendanceNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() => Future.value();

  Future<void> checkIn(String userId) async {
    state = const AsyncLoading();
    final repo = ref.read(attendanceRepositoryProvider);
    final today = _todayDate();
    try {
      await repo.checkIn(userId, today);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> checkOut(String attendanceUid) async {
    state = const AsyncLoading();
    final repo = ref.read(attendanceRepositoryProvider);
    try {
      await repo.checkOut(attendanceUid);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }

  String _todayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

final attendanceActionProvider = AsyncNotifierProvider<AttendanceNotifier, void>(
  AttendanceNotifier.new,
);
