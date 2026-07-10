import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/data/models/attendance_model.dart';
import '../../../attendance/presentation/providers/attendance_notifier.dart';
import '../../../employees/presentation/providers/users_provider.dart';
import '../../../workplaces/presentation/providers/workplace_notifier.dart';
import '../../data/models/history_record_model.dart';

final allAttendancesProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final repo = ref.read(attendanceRepositoryProvider);
  return repo.getAllAttendances();
});

class HistoryFilterState {
  final String searchQuery;
  final String? employeeId;
  final String? workplaceId;
  final String? status;
  final String? dateFrom;
  final String? dateTo;

  const HistoryFilterState({
    this.searchQuery = '',
    this.employeeId,
    this.workplaceId,
    this.status,
    this.dateFrom,
    this.dateTo,
  });

  HistoryFilterState copyWith({
    String? searchQuery,
    String? employeeId,
    String? workplaceId,
    String? status,
    String? dateFrom,
    String? dateTo,
  }) {
    return HistoryFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      employeeId: employeeId ?? this.employeeId,
      workplaceId: workplaceId ?? this.workplaceId,
      status: status ?? this.status,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }
}

class HistoryFilterNotifier extends Notifier<HistoryFilterState> {
  @override
  HistoryFilterState build() => const HistoryFilterState();

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value.trim().toLowerCase());
  }

  void setEmployeeId(String? id) {
    state = state.copyWith(employeeId: id);
  }

  void setWorkplaceId(String? id) {
    state = state.copyWith(workplaceId: id);
  }

  void setStatus(String? status) {
    state = state.copyWith(status: status);
  }

  void setDateFrom(String? date) {
    state = state.copyWith(dateFrom: date);
  }

  void setDateTo(String? date) {
    state = state.copyWith(dateTo: date);
  }

  void clear() {
    state = const HistoryFilterState();
  }
}

final historyFilterProvider = NotifierProvider<HistoryFilterNotifier, HistoryFilterState>(
  HistoryFilterNotifier.new,
);

final filteredHistoryProvider = Provider<List<HistoryRecordModel>>((ref) {
  final attendancesAsync = ref.watch(allAttendancesProvider);
  final usersAsync = ref.watch(usersStreamProvider);
  final workplacesAsync = ref.watch(workplacesStreamProvider);
  final filter = ref.watch(historyFilterProvider);

  final attendances = attendancesAsync.value ?? [];
  final users = usersAsync.value ?? [];
  final workplaces = workplacesAsync.value ?? [];

  final userMap = {for (final u in users) u.id: u};
  final workplaceMap = {for (final w in workplaces) w.id: w.nombre};

  List<AttendanceModel> filtered = attendances.toList();

  if (filter.employeeId != null) {
    filtered = filtered.where((a) => a.userId == filter.employeeId).toList();
  }

  if (filter.workplaceId != null) {
    filtered = filtered.where((a) {
      final user = userMap[a.userId];
      return user?.lugarDeTrabajoId == filter.workplaceId;
    }).toList();
  }

  if (filter.status != null) {
    final status = filter.status == 'active'
        ? AttendanceStatus.active
        : AttendanceStatus.completed;
    filtered = filtered.where((a) => a.status == status).toList();
  }

  if (filter.dateFrom != null && filter.dateFrom!.isNotEmpty) {
    filtered = filtered.where((a) => a.date.compareTo(filter.dateFrom!) >= 0).toList();
  }

  if (filter.dateTo != null && filter.dateTo!.isNotEmpty) {
    filtered = filtered.where((a) => a.date.compareTo(filter.dateTo!) <= 0).toList();
  }

  if (filter.searchQuery.isNotEmpty) {
    final q = filter.searchQuery;
    filtered = filtered.where((a) {
      final user = userMap[a.userId];
      if (user == null) return false;
      return user.nombre.toLowerCase().contains(q) ||
          user.apellido.toLowerCase().contains(q);
    }).toList();
  }

  filtered.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

  return filtered.map((a) {
    final user = userMap[a.userId];
    final workplaceName = user?.lugarDeTrabajoId != null
        ? workplaceMap[user!.lugarDeTrabajoId]
        : null;
    return HistoryRecordModel(
      id: a.id,
      employeeName: user?.nombreCompleto ?? 'Usuario ${a.userId.substring(0, 6)}',
      employeeEmail: user?.email ?? '',
      workplaceName: workplaceName,
      checkInTime: a.checkInTime,
      checkOutTime: a.checkOutTime,
      durationMinutes: a.durationMinutes,
      date: a.date,
      status: a.status,
    );
  }).toList();
});

final totalRecordsProvider = Provider<int>((ref) {
  return ref.watch(filteredHistoryProvider).length;
});

final activeRecordsProvider = Provider<int>((ref) {
  return ref.watch(filteredHistoryProvider).where((r) => r.status == AttendanceStatus.active).length;
});

final completedRecordsProvider = Provider<int>((ref) {
  return ref.watch(filteredHistoryProvider).where((r) => r.status == AttendanceStatus.completed).length;
});
