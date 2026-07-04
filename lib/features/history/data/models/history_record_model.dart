import 'package:equatable/equatable.dart';
import '../../../attendance/data/models/attendance_model.dart';

class HistoryRecordModel extends Equatable {
  final String id;
  final String employeeName;
  final String employeeEmail;
  final String? workplaceName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final int? durationMinutes;
  final String date;
  final AttendanceStatus status;

  const HistoryRecordModel({
    required this.id,
    required this.employeeName,
    required this.employeeEmail,
    this.workplaceName,
    required this.checkInTime,
    this.checkOutTime,
    this.durationMinutes,
    required this.date,
    required this.status,
  });

  String get employeeInfo => '$employeeName ($employeeEmail)';

  String get checkInFormatted {
    final h = checkInTime.hour.toString().padLeft(2, '0');
    final m = checkInTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get checkOutFormatted {
    if (checkOutTime == null) return '-';
    final h = checkOutTime!.hour.toString().padLeft(2, '0');
    final m = checkOutTime!.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get durationFormatted {
    if (durationMinutes == null) return '-';
    final h = durationMinutes! ~/ 60;
    final m = durationMinutes! % 60;
    if (h > 0) return '${h}h ${m}m';
    return '$m min';
  }

  String get statusLabel {
    switch (status) {
      case AttendanceStatus.active:
        return 'Activo';
      case AttendanceStatus.completed:
        return 'Completado';
    }
  }

  @override
  List<Object?> get props => [
        id,
        employeeName,
        employeeEmail,
        workplaceName,
        checkInTime,
        checkOutTime,
        durationMinutes,
        date,
        status,
      ];
}
