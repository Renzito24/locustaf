import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TargetType { all, workplace, users }

extension TargetTypeExtension on TargetType {
  String get name => toString().split('.').last;

  static TargetType fromString(String val) {
    return TargetType.values.firstWhere((e) => e.name == val, orElse: () => TargetType.all);
  }
}

class ComunicadoModel extends Equatable {
  final String id;
  final String companyId;
  final String title;
  final String content;
  final TargetType targetType;
  final List<String> targetWorkplaceIds;
  final List<String> targetUserIds;
  final List<String> readBy;
  final String createdBy;
  final DateTime createdAt;

  const ComunicadoModel({
    required this.id,
    required this.companyId,
    required this.title,
    required this.content,
    required this.targetType,
    this.targetWorkplaceIds = const [],
    this.targetUserIds = const [],
    this.readBy = const [],
    required this.createdBy,
    required this.createdAt,
  });

  factory ComunicadoModel.fromJson(Map<String, dynamic> json) {
    return ComunicadoModel(
      id: json['id'] ?? '',
      companyId: json['companyId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      targetType: TargetTypeExtension.fromString(json['targetType'] ?? 'all'),
      targetWorkplaceIds: List<String>.from(json['targetWorkplaceIds'] ?? []),
      targetUserIds: List<String>.from(json['targetUserIds'] ?? []),
      readBy: List<String>.from(json['readBy'] ?? []),
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] is Timestamp 
          ? (json['createdAt'] as Timestamp).toDate().toLocal()
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()).toLocal() : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'title': title,
      'content': content,
      'targetType': targetType.name,
      'targetWorkplaceIds': targetWorkplaceIds,
      'targetUserIds': targetUserIds,
      'readBy': readBy,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
    };
  }

  ComunicadoModel copyWith({
    String? id,
    String? companyId,
    String? title,
    String? content,
    TargetType? targetType,
    List<String>? targetWorkplaceIds,
    List<String>? targetUserIds,
    List<String>? readBy,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return ComunicadoModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      content: content ?? this.content,
      targetType: targetType ?? this.targetType,
      targetWorkplaceIds: targetWorkplaceIds ?? this.targetWorkplaceIds,
      targetUserIds: targetUserIds ?? this.targetUserIds,
      readBy: readBy ?? this.readBy,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, companyId, title, content, targetType, targetWorkplaceIds, targetUserIds, readBy, createdBy, createdAt];
}
