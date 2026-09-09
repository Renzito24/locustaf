import 'package:equatable/equatable.dart';

import 'company_model.dart';

/// Registro histórico de un pago registrado por el superadmin (TASK-017).
/// A diferencia de los campos de facturación de la empresa (que solo guardan
/// el último pago), cada pago deja un documento inmutable en `payments/`.
class PaymentModel extends Equatable {
  final String id;
  final String companyId;

  /// Nombre comercial desnormalizado para mostrar el historial sin joins.
  final String companyName;
  final CompanyPlan plan;

  /// Fecha hasta la que el pago habilita la empresa.
  final DateTime paidUntil;

  /// Nota opcional del superadmin (ej: "Pago anticipado", "Renovación").
  final String? nota;

  /// Momento en que se registró el pago.
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.plan,
    required this.paidUntil,
    this.nota,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      companyName: json['companyName'] as String? ?? '',
      plan: json['plan'] != null
          ? _parsePlan(json['plan'] as String)
          : CompanyPlan.mensual,
      paidUntil: DateTime.parse(json['paidUntil'] as String).toLocal(),
      nota: json['nota'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String).toLocal()
          : DateTime.now(),
    );
  }

  static CompanyPlan _parsePlan(String value) {
    try {
      return CompanyPlanExtension.fromString(value);
    } on ArgumentError {
      return CompanyPlan.mensual;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'companyName': companyName,
      'plan': plan.name,
      'paidUntil': paidUntil.toUtc().toIso8601String(),
      'nota': nota,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        companyName,
        plan,
        paidUntil,
        nota,
        createdAt,
      ];
}