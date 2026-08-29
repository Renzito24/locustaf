import '../../data/models/medical_document_model.dart';

abstract class MedicalDocumentRepository {
  Stream<List<MedicalDocumentModel>> getDocuments();
  Future<void> createDocument(MedicalDocumentModel document);
  Future<void> updateDocument(MedicalDocumentModel document);
  Future<void> updateEstado(
    String id, {
    required MedicalDocumentEstado estado,
    String? observacionRechazo,
    String? reviewedBy,
  });
  Future<void> softDeleteDocument(String id);
}
