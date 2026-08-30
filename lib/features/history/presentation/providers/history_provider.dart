import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/data/models/attendance_model.dart';
import '../../../../core/providers/data_providers.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../attendance/presentation/providers/attendance_notifier.dart';
import '../../data/models/history_record_model.dart';

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

/// Tamaño de página para el historial paginado.
const int historyPageSize = 25;

class HistoryPageState {
  final List<AttendanceModel> items;
  final bool hasMore;
  final Object? lastCheckInTime;

  const HistoryPageState({
    this.items = const [],
    this.hasMore = true,
    this.lastCheckInTime,
  });

  HistoryPageState copyWith({
    List<AttendanceModel>? items,
    bool? hasMore,
    Object? lastCheckInTime,
    bool clearLastCheckInTime = false,
  }) {
    return HistoryPageState(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      lastCheckInTime: clearLastCheckInTime
          ? null
          : lastCheckInTime ?? this.lastCheckInTime,
    );
  }
}

/// Carga del historial por páginas (cursor por checkInTime DESC), acumulando
/// los registros ya traídos. Filtrado client-side sobre las páginas cargadas.
class HistoryPaginationNotifier extends AsyncNotifier<HistoryPageState> {
  @override
  Future<HistoryPageState> build() async {
    ref.watch(currentCompanyIdProvider);
    final repo = ref.read(attendanceRepositoryProvider);
    final page = await repo.getAttendancePage(limit: historyPageSize);
    return HistoryPageState(
      items: page.items,
      hasMore: page.hasMore,
      lastCheckInTime: page.lastCheckInTime,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore) return;
    final repo = ref.read(attendanceRepositoryProvider);
    try {
      final page = await repo.getAttendancePage(
        limit: historyPageSize,
        startAfter: current.lastCheckInTime,
      );
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          hasMore: page.hasMore,
          lastCheckInTime: page.lastCheckInTime,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> reload() async {
    state = const AsyncData(HistoryPageState());
    final repo = ref.read(attendanceRepositoryProvider);
    try {
      final page = await repo.getAttendancePage(limit: historyPageSize);
      state = AsyncData(
        HistoryPageState(
          items: page.items,
          hasMore: page.hasMore,
          lastCheckInTime: page.lastCheckInTime,
        ),
      );
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final historyPaginationProvider = AsyncNotifierProvider<HistoryPaginationNotifier, HistoryPageState>(
  HistoryPaginationNotifier.new,
);

/// Total real de asistencias de la empresa (agregación COUNT nativa).
final attendanceTotalCountProvider = FutureProvider<int>((ref) {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.countCompanyAttendances();
});

final paginatedAttendancesProvider = Provider<List<AttendanceModel>>((ref) {
  return ref.watch(historyPaginationProvider).value?.items ?? const [];
});

final filteredHistoryProvider = Provider<List<HistoryRecordModel>>((ref) {
  final attendances = ref.watch(paginatedAttendancesProvider);
  final usersAsync = ref.watch(allUsersStreamProvider);
  final workplacesAsync = ref.watch(allWorkplacesStreamProvider);
  final filter = ref.watch(historyFilterProvider);

  final users = usersAsync.value ?? [];
  final workplaces = workplacesAsync.value ?? [];

  final userMap = {for (final u in users) u.id: u};
  final workplaceMap = {for (final w in workplaces) w.id: w.nombre};

  List<AttendanceModel> filtered = attendances.toList();

  if (filter.employeeId != null) {
    filtered = filtered.where((a) => a.userId == filter.employeeId).toList();
  }

  if (filter.workplaceId != null) {
    filtered = filtered.where((a) => a.workplaceId == filter.workplaceId).toList();
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
    final workplaceName = a.workplaceId != null
        ? workplaceMap[a.workplaceId]
        : null;
    return HistoryRecordModel(
      id: a.id,
      employeeName: user?.nombreCompleto ?? 'Usuario ${StringUtils.safePrefix(a.userId, 6)}',
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
