import 'package:cloud_firestore/cloud_firestore.dart';
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
  final double? checkOutLatitud;
  final double? checkOutLongitud;
  final bool? isLate;
  final String? workplaceId;
  final String? companyId;

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
    this.checkOutLatitud,
    this.checkOutLongitud,
    this.isLate,
    this.workplaceId,
    this.companyId,
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
    double? checkOutLatitud,
    double? checkOutLongitud,
    bool? isLate,
    String? workplaceId,
    String? companyId,
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
      checkOutLatitud: checkOutLatitud ?? this.checkOutLatitud,
      checkOutLongitud: checkOutLongitud ?? this.checkOutLongitud,
      isLate: isLate ?? this.isLate,
      workplaceId: workplaceId ?? this.workplaceId,
      companyId: companyId ?? this.companyId,
    );
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: (json['id'] ?? json['uid'] ?? '') as String,
      userId: (json['userId'] ?? '') as String,
      checkInTime: _parseTimestamp(json['checkInTime']),
      checkOutTime: json['checkOutTime'] != null
          ? _parseTimestamp(json['checkOutTime'])
          : null,
      durationMinutes: json['durationMinutes'] as int?,
      date: (json['date'] ?? '') as String,
      status: _parseStatus(json['status']),
      checkInLatitud: (json['checkInLatitud'] as num?)?.toDouble(),
      checkInLongitud: (json['checkInLongitud'] as num?)?.toDouble(),
      checkOutLatitud: (json['checkOutLatitud'] as num?)?.toDouble(),
      checkOutLongitud: (json['checkOutLongitud'] as num?)?.toDouble(),
      isLate: json['isLate'] as bool?,
      workplaceId: json['workplaceId'] as String?,
      companyId: json['companyId'] as String?,
    );
  }

  /// Parsea timestamps tolerando ausencia o formatos inválidos para no romper
  /// el stream de asistencias con documentos corruptos. Ante datos inválidos
  /// devuelve la época Unix como fallback predecible.
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.toLocal();
    }
    return DateTime.fromMillisecondsSinceEpoch(0).toLocal();
  }

  /// Parsea el estado tolerando ausencia o valores desconocidos: ante datos
  /// inválidos degrada a [AttendanceStatus.active] para mantener vivo el stream.
  static AttendanceStatus _parseStatus(dynamic value) {
    if (value is String) {
      switch (value) {
        case 'active':
          return AttendanceStatus.active;
        case 'completed':
          return AttendanceStatus.completed;
      }
    }
    return AttendanceStatus.active;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime': checkOutTime != null
          ? Timestamp.fromDate(checkOutTime!)
          : null,
      'durationMinutes': durationMinutes,
      'date': date,
      'status': status.name,
      'checkInLatitud': checkInLatitud,
      'checkInLongitud': checkInLongitud,
      'checkOutLatitud': checkOutLatitud,
      'checkOutLongitud': checkOutLongitud,
      'isLate': isLate,
      'workplaceId': workplaceId,
      'companyId': companyId,
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
        checkOutLatitud,
        checkOutLongitud,
        isLate,
        workplaceId,
        companyId,
      ];
}
