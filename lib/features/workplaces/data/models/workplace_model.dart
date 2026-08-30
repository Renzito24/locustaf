import 'package:equatable/equatable.dart';

class WorkplaceModel extends Equatable {
  final String id;
  final String nombre;
  final String? description;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  final double? radio;
  final String? codigo;
  final String? horaInicio;
  final String? horaFin;
  final int toleranciaMinutos;
  final String? companyId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const WorkplaceModel({
    required this.id,
    required this.nombre,
    this.description,
    this.direccion,
    this.latitud,
    this.longitud,
    this.radio,
    this.codigo,
    this.horaInicio,
    this.horaFin,
    this.toleranciaMinutos = 15,
    this.companyId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  WorkplaceModel copyWith({
    String? id,
    String? nombre,
    String? description,
    String? direccion,
    double? latitud,
    double? longitud,
    double? radio,
    String? codigo,
    String? horaInicio,
    String? horaFin,
    int? toleranciaMinutos,
    String? companyId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkplaceModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      description: description ?? this.description,
      direccion: direccion ?? this.direccion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      radio: radio ?? this.radio,
      codigo: codigo ?? this.codigo,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      toleranciaMinutos: toleranciaMinutos ?? this.toleranciaMinutos,
      companyId: companyId ?? this.companyId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WorkplaceModel.fromJson(Map<String, dynamic> json) {
    return WorkplaceModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      description: json['description'] as String?,
      direccion: json['direccion'] as String?,
      latitud: (json['latitud'] as num?)?.toDouble(),
      longitud: (json['longitud'] as num?)?.toDouble(),
      radio: (json['radio'] as num?)?.toDouble(),
      codigo: json['codigo'] as String?,
      horaInicio: json['horaInicio'] as String?,
      horaFin: json['horaFin'] as String?,
      toleranciaMinutos: (json['toleranciaMinutos'] as num?)?.toInt() ?? 15,
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
      'nombre': nombre,
      'description': description,
      'direccion': direccion,
      'latitud': latitud,
      'longitud': longitud,
      'radio': radio,
      'codigo': codigo,
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'toleranciaMinutos': toleranciaMinutos,
      'companyId': companyId,
      'isActive': isActive,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        description,
        direccion,
        latitud,
        longitud,
        radio,
        codigo,
        horaInicio,
        horaFin,
        toleranciaMinutos,
        companyId,
        isActive,
        createdAt,
        updatedAt,
      ];
}
