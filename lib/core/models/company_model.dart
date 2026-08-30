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
  final String? createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Tolerancia del check-in en minutos que valida Firestore Rules contra el
  /// tiempo del servidor. Configurable por el admin de la empresa (D1).
  final int toleranciaCheckIn;

  /// Días laborables de la empresa (ISO 1=Lu .. 7=Do). En los días no
  /// laborables no se contabilizan ausencias. Configurable por el admin (D2).
  final List<int> diasLaborables;

  const CompanyModel({
    required this.id,
    required this.nombreComercial,
    required this.razonSocial,
    required this.cuit,
    this.direccion,
    this.telefono,
    this.email,
    this.estado = CompanyEstado.activa,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.toleranciaCheckIn = 15,
    this.diasLaborables = const [1, 2, 3, 4, 5],
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
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? toleranciaCheckIn,
    List<int>? diasLaborables,
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
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      toleranciaCheckIn: toleranciaCheckIn ?? this.toleranciaCheckIn,
      diasLaborables: diasLaborables ?? this.diasLaborables,
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
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String).toLocal()
          : null,
      toleranciaCheckIn: (json['toleranciaCheckIn'] as num?)?.toInt() ?? 15,
      diasLaborables: (json['diasLaborables'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 2, 3, 4, 5],
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
      'createdBy': createdBy,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'toleranciaCheckIn': toleranciaCheckIn,
      'diasLaborables': diasLaborables,
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
        createdBy,
        createdAt,
        updatedAt,
        toleranciaCheckIn,
        diasLaborables,
      ];
}
