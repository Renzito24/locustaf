import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum PaystubEstado {
  pendiente,
  aceptado,
  rechazado;

  String get displayName {
    switch (this) {
      case PaystubEstado.pendiente:
        return 'Pendiente';
      case PaystubEstado.aceptado:
        return 'Aceptado';
      case PaystubEstado.rechazado:
        return 'Rechazado';
    }
  }
}

class PaystubModel extends Equatable {
  final String id;
  final String companyId;
  final String userId;
  final String periodo;
  final String documentUrl;
  final PaystubEstado estado;
  final String? observacionRechazo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  const PaystubModel({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.periodo,
    required this.documentUrl,
    required this.estado,
    this.observacionRechazo,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory PaystubModel.fromJson(Map<String, dynamic> json) {
    return PaystubModel(
      id: json['id'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      periodo: json['periodo'] as String? ?? '',
      documentUrl: json['documentUrl'] as String? ?? '',
      estado: PaystubEstado.values.firstWhere(
        (e) => e.name == json['estado'],
        orElse: () => PaystubEstado.pendiente,
      ),
      observacionRechazo: json['observacionRechazo'] as String?,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'userId': userId,
      'periodo': periodo,
      'documentUrl': documentUrl,
      'estado': estado.name,
      if (observacionRechazo != null) 'observacionRechazo': observacionRechazo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  PaystubModel copyWith({
    String? id,
    String? companyId,
    String? userId,
    String? periodo,
    String? documentUrl,
    PaystubEstado? estado,
    String? observacionRechazo,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return PaystubModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      periodo: periodo ?? this.periodo,
      documentUrl: documentUrl ?? this.documentUrl,
      estado: estado ?? this.estado,
      observacionRechazo: observacionRechazo ?? this.observacionRechazo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        userId,
        periodo,
        documentUrl,
        estado,
        observacionRechazo,
        createdAt,
        updatedAt,
        isActive,
      ];
}
