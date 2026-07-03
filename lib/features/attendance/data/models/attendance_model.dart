import 'package:equatable/equatable.dart';

enum AttendanceEstado { presente, ausente, tardanza, justificado }

extension AttendanceEstadoExtension on AttendanceEstado {
  String get label {
    switch (this) {
      case AttendanceEstado.presente:
        return 'Presente';
      case AttendanceEstado.ausente:
        return 'Ausente';
      case AttendanceEstado.tardanza:
        return 'Tardanza';
      case AttendanceEstado.justificado:
        return 'Justificado';
    }
  }

  static AttendanceEstado fromString(String value) {
    switch (value) {
      case 'presente':
        return AttendanceEstado.presente;
      case 'ausente':
        return AttendanceEstado.ausente;
      case 'tardanza':
        return AttendanceEstado.tardanza;
      case 'justificado':
        return AttendanceEstado.justificado;
      default:
        throw ArgumentError('Invalid AttendanceEstado: $value');
    }
  }
}

class AttendanceModel extends Equatable {
  final String id;
  final String userId;
  final String lugarDeTrabajoId;
  final DateTime fecha;
  final DateTime? horaEntrada;
  final DateTime? horaSalida;
  final double? latitudEntrada;
  final double? longitudEntrada;
  final double? distanciaEntrada;
  final double? latitudSalida;
  final double? longitudSalida;
  final double? distanciaSalida;
  final AttendanceEstado estado;
  final String? observacion;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const AttendanceModel({
    required this.id,
    required this.userId,
    required this.lugarDeTrabajoId,
    required this.fecha,
    this.horaEntrada,
    this.horaSalida,
    this.latitudEntrada,
    this.longitudEntrada,
    this.distanciaEntrada,
    this.latitudSalida,
    this.longitudSalida,
    this.distanciaSalida,
    required this.estado,
    this.observacion,
    required this.createdAt,
    this.updatedAt,
  });

  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? lugarDeTrabajoId,
    DateTime? fecha,
    DateTime? horaEntrada,
    DateTime? horaSalida,
    double? latitudEntrada,
    double? longitudEntrada,
    double? distanciaEntrada,
    double? latitudSalida,
    double? longitudSalida,
    double? distanciaSalida,
    AttendanceEstado? estado,
    String? observacion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lugarDeTrabajoId: lugarDeTrabajoId ?? this.lugarDeTrabajoId,
      fecha: fecha ?? this.fecha,
      horaEntrada: horaEntrada ?? this.horaEntrada,
      horaSalida: horaSalida ?? this.horaSalida,
      latitudEntrada: latitudEntrada ?? this.latitudEntrada,
      longitudEntrada: longitudEntrada ?? this.longitudEntrada,
      distanciaEntrada: distanciaEntrada ?? this.distanciaEntrada,
      latitudSalida: latitudSalida ?? this.latitudSalida,
      longitudSalida: longitudSalida ?? this.longitudSalida,
      distanciaSalida: distanciaSalida ?? this.distanciaSalida,
      estado: estado ?? this.estado,
      observacion: observacion ?? this.observacion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      lugarDeTrabajoId: json['lugarDeTrabajoId'] as String,
      fecha: DateTime.parse(json['fecha'] as String),
      horaEntrada: json['horaEntrada'] != null
          ? DateTime.parse(json['horaEntrada'] as String)
          : null,
      horaSalida: json['horaSalida'] != null
          ? DateTime.parse(json['horaSalida'] as String)
          : null,
      latitudEntrada: (json['latitudEntrada'] as num?)?.toDouble(),
      longitudEntrada: (json['longitudEntrada'] as num?)?.toDouble(),
      distanciaEntrada: (json['distanciaEntrada'] as num?)?.toDouble(),
      latitudSalida: (json['latitudSalida'] as num?)?.toDouble(),
      longitudSalida: (json['longitudSalida'] as num?)?.toDouble(),
      distanciaSalida: (json['distanciaSalida'] as num?)?.toDouble(),
      estado:
          AttendanceEstadoExtension.fromString(json['estado'] as String),
      observacion: json['observacion'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'lugarDeTrabajoId': lugarDeTrabajoId,
      'fecha': fecha.toIso8601String(),
      'horaEntrada': horaEntrada?.toIso8601String(),
      'horaSalida': horaSalida?.toIso8601String(),
      'latitudEntrada': latitudEntrada,
      'longitudEntrada': longitudEntrada,
      'distanciaEntrada': distanciaEntrada,
      'latitudSalida': latitudSalida,
      'longitudSalida': longitudSalida,
      'distanciaSalida': distanciaSalida,
      'estado': estado.name,
      'observacion': observacion,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        lugarDeTrabajoId,
        fecha,
        horaEntrada,
        horaSalida,
        latitudEntrada,
        longitudEntrada,
        distanciaEntrada,
        latitudSalida,
        longitudSalida,
        distanciaSalida,
        estado,
        observacion,
        createdAt,
        updatedAt,
      ];
}
