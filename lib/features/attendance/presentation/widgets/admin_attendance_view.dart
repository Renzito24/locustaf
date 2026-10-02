import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/data_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/attendance_notifier.dart';
import 'admin_attendance_components.dart';

class AdminAttendanceView extends ConsumerStatefulWidget {
  const AdminAttendanceView({super.key});

  @override
  ConsumerState<AdminAttendanceView> createState() => _AdminAttendanceViewState();
}

class _AdminAttendanceViewState extends ConsumerState<AdminAttendanceView> {
  DateTime _selectedDate = DateTime.now();

  String get _dateKey {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  bool get _isToday {
    final now = DateTime.now();
    return now.year == _selectedDate.year &&
        now.month == _selectedDate.month &&
        now.day == _selectedDate.day;
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersStreamProvider);
    final attendancesAsync = ref.watch(allAttendancesStreamProvider);
    final workplacesAsync = ref.watch(allWorkplacesStreamProvider);
    final actionState = ref.watch(attendanceActionProvider);
    final isActionLoading = actionState.status == AttendanceActionStatus.loading;

    ref.listen<AttendanceActionState>(attendanceActionProvider, (prev, next) {
      if (prev?.status == next.status) return;
      if (next.status == AttendanceActionStatus.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar(next.message ?? 'Operación exitosa'),
        );
      } else if (next.status == AttendanceActionStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar(next.message ?? 'Error'),
        );
      }
    });

    final users = usersAsync.value ?? [];
    final attendances = attendancesAsync.value ?? [];
    final workplaces = workplacesAsync.value ?? [];

    final dayAttendances = attendances
        .where((a) => a.date == _dateKey)
        .toList()
      ..sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

    final workplaceMap = {for (final w in workplaces) w.id: w.nombre};
    final userMap = {for (final u in users) u.id: u};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminAttendanceHeader(
            selectedDate: _selectedDate,
            onPreviousDay: () => _changeDate(-1),
            onNextDay: () => _changeDate(1),
            isToday: _isToday,
            isActionLoading: isActionLoading,
            onManualCheckIn: () => AdminAttendanceDialogs.showManualCheckInDialog(
              context,
              ref,
              users,
            ),
          ),
          const SizedBox(height: 24),
          AdminAttendanceList(
            dayAttendances: dayAttendances,
            userMap: userMap,
            workplaceMap: workplaceMap,
          ),
        ],
      ),
    );
  }
}
