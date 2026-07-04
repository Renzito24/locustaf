import '../../../../core/services/firestore_service.dart';
import '../../domain/repositories/medical_document_repository.dart';
import '../models/medical_document_model.dart';

class MedicalDocumentRepositoryImpl implements MedicalDocumentRepository {
  final FirestoreService _firestoreService;

  MedicalDocumentRepositoryImpl(this._firestoreService);

  @override
  Stream<List<MedicalDocumentModel>> getDocuments() {
    return _firestoreService.collectionStream<MedicalDocumentModel>(
      path: 'medical_documents',
      fromJson: MedicalDocumentModel.fromJson,
    );
  }

  @override
  Future<void> createDocument(MedicalDocumentModel document) async {
    await _firestoreService.addDocument(
      path: 'medical_documents',
      data: document.toJson(),
    );
  }

  @override
  Future<void> updateDocument(MedicalDocumentModel document) async {
    await _firestoreService.updateDocument(
      path: 'medical_documents',
      documentId: document.id,
      data: document.toJson(),
    );
  }

  @override
  Future<void> softDeleteDocument(String id) async {
    await _firestoreService.updateDocument(
      path: 'medical_documents',
      documentId: id,
      data: {'isActive': false},
    );
  }
}
