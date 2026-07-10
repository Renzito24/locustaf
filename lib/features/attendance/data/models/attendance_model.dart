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
  final String id;
  final String userId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final int? durationMinutes;
  final String date;
  final AttendanceStatus status;
  final double? checkInLatitud;
  final double? checkInLongitud;
  final String? workplaceId;

  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.checkInTime,
    this.checkOutTime,
    this.durationMinutes,
    required this.date,
    this.status = AttendanceStatus.active,
    this.checkInLatitud,
    this.checkInLongitud,
    this.workplaceId,
  });

  AttendanceModel copyWith({
    String? id,
    String? userId,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    int? durationMinutes,
    String? date,
    AttendanceStatus? status,
    double? checkInLatitud,
    double? checkInLongitud,
    String? workplaceId,
    bool clearCheckOut = false,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: clearCheckOut ? null : (checkOutTime ?? this.checkOutTime),
      durationMinutes: durationMinutes ?? this.durationMinutes,
      date: date ?? this.date,
      status: status ?? this.status,
      checkInLatitud: checkInLatitud ?? this.checkInLatitud,
      checkInLongitud: checkInLongitud ?? this.checkInLongitud,
      workplaceId: workplaceId ?? this.workplaceId,
    );
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: (json['id'] ?? json['uid'] ?? '') as String,
      userId: json['userId'] as String,
      checkInTime: DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] != null
          ? DateTime.parse(json['checkOutTime'] as String)
          : null,
      durationMinutes: json['durationMinutes'] as int?,
      date: json['date'] as String,
      status: AttendanceStatusExtension.fromString(json['status'] as String),
      checkInLatitud: (json['checkInLatitud'] as num?)?.toDouble(),
      checkInLongitud: (json['checkInLongitud'] as num?)?.toDouble(),
      workplaceId: json['workplaceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'date': date,
      'status': status.name,
      'checkInLatitud': checkInLatitud,
      'checkInLongitud': checkInLongitud,
      'workplaceId': workplaceId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        checkInTime,
        checkOutTime,
        durationMinutes,
        date,
        status,
        checkInLatitud,
        checkInLongitud,
        workplaceId,
      ];
}
