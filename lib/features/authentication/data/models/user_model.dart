import 'package:equatable/equatable.dart';

enum UserRole { admin, empleado }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Administrador';
      case UserRole.empleado:
        return 'Empleado';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'empleado':
        return UserRole.empleado;
      default:
        throw ArgumentError('Invalid UserRole: $value');
    }
  }
}

class UserModel extends Equatable {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String dni;
  final String? telefono;
  final UserRole rol;
  final bool isActive;
  final String? lugarDeTrabajoId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.dni,
    this.telefono,
    required this.rol,
    this.isActive = true,
    this.lugarDeTrabajoId,
    required this.createdAt,
    this.updatedAt,
  });

  String get nombreCompleto => '$nombre $apellido';

  UserModel copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? email,
    String? dni,
    String? telefono,
    UserRole? rol,
    bool? isActive,
    String? lugarDeTrabajoId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      email: email ?? this.email,
      dni: dni ?? this.dni,
      telefono: telefono ?? this.telefono,
      rol: rol ?? this.rol,
      isActive: isActive ?? this.isActive,
      lugarDeTrabajoId: lugarDeTrabajoId ?? this.lugarDeTrabajoId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String,
      email: json['email'] as String,
      dni: json['dni'] as String,
      telefono: json['telefono'] as String?,
      rol: UserRoleExtension.fromString(json['rol'] as String),
      isActive: json['isActive'] as bool? ?? true,
      lugarDeTrabajoId: json['lugarDeTrabajoId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'dni': dni,
      'telefono': telefono,
      'rol': rol.name,
      'isActive': isActive,
      'lugarDeTrabajoId': lugarDeTrabajoId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        apellido,
        email,
        dni,
        telefono,
        rol,
        isActive,
        lugarDeTrabajoId,
        createdAt,
        updatedAt,
      ];
}
