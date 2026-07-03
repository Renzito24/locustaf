import 'package:equatable/equatable.dart';

enum MedicalDocumentTipo { enfermedad, accidente, familiar, personal, otro }

extension MedicalDocumentTipoExtension on MedicalDocumentTipo {
  String get label {
    switch (this) {
      case MedicalDocumentTipo.enfermedad:
        return 'Enfermedad';
      case MedicalDocumentTipo.accidente:
        return 'Accidente';
      case MedicalDocumentTipo.familiar:
        return 'Familiar';
      case MedicalDocumentTipo.personal:
        return 'Personal';
      case MedicalDocumentTipo.otro:
        return 'Otro';
    }
  }

  static MedicalDocumentTipo fromString(String value) {
    switch (value) {
      case 'enfermedad':
        return MedicalDocumentTipo.enfermedad;
      case 'accidente':
        return MedicalDocumentTipo.accidente;
      case 'familiar':
        return MedicalDocumentTipo.familiar;
      case 'personal':
        return MedicalDocumentTipo.personal;
      case 'otro':
        return MedicalDocumentTipo.otro;
      default:
        throw ArgumentError('Invalid MedicalDocumentTipo: $value');
    }
  }
}

enum MedicalDocumentEstado { pendiente, aprobado, rechazado }

extension MedicalDocumentEstadoExtension on MedicalDocumentEstado {
  String get label {
    switch (this) {
      case MedicalDocumentEstado.pendiente:
        return 'Pendiente';
      case MedicalDocumentEstado.aprobado:
        return 'Aprobado';
      case MedicalDocumentEstado.rechazado:
        return 'Rechazado';
    }
  }

  static MedicalDocumentEstado fromString(String value) {
    switch (value) {
      case 'pendiente':
        return MedicalDocumentEstado.pendiente;
      case 'aprobado':
        return MedicalDocumentEstado.aprobado;
      case 'rechazado':
        return MedicalDocumentEstado.rechazado;
      default:
        throw ArgumentError('Invalid MedicalDocumentEstado: $value');
    }
  }
}

class MedicalDocumentModel extends Equatable {
  final String id;
  final String userId;
  final MedicalDocumentTipo tipo;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String motivo;
  final String? archivoUrl;
  final String? mimeType;
  final MedicalDocumentEstado estado;
  final String? observacionRechazo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const MedicalDocumentModel({
    required this.id,
    required this.userId,
    required this.tipo,
    required this.fechaInicio,
    required this.fechaFin,
    required this.motivo,
    this.archivoUrl,
    this.mimeType,
    this.estado = MedicalDocumentEstado.pendiente,
    this.observacionRechazo,
    required this.createdAt,
    this.updatedAt,
  });

  MedicalDocumentModel copyWith({
    String? id,
    String? userId,
    MedicalDocumentTipo? tipo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? motivo,
    String? archivoUrl,
    String? mimeType,
    MedicalDocumentEstado? estado,
    String? observacionRechazo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicalDocumentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      tipo: tipo ?? this.tipo,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      motivo: motivo ?? this.motivo,
      archivoUrl: archivoUrl ?? this.archivoUrl,
      mimeType: mimeType ?? this.mimeType,
      estado: estado ?? this.estado,
      observacionRechazo: observacionRechazo ?? this.observacionRechazo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory MedicalDocumentModel.fromJson(Map<String, dynamic> json) {
    return MedicalDocumentModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      tipo: MedicalDocumentTipoExtension.fromString(json['tipo'] as String),
      fechaInicio: DateTime.parse(json['fechaInicio'] as String),
      fechaFin: DateTime.parse(json['fechaFin'] as String),
      motivo: json['motivo'] as String,
      archivoUrl: json['archivoUrl'] as String?,
      mimeType: json['mimeType'] as String?,
      estado: json['estado'] != null
          ? MedicalDocumentEstadoExtension.fromString(
              json['estado'] as String)
          : MedicalDocumentEstado.pendiente,
      observacionRechazo: json['observacionRechazo'] as String?,
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
      'tipo': tipo.name,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'motivo': motivo,
      'archivoUrl': archivoUrl,
      'mimeType': mimeType,
      'estado': estado.name,
      'observacionRechazo': observacionRechazo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        tipo,
        fechaInicio,
        fechaFin,
        motivo,
        archivoUrl,
        mimeType,
        estado,
        observacionRechazo,
        createdAt,
        updatedAt,
      ];
}
