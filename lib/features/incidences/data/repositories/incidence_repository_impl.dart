import '../../../../core/services/firestore_service.dart';
import '../../domain/repositories/incidence_repository.dart';
import '../models/incidence_model.dart';

class IncidenceRepositoryImpl implements IncidenceRepository {
  final FirestoreService _firestoreService;
  final String? _companyId;

  IncidenceRepositoryImpl(this._firestoreService, {String? companyId})
      : _companyId = companyId;

  @override
  Stream<List<IncidenceModel>> getIncidences() {
    if (_companyId == null) return Stream.value(<IncidenceModel>[]);
    return _firestoreService.queryStreamWithFilters<IncidenceModel>(
      path: 'incidences',
      filters: {'companyId': _companyId},
      fromJson: IncidenceModel.fromJson,
    );
  }

  @override
  Future<void> createIncidence(IncidenceModel incidence) async {
    final data = incidence.toJson();
    if (_companyId != null) data['companyId'] = _companyId;
    await _firestoreService.addDocument(
      path: 'incidences',
      data: data,
    );
  }

  @override
  Future<void> updateIncidence(IncidenceModel incidence) async {
    await _firestoreService.updateDocument(
      path: 'incidences',
      documentId: incidence.id,
      data: incidence.copyWith(updatedAt: DateTime.now()).toJson(),
    );
  }

  @override
  Future<void> softDeleteIncidence(String id) async {
    await _firestoreService.updateDocument(
      path: 'incidences',
      documentId: id,
      data: {
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }
}
