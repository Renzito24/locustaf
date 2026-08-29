import '../../../../core/models/user_model.dart';
import '../../../../core/services/firestore_service.dart';
import '../../domain/repositories/medical_document_repository.dart';
import '../models/medical_document_model.dart';

class MedicalDocumentRepositoryImpl implements MedicalDocumentRepository {
  final FirestoreService _firestoreService;
  final String? _companyId;
  final String? _userId;
  final UserRole? _role;

  MedicalDocumentRepositoryImpl(
    this._firestoreService, {
    String? companyId,
    String? userId,
    UserRole? role,
  })  : _companyId = companyId,
        _userId = userId,
        _role = role;

  @override
  Stream<List<MedicalDocumentModel>> getDocuments() {
    if (_companyId == null) return Stream.value(<MedicalDocumentModel>[]);
    // El empleado solo ve sus propios documentos (alineado con las reglas).
    if (_role == UserRole.employee) {
      if (_userId == null) return Stream.value(<MedicalDocumentModel>[]);
      return _firestoreService.queryStreamWithFilters<MedicalDocumentModel>(
        path: 'medical_documents',
        filters: {'companyId': _companyId, 'userId': _userId},
        fromJson: MedicalDocumentModel.fromJson,
      );
    }
    return _firestoreService.queryStreamWithFilters<MedicalDocumentModel>(
      path: 'medical_documents',
      filters: {'companyId': _companyId},
      fromJson: MedicalDocumentModel.fromJson,
    );
  }

  @override
  Future<void> createDocument(MedicalDocumentModel document) async {
    final data = document.toJson();
    if (_companyId != null) data['companyId'] = _companyId;
    await _firestoreService.addDocument(
      path: 'medical_documents',
      data: data,
    );
  }

  @override
  Future<void> updateDocument(MedicalDocumentModel document) async {
    await _firestoreService.updateDocument(
      path: 'medical_documents',
      documentId: document.id,
      data: document.copyWith(updatedAt: DateTime.now()).toJson(),
    );
  }

  @override
  Future<void> updateEstado(
    String id, {
    required MedicalDocumentEstado estado,
    String? observacionRechazo,
    String? reviewedBy,
  }) async {
    await _firestoreService.updateDocument(
      path: 'medical_documents',
      documentId: id,
      data: {
        'estado': estado.name,
        'observacionRechazo': observacionRechazo,
        'reviewedBy': reviewedBy,
        'reviewedAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  @override
  Future<void> softDeleteDocument(String id) async {
    await _firestoreService.updateDocument(
      path: 'medical_documents',
      documentId: id,
      data: {
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }
}
