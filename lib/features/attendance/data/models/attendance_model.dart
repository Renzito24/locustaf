import 'package:equatable/equatable.dart';

enum AttendanceStatus { active, completed }

extension AttendanceStatusExtension on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.active:
        return 'Activo';
      case AttendanceStatus.completed:
        return 'Completado';
    }
  }

  static AttendanceStatus fromString(String value) {
    switch (value) {
      case 'active':
        return AttendanceStatus.active;
      case 'completed':
        return AttendanceStatus.completed;
      default:
        throw ArgumentError('Invalid AttendanceStatus: $value');
    }
  }
}

class AttendanceModel extends Equatable {
  final String uid;
  final String userId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final int? durationMinutes;
  final String date;
  final AttendanceStatus status;

  const AttendanceModel({
    required this.uid,
    required this.userId,
    required this.checkInTime,
    this.checkOutTime,
    this.durationMinutes,
    required this.date,
    this.status = AttendanceStatus.active,
  });

  AttendanceModel copyWith({
    String? uid,
    String? userId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    int? durationMinutes,
    String? date,
    AttendanceStatus? status,
  }) {
    return AttendanceModel(
      uid: uid ?? this.uid,
      userId: userId ?? this.userId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      uid: json['uid'] as String,
      userId: json['userId'] as String,
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int?,
      date: json['date'] as String,
      status: AttendanceStatusExtension.fromString(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'userId': userId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'date': date,
      'status': status.name,
    };
  }

  @override
  List<Object?> get props => [
        uid,
        userId,
        checkInTime,
        checkOutTime,
        durationMinutes,
        date,
        status,
      ];
}
