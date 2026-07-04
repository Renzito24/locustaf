import '../../../../core/services/firestore_service.dart';
import '../../domain/repositories/incidence_repository.dart';
import '../models/incidence_model.dart';

class IncidenceRepositoryImpl implements IncidenceRepository {
  final FirestoreService _firestoreService;

  IncidenceRepositoryImpl(this._firestoreService);

  @override
  Stream<List<IncidenceModel>> getIncidences() {
    return _firestoreService.collectionStream<IncidenceModel>(
      path: 'incidences',
      fromJson: IncidenceModel.fromJson,
    );
  }

  @override
  Future<void> createIncidence(IncidenceModel incidence) async {
    await _firestoreService.addDocument(
      path: 'incidences',
      data: incidence.toJson(),
    );
  }

  @override
  Future<void> updateIncidence(IncidenceModel incidence) async {
    await _firestoreService.updateDocument(
      path: 'incidences',
      documentId: incidence.id,
      data: incidence.toJson(),
    );
  }

  @override
  Future<void> softDeleteIncidence(String id) async {
    await _firestoreService.updateDocument(
      path: 'incidences',
      documentId: id,
      data: {'isActive': false},
    );
  }
}
