import 'package:equatable/equatable.dart';

enum IncidenceType {
  vacaciones,
  licenciaMedica,
  enfermedad,
  accidenteLaboral,
  llegadaTarde,
  salidaAnticipada,
  homeOffice,
  comisionServicio,
  franco,
  ausenciaJustificada,
  otro,
}

extension IncidenceTypeExtension on IncidenceType {
  String get label {
    switch (this) {
      case IncidenceType.vacaciones:
        return 'Vacaciones';
      case IncidenceType.licenciaMedica:
        return 'Licencia médica';
      case IncidenceType.enfermedad:
        return 'Enfermedad';
      case IncidenceType.accidenteLaboral:
        return 'Accidente laboral';
      case IncidenceType.llegadaTarde:
        return 'Llegada tarde';
      case IncidenceType.salidaAnticipada:
        return 'Salida anticipada';
      case IncidenceType.homeOffice:
        return 'Home Office';
      case IncidenceType.comisionServicio:
        return 'Comisión de servicio';
      case IncidenceType.franco:
        return 'Franco';
      case IncidenceType.ausenciaJustificada:
        return 'Ausencia justificada';
      case IncidenceType.otro:
        return 'Otro';
    }
  }

  static IncidenceType fromString(String value) {
    switch (value) {
      case 'vacaciones':
        return IncidenceType.vacaciones;
      case 'licenciaMedica':
        return IncidenceType.licenciaMedica;
      case 'enfermedad':
        return IncidenceType.enfermedad;
      case 'accidenteLaboral':
        return IncidenceType.accidenteLaboral;
      case 'llegadaTarde':
        return IncidenceType.llegadaTarde;
      case 'salidaAnticipada':
        return IncidenceType.salidaAnticipada;
      case 'homeOffice':
        return IncidenceType.homeOffice;
      case 'comisionServicio':
        return IncidenceType.comisionServicio;
      case 'franco':
        return IncidenceType.franco;
      case 'ausenciaJustificada':
        return IncidenceType.ausenciaJustificada;
      case 'otro':
        return IncidenceType.otro;
      default:
        throw ArgumentError('Invalid IncidenceType: $value');
    }
  }
}

enum IncidenceState { programada, enCurso, finalizada }

extension IncidenceStateExtension on IncidenceState {
  String get label {
    switch (this) {
      case IncidenceState.programada:
        return 'Programada';
      case IncidenceState.enCurso:
        return 'En curso';
      case IncidenceState.finalizada:
        return 'Finalizada';
    }
  }
}

class IncidenceModel extends Equatable {
  final String id;
  final String userId;
  final IncidenceType type;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String observaciones;
  final String? documentoRelacionado;
  final String? companyId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const IncidenceModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.fechaInicio,
    required this.fechaFin,
    this.observaciones = '',
    this.documentoRelacionado,
    this.companyId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  IncidenceState get state {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inicio = DateTime(fechaInicio.year, fechaInicio.month, fechaInicio.day);
    final fin = DateTime(fechaFin.year, fechaFin.month, fechaFin.day);
    if (today.isBefore(inicio)) return IncidenceState.programada;
    if (today.isAfter(fin)) return IncidenceState.finalizada;
    return IncidenceState.enCurso;
  }

  IncidenceModel copyWith({
    String? id,
    String? userId,
    IncidenceType? type,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? observaciones,
    String? documentoRelacionado,
    String? companyId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IncidenceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      observaciones: observaciones ?? this.observaciones,
      documentoRelacionado: documentoRelacionado ?? this.documentoRelacionado,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory IncidenceModel.fromJson(Map<String, dynamic> json) {
    return IncidenceModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: IncidenceTypeExtension.fromString(json['type'] as String),
      fechaInicio: DateTime.parse(json['fechaInicio'] as String),
      fechaFin: DateTime.parse(json['fechaFin'] as String),
      observaciones: json['observaciones'] as String? ?? '',
      documentoRelacionado: json['documentoRelacionado'] as String?,
      companyId: json['companyId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
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
      'type': type.name,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'observaciones': observaciones,
      'documentoRelacionado': documentoRelacionado,
      'companyId': companyId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        fechaInicio,
        fechaFin,
        observaciones,
        documentoRelacionado,
        companyId,
        isActive,
        createdAt,
        updatedAt,
      ];
}
