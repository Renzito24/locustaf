import 'package:equatable/equatable.dart';

enum MedicalDocumentTipo { enfermedad, accidente, familiar, personal, otro }

enum VigenciaEstado { vigente, proximoAVencer, vencido }

extension VigenciaEstadoExtension on VigenciaEstado {
  String get label {
    switch (this) {
      case VigenciaEstado.vigente:
        return 'Vigente';
      case VigenciaEstado.proximoAVencer:
        return 'Próximo a vencer';
      case VigenciaEstado.vencido:
        return 'Vencido';
    }
  }
}

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
  final String? archivoNombre;
  final String? mimeType;
  final MedicalDocumentEstado estado;
  final String? observacionRechazo;
  final String? companyId;
  final bool isActive;
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
    this.archivoNombre,
    this.mimeType,
    this.estado = MedicalDocumentEstado.pendiente,
    this.observacionRechazo,
    this.companyId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  String get observaciones => motivo;

  VigenciaEstado get vigencia {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    final diff = fin.difference(today).inDays;
    if (diff < 0) return VigenciaEstado.vencido;
    if (diff <= 30) return VigenciaEstado.proximoAVencer;
    return VigenciaEstado.vigente;
  }

  MedicalDocumentModel copyWith({
    String? id,
    String? userId,
    MedicalDocumentTipo? tipo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? motivo,
    String? archivoUrl,
    String? archivoNombre,
    String? mimeType,
    MedicalDocumentEstado? estado,
    String? observacionRechazo,
    String? companyId,
    bool? isActive,
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
      archivoNombre: archivoNombre ?? this.archivoNombre,
      mimeType: mimeType ?? this.mimeType,
      estado: estado ?? this.estado,
      observacionRechazo: observacionRechazo ?? this.observacionRechazo,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
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
      archivoNombre: json['archivoNombre'] as String?,
      mimeType: json['mimeType'] as String?,
      estado: json['estado'] != null
          ? MedicalDocumentEstadoExtension.fromString(
              json['estado'] as String)
          : MedicalDocumentEstado.pendiente,
      observacionRechazo: json['observacionRechazo'] as String?,
      companyId: json['companyId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String).toLocal()
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
      'archivoNombre': archivoNombre,
      'mimeType': mimeType,
      'estado': estado.name,
      'observacionRechazo': observacionRechazo,
      'companyId': companyId,
      'isActive': isActive,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
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
        archivoNombre,
        mimeType,
        estado,
        observacionRechazo,
        companyId,
        isActive,
        createdAt,
        updatedAt,
      ];
}
