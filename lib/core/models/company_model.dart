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

/// Plan comercial de la empresa (TASK-010). Un solo plan con modalidad
/// mensual o anual; el superadmin registra los pagos manualmente.
enum CompanyPlan { mensual, anual }

extension CompanyPlanExtension on CompanyPlan {
  String get label {
    switch (this) {
      case CompanyPlan.mensual:
        return 'Mensual';
      case CompanyPlan.anual:
        return 'Anual';
    }
  }

  static CompanyPlan fromString(String value) {
    switch (value) {
      case 'mensual':
        return CompanyPlan.mensual;
      case 'anual':
        return CompanyPlan.anual;
      default:
        throw ArgumentError('Invalid CompanyPlan: $value');
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

  /// Plan comercial de la empresa. Solo el superadmin puede modificarlo.
  final CompanyPlan plan;

  /// Fecha hasta la que la empresa tiene uso pagado (o trial). Si es null la
  /// empresa se trata como trial hasta el primer pago registrado.
  final DateTime? paidUntil;

  /// Último pago registrado por el superadmin. null durante el trial.
  final DateTime? lastPaymentAt;

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
    this.plan = CompanyPlan.mensual,
    this.paidUntil,
    this.lastPaymentAt,
  });

  /// La empresa está operativa si está activa y, si tiene una fecha tope
  /// registrada, esa fecha todavía no venció. Las empresas sin `paidUntil`
  /// (legacy o trial) se consideran utilizables hasta el primer vencimiento.
  bool isUsableAt(DateTime now) {
    if (estado != CompanyEstado.activa) return false;
    if (paidUntil == null) return true;
    return paidUntil!.isAfter(now);
  }

  bool get isUsable => isUsableAt(DateTime.now());

  /// Días completos de uso restantes (0 si ya venció o no tiene tope).
  int daysRemainingAt(DateTime now) {
    if (paidUntil == null) return 0;
    final diff = paidUntil!.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

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
    CompanyPlan? plan,
    DateTime? paidUntil,
    DateTime? lastPaymentAt,
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
      plan: plan ?? this.plan,
      paidUntil: paidUntil ?? this.paidUntil,
      lastPaymentAt: lastPaymentAt ?? this.lastPaymentAt,
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
      plan: json['plan'] != null
          ? CompanyPlanExtension.fromString(json['plan'] as String)
          : CompanyPlan.mensual,
      paidUntil: json['paidUntil'] != null
          ? DateTime.parse(json['paidUntil'] as String).toLocal()
          : null,
      lastPaymentAt: json['lastPaymentAt'] != null
          ? DateTime.parse(json['lastPaymentAt'] as String).toLocal()
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
      'createdBy': createdBy,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
      'toleranciaCheckIn': toleranciaCheckIn,
      'diasLaborables': diasLaborables,
      'plan': plan.name,
      'paidUntil': paidUntil?.toUtc().toIso8601String(),
      'lastPaymentAt': lastPaymentAt?.toUtc().toIso8601String(),
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
        plan,
        paidUntil,
        lastPaymentAt,
      ];
}