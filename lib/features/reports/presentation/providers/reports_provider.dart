import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../attendance/data/models/attendance_model.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/providers/data_providers.dart';

final totalActiveEmployeesProvider = Provider<int>((ref) {
  final usersAsync = ref.watch(allUsersStreamProvider);
  final data = usersAsync.value;
  if (data == null) return 0;
  return data.where((u) => u.rol == UserRole.employee && u.isActive && !u.isDeleted).length;
});

final activeWorkplacesCountProvider = Provider<int>((ref) {
  final workplacesAsync = ref.watch(allWorkplacesStreamProvider);
  final data = workplacesAsync.value;
  if (data == null) return 0;
  return data.where((w) => w.isActive).length;
});

String _todayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

final todayAttendancesProvider = Provider<List<AttendanceModel>>((ref) {
  final attendancesAsync = ref.watch(allAttendancesStreamProvider);
  final attendances = attendancesAsync.value;
  if (attendances == null) return [];
  final today = _todayDate();
  return attendances.where((a) => a.date == today).toList();
});

final employeesPresentTodayProvider = Provider<int>((ref) {
  final today = ref.watch(todayAttendancesProvider);
  final uniqueUserIds = today.map((a) => a.userId).toSet();
  return uniqueUserIds.length;
});

final employeesAbsentTodayProvider = Provider<int>((ref) {
  final total = ref.watch(totalActiveEmployeesProvider);
  final present = ref.watch(employeesPresentTodayProvider);
  return (total - present).clamp(0, total);
});

class AttendanceReportRow {
  final String employeeName;
  final String? workplaceName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final int? durationMinutes;

  const AttendanceReportRow({
    required this.employeeName,
    this.workplaceName,
    required this.checkInTime,
    this.checkOutTime,
    this.durationMinutes,
  });
}

class AttendanceReportFilter {
  final String? date;
  final String? workplaceId;

  const AttendanceReportFilter({this.date, this.workplaceId});
}

class AttendanceReportFilterNotifier extends Notifier<AttendanceReportFilter> {
  @override
  AttendanceReportFilter build() => const AttendanceReportFilter();

  void setDate(String? date) {
    state = AttendanceReportFilter(date: date, workplaceId: state.workplaceId);
  }

  void setWorkplaceId(String? workplaceId) {
    state = AttendanceReportFilter(date: state.date, workplaceId: workplaceId);
  }

  void clear() {
    state = const AttendanceReportFilter();
  }
}

final attendanceReportFilterProvider = NotifierProvider<AttendanceReportFilterNotifier, AttendanceReportFilter>(
  AttendanceReportFilterNotifier.new,
);

const int attendanceReportPageSize = 20;

class AttendanceReportPageNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setPage(int page) {
    state = page < 0 ? 0 : page;
  }

  void reset() {
    state = 0;
  }
}

final attendanceReportPageProvider = NotifierProvider<AttendanceReportPageNotifier, int>(
  AttendanceReportPageNotifier.new,
);

final attendanceReportTotalPagesProvider = Provider<int>((ref) {
  final total = ref.watch(filteredAttendanceReportProvider).length;
  if (total == 0) return 1;
  return (total / attendanceReportPageSize).ceil();
});

final paginatedAttendanceReportProvider = Provider<List<AttendanceReportRow>>((ref) {
  final all = ref.watch(filteredAttendanceReportProvider);
  final page = ref.watch(attendanceReportPageProvider);
  final start = page * attendanceReportPageSize;
  if (start >= all.length) return <AttendanceReportRow>[];
  final end = (start + attendanceReportPageSize).clamp(0, all.length);
  return all.sublist(start, end);
});

final filteredAttendanceReportProvider = Provider<List<AttendanceReportRow>>((ref) {
  final attendancesAsync = ref.watch(allAttendancesStreamProvider);
  final usersAsync = ref.watch(allUsersStreamProvider);
  final workplacesAsync = ref.watch(allWorkplacesStreamProvider);
  final filter = ref.watch(attendanceReportFilterProvider);

  final attendances = attendancesAsync.value ?? [];
  final users = usersAsync.value ?? [];
  final workplaces = workplacesAsync.value ?? [];

  final userMap = {for (final u in users) u.id: u};
  final workplaceMap = {for (final w in workplaces) w.id: w.nombre};

  var filtered = attendances.where((a) => a.status == AttendanceStatus.completed).toList();

  if (filter.date != null && filter.date!.isNotEmpty) {
    filtered = filtered.where((a) => a.date == filter.date).toList();
  }

  if (filter.workplaceId != null && filter.workplaceId!.isNotEmpty) {
    filtered = filtered.where((a) {
      final user = userMap[a.userId];
      return user?.lugarDeTrabajoId == filter.workplaceId;
    }).toList();
  }

  filtered.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

  return filtered.map((a) {
    final user = userMap[a.userId];
    final workplaceName = user?.lugarDeTrabajoId != null
        ? workplaceMap[user!.lugarDeTrabajoId]
        : null;
    return AttendanceReportRow(
      employeeName: user?.nombreCompleto ?? 'Usuario ${a.userId.substring(0, 6)}',
      workplaceName: workplaceName,
      checkInTime: a.checkInTime,
      checkOutTime: a.checkOutTime,
      durationMinutes: a.durationMinutes,
    );
  }).toList();
});
