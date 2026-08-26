import 'package:equatable/equatable.dart';

enum CompanyEstado { activa, inactiva }

extension CompanyEstadoExtension on CompanyEstado {
  String get label {
    switch (this) {
      case CompanyEstado.activa:
        return 'Activa';
      case CompanyEstado.inactiva:
        return 'Inactiva';
    }
  }

  static CompanyEstado fromString(String value) {
    switch (value) {
      case 'activa':
        return CompanyEstado.activa;
      case 'inactiva':
        return CompanyEstado.inactiva;
      default:
        throw ArgumentError('Invalid CompanyEstado: $value');
    }
  }
}

class CompanyModel extends Equatable {
  final String id;
  final String nombreComercial;
  final String razonSocial;
  final String cuit;
  final String? direccion;
  final String? telefono;
  final String? email;
  final CompanyEstado estado;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CompanyModel({
    required this.id,
    required this.nombreComercial,
    required this.razonSocial,
    required this.cuit,
    this.direccion,
    this.telefono,
    this.email,
    this.estado = CompanyEstado.activa,
    required this.createdAt,
    this.updatedAt,
  });

  CompanyModel copyWith({
    String? id,
    String? nombreComercial,
    String? razonSocial,
    String? cuit,
    String? direccion,
    String? telefono,
    String? email,
    CompanyEstado? estado,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      nombreComercial: nombreComercial ?? this.nombreComercial,
      razonSocial: razonSocial ?? this.razonSocial,
      cuit: cuit ?? this.cuit,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      estado: estado ?? this.estado,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] as String,
      nombreComercial: json['nombreComercial'] as String,
      razonSocial: json['razonSocial'] as String,
      cuit: json['cuit'] as String,
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      estado: CompanyEstadoExtension.fromString(json['estado'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombreComercial': nombreComercial,
      'razonSocial': razonSocial,
      'cuit': cuit,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
      'estado': estado.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        nombreComercial,
        razonSocial,
        cuit,
        direccion,
        telefono,
        email,
        estado,
        createdAt,
        updatedAt,
      ];
}
