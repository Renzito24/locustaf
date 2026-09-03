import 'package:equatable/equatable.dart';

enum UserRole { superadmin, admin, supervisor, employee }

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.superadmin:
        return 'Super Administrador';
      case UserRole.admin:
        return 'Administrador';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.employee:
        return 'Empleado';
    }
  }

  static UserRole fromString(String value) {
    switch (value) {
      case 'superadmin':
        return UserRole.superadmin;
      case 'admin':
        return UserRole.admin;
      case 'supervisor':
        return UserRole.supervisor;
      case 'employee':
        return UserRole.employee;
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
  final String? localidad;
  final String? provincia;
  final String? codigoPostal;
  final UserRole rol;
  final bool isActive;
  final bool isDeleted;
  final String? lugarDeTrabajoId;
  final String? companyId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.dni,
    this.telefono,
    this.localidad,
    this.provincia,
    this.codigoPostal,
    required this.rol,
    this.isActive = true,
    this.isDeleted = false,
    this.lugarDeTrabajoId,
    this.companyId,
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
    String? localidad,
    String? provincia,
    String? codigoPostal,
    UserRole? rol,
    bool? isActive,
    bool? isDeleted,
    String? lugarDeTrabajoId,
    String? companyId,
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
      localidad: localidad ?? this.localidad,
      provincia: provincia ?? this.provincia,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      rol: rol ?? this.rol,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      lugarDeTrabajoId: lugarDeTrabajoId ?? this.lugarDeTrabajoId,
      companyId: companyId ?? this.companyId,
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
      localidad: json['localidad'] as String?,
      provincia: json['provincia'] as String?,
      codigoPostal: json['codigoPostal'] as String?,
      rol: UserRoleExtension.fromString(json['rol'] as String),
      isActive: json['isActive'] as bool? ?? true,
      isDeleted: json['isDeleted'] as bool? ?? false,
      lugarDeTrabajoId: json['lugarDeTrabajoId'] as String?,
      companyId: json['companyId'] as String?,
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
      'apellido': apellido,
      'email': email,
      'dni': dni,
      'telefono': telefono,
      'localidad': localidad,
      'provincia': provincia,
      'codigoPostal': codigoPostal,
      'rol': rol.name,
      'isActive': isActive,
      'isDeleted': isDeleted,
      'lugarDeTrabajoId': lugarDeTrabajoId,
      'companyId': companyId,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
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
        localidad,
        provincia,
        codigoPostal,
        rol,
        isActive,
        isDeleted,
        lugarDeTrabajoId,
        companyId,
        createdAt,
        updatedAt,
      ];
}
