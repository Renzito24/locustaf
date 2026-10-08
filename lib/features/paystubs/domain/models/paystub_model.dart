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
  final String? storagePath;
  final String? fileName;
  final PaystubEstado estado;
  final String? observacionRechazo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? respondedAt;
  final bool isActive;

  const PaystubModel({
    required this.id,
    required this.companyId,
    required this.userId,
    required this.periodo,
    required this.documentUrl,
    this.storagePath,
    this.fileName,
    required this.estado,
    this.observacionRechazo,
    required this.createdAt,
    required this.updatedAt,
    this.respondedAt,
    this.isActive = true,
  });

  factory PaystubModel.fromJson(Map<String, dynamic> json) {
    // Si no tiene storagePath, intentamos deducirlo de documentUrl si es un link de Storage.
    String? sPath = json['storagePath'] as String?;
    if (sPath == null) {
      final String? docUrl = json['documentUrl'] as String?;
      if (docUrl != null && docUrl.contains('firebasestorage.googleapis.com')) {
        // Extraer ruta: /v0/b/project.appspot.com/o/PATH?alt=media
        final oIndex = docUrl.indexOf('/o/');
        final altIndex = docUrl.indexOf('?alt=');
        if (oIndex != -1 && altIndex != -1) {
          sPath = Uri.decodeComponent(docUrl.substring(oIndex + 3, altIndex));
        }
      }
    }

    return PaystubModel(
      id: json['id'] as String? ?? '',
      companyId: json['companyId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      periodo: json['periodo'] as String? ?? '',
      documentUrl: json['documentUrl'] as String? ?? '',
      storagePath: sPath,
      fileName: json['fileName'] as String?,
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
      respondedAt: json['respondedAt'] != null
          ? (json['respondedAt'] as Timestamp).toDate()
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'userId': userId,
      'periodo': periodo,
      'documentUrl': documentUrl,
      if (storagePath != null) 'storagePath': storagePath,
      if (fileName != null) 'fileName': fileName,
      'estado': estado.name,
      if (observacionRechazo != null) 'observacionRechazo': observacionRechazo,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (respondedAt != null) 'respondedAt': Timestamp.fromDate(respondedAt!),
      'isActive': isActive,
    };
  }

  PaystubModel copyWith({
    String? id,
    String? companyId,
    String? userId,
    String? periodo,
    String? documentUrl,
    String? storagePath,
    String? fileName,
    PaystubEstado? estado,
    String? observacionRechazo,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? respondedAt,
    bool? isActive,
  }) {
    return PaystubModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      periodo: periodo ?? this.periodo,
      documentUrl: documentUrl ?? this.documentUrl,
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      estado: estado ?? this.estado,
      observacionRechazo: observacionRechazo ?? this.observacionRechazo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      respondedAt: respondedAt ?? this.respondedAt,
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
        storagePath,
        fileName,
        estado,
        observacionRechazo,
        createdAt,
        updatedAt,
        respondedAt,
        isActive,
      ];
}
